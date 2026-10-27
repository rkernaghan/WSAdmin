//
//  SheetVersionStore.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2026-10-20.
//
import Foundation

// These functions are used to implement optimistic locking of certain spreadsheet ranges to ensure the cells have not been
// updated by an external program since the data was loaded into memory, causing WSAdmin to write stale data.
//
// The lock is based on cell CONTENT, not the Drive file "version".  The Drive version is bumped asynchronously by Google
// (once or twice, up to ~20 seconds after a write), so it can't distinguish WSAdmin's own writes from outside changes.
//
//	- readSheetCells (trackVersion: true) stores a snapshot of the values it read, keyed by file + starting cell
//	- writeSheetCells re-reads the snapshot's range just before writing and throws if the values differ
//	- after a successful write the snapshot is replaced with the values Google reports it wrote
//
// Ranges that were never read with trackVersion: true have no snapshot and are not checked.
//
actor SheetVersionStore {
	static let shared = SheetVersionStore()

	private struct Snapshot {
		let range: String         // range as it was read, e.g. "Master!V3:AT14"
		let values: [[String]]    // normalized values (see normalize)
		let label: String         // used in the conflict message
	}
	private var snapshots: [String: Snapshot] = [:]    // "fileID|SHEET!STARTCELL" -> snapshot

	// A write replaces the range that was read starting at the same cell (the read and write ranges
	// usually differ only in their last row), so key on the file and the range's starting cell.
	private func snapshotKey(_ fileID: String, _ range: String) -> String {
		let startCell = range.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? range
		return fileID + "|" + startCell.uppercased()
	}

	// The Sheets API omits trailing empty cells and rows, so strip them before comparing
	private func normalize(_ values: [[String]]) -> [[String]] {
		var rows = values.map { row -> [String] in
			var trimmed = row
			while let last = trimmed.last, last.isEmpty { trimmed.removeLast() }
			return trimmed
		}
		while let last = rows.last, last.isEmpty { rows.removeLast() }
		return rows
	}

	// Reads the current values of a range directly (no snapshot is recorded)
	private func fetchValues(fileID: String, range: String) async throws -> [[String]] {
		guard let accessToken = await TokenStore.shared.validAccessToken() else {
			throw URLError(.userAuthenticationRequired)
		}
		let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(fileID)/values/\(range)"
		guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
			throw URLError(.badURL)
		}
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

		let (data, _) = try await performRequestWithRetry(
			request: request,
			maxAttempts: PgmConstants.maxReadAttempts,
			context: "SheetVersionStore.fetchValues - Range: \(range), FileID: \(fileID)"
		)
		return normalize(try JSONDecoder().decode(SheetData.self, from: data).values)
	}

	// Describes the first cell that differs, for the log
	private func firstDifference(_ a: [[String]], _ b: [[String]]) -> String {
		for row in 0..<max(a.count, b.count) {
			let rowA = row < a.count ? a[row] : []
			let rowB = row < b.count ? b[row] : []
			for col in 0..<max(rowA.count, rowB.count) {
				let cellA = col < rowA.count ? rowA[col] : ""
				let cellB = col < rowB.count ? rowB[col] : ""
				if cellA != cellB {
					return "first difference at row \(row + 1), column \(col + 1): loaded \"\(cellA)\" now \"\(cellB)\""
				}
			}
		}
		return "no difference found"
	}

	// Called by readSheetCells (trackVersion: true) to remember what was loaded into memory
	func recordSnapshot(fileID: String, range: String, values: [[String]], label: String) {
		snapshots[snapshotKey(fileID, range)] = Snapshot(range: range, values: normalize(values), label: label)
	}

	// Forget all snapshots for a file
	func invalidate(fileID: String) {
		snapshots = snapshots.filter { !$0.key.hasPrefix(fileID + "|") }
	}

	// Called by writeSheetCells before it writes.  Throws if the cells that were loaded have since changed;
	// ranges with no snapshot (untracked) pass.
	func assertUnchanged(fileID: String, range: String) async throws {
		guard let snapshot = snapshots[snapshotKey(fileID, range)] else { return }
		try await compareToCurrent(fileID: fileID, snapshot: snapshot)
	}
	
	// Pre-flight check for operations that make several writes: verifies every tracked range of the file
	// (or only those on one sheet/tab when sheetName is given) is unchanged, without writing anything.
	// Call it before changing any data so a conflict stops the whole operation, not just its later writes.
	func verifyUnchanged(fileID: String, sheetName: String? = nil) async throws {
		var prefix = fileID + "|"
		if let sheetName { prefix += sheetName.uppercased() + "!" }
		let matches = snapshots.filter { $0.key.hasPrefix(prefix) }.map { $0.value }
		for snapshot in matches {
			try await compareToCurrent(fileID: fileID, snapshot: snapshot)
		}
	}
	
	private func compareToCurrent(fileID: String, snapshot: Snapshot) async throws {
		let current: [[String]]
		do {
			current = try await fetchValues(fileID: fileID, range: snapshot.range)
		} catch {
			throw SheetError.versionCheckFailed(fileID: fileID, underlying: error)
		}
		
		if current != snapshot.values {
			let logMessage = "ERROR: Optimistic lock failed for \(snapshot.label), Range: \(snapshot.range), FileID: \(fileID) - \(firstDifference(snapshot.values, current))"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			throw SheetError.modifiedExternally(fileID: fileID, fileLabel: snapshot.label)
		}
	}
	                                                             
	// Called by writeSheetCells after a successful write.  Uses the values Google echoes back
	// (includeValuesInResponse=true) so formatting changes from USER_ENTERED don't cause false conflicts.
	func recordWrite(fileID: String, range: String, responseData: Data) async {
		let key = snapshotKey(fileID, range)
		guard let snapshot = snapshots[key] else { return }

		var newRange = range
		var newValues: [[String]]?
		if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
		   let updated = json["updatedData"] as? [String: Any] {
			newRange = (updated["range"] as? String) ?? (json["updatedRange"] as? String) ?? range
			let rows = (updated["values"] as? [[Any]]) ?? []
			newValues = normalize(rows.map { $0.map { "\($0)" } })
		}

		// Fall back to re-reading the range if the response didn't include the values
		if newValues == nil {
			newValues = try? await fetchValues(fileID: fileID, range: range)
		}

		if let newValues {
			snapshots[key] = Snapshot(range: newRange, values: newValues, label: snapshot.label)
		} else {
			snapshots[key] = nil
			let logMessage = "WARNING: could not update lock snapshot after write for \(snapshot.label), Range: \(range), FileID: \(fileID) - range is no longer protected until it is re-read"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .warning)
		}
	}
}

enum SheetError: LocalizedError {
	case modifiedExternally(fileID: String, fileLabel: String)
	case versionCheckFailed(fileID: String, underlying: Error)

	var errorDescription: String? {
		switch self {
			case .modifiedExternally(_, let label):
				return "\(label) was changed by another user or app since WSAdmin loaded it. Reload the data before saving."
			case .versionCheckFailed(_, let underlying):
				return "Could not verify the spreadsheet is unchanged: \(underlying.localizedDescription)"
		}
	}
}
