//
//  AppFolders.swift
//  WSAdmin
//

import Foundation
import AppKit

/// Central place for the app's file-system locations. Since the app is
/// sandboxed, these all resolve inside the container
/// (~/Library/Containers/WSAdmin/Data/Documents/...), not the user's real
/// ~/Documents — that's expected and accepted for this app.
enum AppFolders {
	
	/// Where generated CSV exports (client list, Xero invoice exports) are saved.
	static var csvFilesDirectory: URL {
		let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		return documentsDir.appendingPathComponent("WSAdmin CSV Files", isDirectory: true)
	}
	
	/// Where AppLogger writes local audit log files.
	static var logFilesDirectory: URL {
		let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		return documentsDir.appendingPathComponent("WSAdmin Log Files", isDirectory: true)
	}
	
	/// Opens Finder and reveals (highlights) the CSV export folder.
	/// Creates the folder first if it doesn't exist yet (e.g. no CSV has
	/// ever been generated), so Finder has something to open.
	@MainActor
	static func revealCSVFilesFolder() {
		reveal(csvFilesDirectory)
	}
	
	/// Opens Finder and reveals (highlights) the audit log folder.
	@MainActor
	static func revealLogFilesFolder() {
		reveal(logFilesDirectory)
	}
	
	@MainActor
	private static func reveal(_ url: URL) {
		if !FileManager.default.fileExists(atPath: url.path) {
			try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
		}
		NSWorkspace.shared.activateFileViewerSelecting([url])
	}
}
