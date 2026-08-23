//
//  AppLogger.swift
//  WSAdmin
//

import Foundation

enum LogLevel: String {
	case debug = "DEBUG"
	case info = "INFO"
	case warning = "WARNING"
	case error = "ERROR"
}

actor AppLogger {
	static let shared = AppLogger()
	
	private let fileURL: URL
	private let logFileName: String
	private var driveFileID: String?
	private var autoSyncTask: Task<Void, Never>?
	private var hasUnsyncedChanges: Bool = false
	
	// MARK: - Error alerting config
	private let alertRecipientEmail = "rskernaghan@gmail.com"
	private var lastAlertSentAt: Date?
	private let minimumAlertInterval: TimeInterval = 300 // 5 minutes — throttles alert bursts
	
	private init() {
		// Build a per-launch timestamp suffix, e.g. "2026-08-20-143012",
		// so each run of the app gets its own uniquely-named log file
		// both locally and on Google Drive.
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd-HHmmss"
		formatter.timeZone = TimeZone.current
		let sessionTimestamp = formatter.string(from: Date())
		
		logFileName = "WSAdmin-app-\(sessionTimestamp).log"
		
		let appSupportDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let appDir = appSupportDir.appendingPathComponent("WSAdmin Log Files", isDirectory: true)
		
		print("Log Documents directory: \(appDir.path)")
		
		// Make sure the directory exists before we try to write into it
		if !FileManager.default.fileExists(atPath: appDir.path) {
			print("Log file directory \(appDir.path)")
			try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
		}
		
		fileURL = appDir.appendingPathComponent(logFileName)
		
		// This is a brand-new, uniquely-timestamped filename every launch,
		// so it will never already exist — always create it fresh.
		FileManager.default.createFile(atPath: fileURL.path, contents: nil)
		
		// Kick off a self-scheduling background sync loop — no external trigger needed.
		// This runs for the lifetime of the app, since AppLogger is a singleton.
		Task { await self.startAutoSync() }
	}
	
	/// Starts a background loop that syncs to Google Drive every 60 seconds.
	/// Runs indefinitely for the app's lifetime — no need to call this yourself.
	private func startAutoSync() {
		autoSyncTask = Task { [weak self] in
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
				guard let self else { break }
				await self.syncToGoogleDrive()
			}
		}
	}
	
	// MARK: - Local file logging
	
	func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line, newLine: String = "N") {
		// Local time, no UTC offset suffix — e.g. "2026-08-22T17:34:33"
		let logTimeFormatter = DateFormatter()
		logTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
		logTimeFormatter.timeZone = TimeZone.current
		let timestamp = logTimeFormatter.string(from: Date())
		let fileName = (file as NSString).lastPathComponent
		var logLine: String
		
		//		let logLine = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line) \(function)] \(message)\n"
		if newLine == "Y" {
			logLine = "\n[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(message)\n"
		} else {
			logLine = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(message)\n"
		}
		guard let data = logLine.data(using: .utf8) else { return }
		
		if let handle = try? FileHandle(forWritingTo: fileURL) {
			handle.seekToEndOfFile()
			handle.write(data)
			try? handle.close()
			hasUnsyncedChanges = true
		}
		
		if level == .error {
			Task {
				await self.sendErrorAlert(message: message)
			}
		}
	}
	
	/// Returns the current log file's contents, useful for a "view logs" screen or exporting.
	func readLogContents() -> String {
		(try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
	}
	
	/// Returns the file URL, useful if you want to offer "reveal in Finder" or attach the log to a support email.
	func logFileURL() -> URL {
		fileURL
	}
	
	/// Clears the log file — useful for rotation or a manual "clear logs" action.
	func clearLog() {
		try? "".write(to: fileURL, atomically: true, encoding: .utf8)
	}
}

// MARK: - Google Drive sync

extension AppLogger {
	
	/// Uploads the current local log file to Google Drive, creating it on first run
	/// and overwriting it on subsequent syncs. Skips the network call entirely if
	/// nothing has been logged since the last successful sync.
	func syncToGoogleDrive() async {
		guard hasUnsyncedChanges else {
			return // nothing new since last sync — don't waste an API call
		}
		
		let tokenFound = await getAccessToken()
		guard tokenFound, let accessToken = oauth2Token.accessToken else {
			print("AppLogger - couldn't sync to Drive, no access token")
			return
		}
		
		guard let logData = try? Data(contentsOf: fileURL) else { return }
		
		var succeeded = false
		
		if let existingFileID = driveFileID {
			// Already created this session's Drive file — just overwrite it.
			succeeded = await updateDriveFile(fileID: existingFileID, data: logData, accessToken: accessToken)
		} else {
			// First sync of this session — the filename is timestamp-unique,
			// so there's no existing Drive file to find; create it fresh.
			succeeded = await createDriveFile(data: logData, accessToken: accessToken)
		}
		
		// Only clear the flag on a confirmed successful upload — if it failed
		// (network error, 504 exhausted, etc.), leave it set so the next
		// 60-second cycle retries rather than silently dropping the change.
		if succeeded {
			hasUnsyncedChanges = false
		}
	}
	
	@discardableResult
	private func createDriveFile(data: Data, accessToken: String, folderID: String? = nil) async -> Bool {
		guard let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart") else { return false }
		
		var metadata: [String: Any] = ["name": logFileName]
		if let folderID {
			metadata["parents"] = [folderID]
		}
		
		guard let metadataJSON = try? JSONSerialization.data(withJSONObject: metadata) else { return false }
		
		let boundary = "AppLoggerBoundary-\(UUID().uuidString)"
		var body = Data()
		body.append("--\(boundary)\r\n".data(using: .utf8)!)
		body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
		body.append(metadataJSON)
		body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
		body.append("Content-Type: text/plain\r\n\r\n".data(using: .utf8)!)
		body.append(data)
		body.append("\r\n--\(boundary)--".data(using: .utf8)!)
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		request.addValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		request.httpBody = body
		
		var responseData: Data
		var response: URLResponse
		var attempt = 0
		let maxAttempts = 2 // initial try + 1 retry
		
		while true {
			attempt += 1
			guard let result = try? await URLSession.shared.data(for: request) else { return false }
			(responseData, response) = result
			
			guard let httpResponse = response as? HTTPURLResponse else { return false }
			
			if httpResponse.statusCode == 504, attempt < maxAttempts {
				print("AppLogger.createDriveFile - HTTP 504, retrying in 1 second (attempt \(attempt))")
				try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
				continue
			}
			
			if httpResponse.statusCode == 200,
			   let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
			   let fileID = json["id"] as? String {
				driveFileID = fileID
				return true
			} else {
				print("AppLogger.createDriveFile - failed to create Drive log file, status \(httpResponse.statusCode)")
				return false
			}
		}
	}
	
	@discardableResult
	private func updateDriveFile(fileID: String, data: Data, accessToken: String) async -> Bool {
		guard let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files/\(fileID)?uploadType=media") else { return false }
		
		var request = URLRequest(url: url)
		request.httpMethod = "PATCH"
		request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
		request.httpBody = data
		
		var attempt = 0
		let maxAttempts = 2 // initial try + 1 retry
		
		while true {
			attempt += 1
			guard let (_, response) = try? await URLSession.shared.data(for: request),
			      let httpResponse = response as? HTTPURLResponse else {
				print("AppLogger.updateDriveFile - request failed")
				return false
			}
			
			if httpResponse.statusCode == 504, attempt < maxAttempts {
				print("AppLogger.updateDriveFile - HTTP 504, retrying in 1 second (attempt \(attempt))")
				try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
				continue
			}
			
			if httpResponse.statusCode == 200 {
				return true
			} else {
				print("AppLogger.updateDriveFile - failed to update Drive log file, status \(httpResponse.statusCode)")
				return false
			}
		}
	}
}

// MARK: - Error alerting via Gmail API

extension AppLogger {
	
	/// Sends an email alert via the Gmail API when an .error-level log line is written.
	/// Throttled to at most one alert per `minimumAlertInterval`, so a burst of errors
	/// (e.g. a retry loop failing repeatedly) doesn't flood the inbox.
	///
	/// Requires the OAuth token used by this app to include the
	/// "https://www.googleapis.com/auth/gmail.send" scope — add it alongside
	/// whatever scopes are already requested for Sheets/Drive.
	private func sendErrorAlert(message: String) async {
		if let lastAlertSentAt, Date().timeIntervalSince(lastAlertSentAt) < minimumAlertInterval {
			return // suppress — an alert already went out too recently
		}
		
		let tokenFound = await getAccessToken()
		guard tokenFound, let accessToken = oauth2Token.accessToken else {
			print("AppLogger.sendErrorAlert - couldn't send, no access token")
			return
		}
		
		guard let rawMessage = buildRawEmail(to: alertRecipientEmail, subject: "WSAdmin Error Alert", body: message) else {
			print("AppLogger.sendErrorAlert - failed to build email payload")
			return
		}
		
		guard let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/send") else { return }
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		
		guard let body = try? JSONSerialization.data(withJSONObject: ["raw": rawMessage]) else { return }
		request.httpBody = body
		
		var attempt = 0
		let maxAttempts = 2 // initial try + 1 retry
		
		while true {
			attempt += 1
			guard let (_, response) = try? await URLSession.shared.data(for: request),
			      let httpResponse = response as? HTTPURLResponse else {
				print("AppLogger.sendErrorAlert - request failed")
				return
			}
			
			if httpResponse.statusCode == 504, attempt < maxAttempts {
				print("AppLogger.sendErrorAlert - HTTP 504, retrying in 1 second (attempt \(attempt))")
				try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
				continue
			}
			
			if httpResponse.statusCode == 200 {
				lastAlertSentAt = Date()
			} else {
				print("AppLogger.sendErrorAlert - failed to send alert, status \(httpResponse.statusCode)")
			}
			
			break
		}
	}
	
	/// Builds a base64url-encoded RFC 2822 message, the format the Gmail API's
	/// messages.send endpoint requires in its "raw" field.
	private func buildRawEmail(to: String, subject: String, body: String) -> String? {
		let emailString = "To: \(to)\r\nSubject: \(subject)\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n\(body)"
		
		guard let data = emailString.data(using: .utf8) else { return nil }
		
		// Gmail requires base64url (RFC 4648 §5): standard base64 with
		// "+" -> "-", "/" -> "_", and no trailing "=" padding.
		return data.base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
}
