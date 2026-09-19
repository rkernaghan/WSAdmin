//
//  Utilities.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-13.
//

import Foundation
import GoogleSignIn

// getFileID - gets the Google FileID of a file on Google Drive
//	Parameters:
//		fileName - name of the File to retrive Google File ID
//	Returns:
//		a boolean flag as to whether the FileID could be returned
//		a string containing the Google FileID
//
func getFileID(fileName: String) async throws -> (Bool, String) {
//	var fileID: String = ""
//	var fileFound: Bool = false
	var logMessage: String
		
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			// URL for Google Sheets API
			let urlString = "https://www.googleapis.com/drive/v3/files?q=name='\(fileName)'&fields=files(id,name)"
			guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
				logMessage = "ERROR: Invalid URL in GelFileID \(urlString)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return(false, " ")
			}
			
			// Set up the request with OAuth 2.0 token
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			
			// Use async URLSession to fetch the data
			var data: Data
			var response: URLResponse
			var attempt = 0
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			while true {
				attempt += 1
				do {
					(data, response) = try await URLSession.shared.data(for: request)
				} catch {
					if attempt < maxAttempts {
						let delaySeconds = 1 << (attempt - 1) // 1, 2, 4, 8...
						logMessage = "WARNING: getFileID - URLSession request failed for File: \(fileName), error: \(error.localizedDescription), retrying in \(delaySeconds) seconds (attempt \(attempt))"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .warning)
						try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
						continue
					} else {
						logMessage = "ERROR: getFileID - URLSession request failed for File: \(fileName), error: \(error.localizedDescription), attempt: \(attempt), request url: \(request)"
						await AppLogger.shared.log(logMessage, level: .error)
						throw error
					}
				}
				
				if let httpResponse = response as? HTTPURLResponse {
					if httpResponse.statusCode == 503, attempt < maxAttempts {
						let delaySeconds = 1 << (attempt - 1) // 1, 2, 4, 8...
						logMessage = "WARNING: Utilities.getFileID - HTTP 503 for Filename \(fileName), retrying in \(delaySeconds) seconds (attempt \(attempt))"
						print(logMessage)
						await AppLogger.shared.log(logMessage,level: .warning)
						try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
						continue
					}
					
					if httpResponse.statusCode != 200 {
						logMessage = "ERROR: Utilities.getFileID - HTTP Result Error Code: \(httpResponse.statusCode) for Filename \(fileName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}
				}
				
				break
			}
			
			// Check if the response is successful
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				logMessage = "ERROR: Invalid HTTP Response in getFileID Status Code: \(statusCode)"
				print(logMessage)
				await AppLogger.shared.log(logMessage,level: .error)
				throw NSError(domain: logMessage, code: statusCode, userInfo: nil)
			}
			
			// Parse the JSON response
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			   let files = json["files"] as? [[String: Any]], !files.isEmpty,
			   let fileID = files.first?["id"] as? String {
				return (true, fileID)
			} else {
				return (false, "")
			}
		}
		return (false, "")
	}
	else {
		return(false, "")
	}
}

// readSheetCells - reads a range of cells from a Google Sheet
//	Parameters:
//		fileID: the Google Drive FileID of the spreadsheet
//		range: the cell range to retrieve
//	Returns:
//		sheetData: an optional SheetData struct containing the retrieved cells in sheetdata.values
//	Throws:
//
func readSheetCells(fileID: String, range: String, logNote: String) async throws -> SheetData? {
	var sheetData: SheetData?
	var logMessage: String
	
	let tokenFound = await getAccessToken()
	guard tokenFound, let accessToken = oauth2Token.accessToken else {
		return nil
	}
	
	// URL for Google Sheets API
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(fileID)/values/\(range)"
	guard let url = URL(string: urlString) else {
		logMessage = "ERROR: Bad URL in readSheetCells URL: \(urlString)"
		await AppLogger.shared.log(logMessage, level: .error)
		throw URLError(.badURL)
	}
	
	// Set up the request with OAuth 2.0 token
	var request = URLRequest(url: url)
	request.httpMethod = "GET"
	request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
	
	logMessage = "INFO: readSheetCells \(logNote) - Range: \(range), FileID \(fileID)"
	await AppLogger.shared.log(logMessage)
	
	// Perform the network request, retrying on transient errors and
	// 429/500/502/503/504 responses; throws on a final non-200 status.
	let (data, _) = try await performRequestWithRetry(
		request: request,
		maxAttempts: PgmConstants.maxReadAttempts,
		context: "Utilities.readSheetCells - Range: \(range), FileID: \(fileID)"
	)
	
	// Decode the JSON data into the SheetData structure
	do {
		sheetData = try JSONDecoder().decode(SheetData.self, from: data)
	} catch {
		logMessage = "ERROR: readSheetCells - Decoding error: \(error.localizedDescription)"
		await AppLogger.shared.log(logMessage, level: .error)
		throw error
	}
	
	return sheetData
}

// writeSheetCells - writes a set of cells to a Google Sheets spreadsheet
//	Parameters:
//		fileID: the Google Drive FileID of the spreadsheet to write to
//		range: the spreadsheet range to write to
//		values: a 2 dimensional array in row/column format of cells values to be written
//	Returns:
//		a boolean indicating whether the write operation was successful
//	Throws:
//
func writeSheetCells(fileID: String, range: String, values: [[String]], logNote: String) async throws -> Bool {
	var completionFlag: Bool = true
	var logMessage: String
	
	let tokenFound = await getAccessToken()
	guard tokenFound, let accessToken = oauth2Token.accessToken else {
		return false
	}
	
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(fileID)/values/\(range)?valueInputOption=USER_ENTERED"
	guard let url = URL(string: urlString) else {
		logMessage = "ERROR: Invalid URL for Google Sheets API \(urlString)"
		await AppLogger.shared.log(logMessage, level: .error)
		throw URLError(.badURL)
	}
	
	// Prepare the request
	var request = URLRequest(url: url)
	request.httpMethod = "PUT"  // Using PUT to update the values in the sheet
	request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
	request.addValue("application/json", forHTTPHeaderField: "Content-Type")
	
	// Prepare the request body with the data to write
	let body: [String: Any] = [
		"range": range,
		"majorDimension": "ROWS",  // Writing row by row
		"values": values            // The 2D array of values to write
	]
	
	request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
	
	logMessage = "INFO: writeSheetCells - \(logNote), Range: \(range), FileID \(fileID)"
	await AppLogger.shared.log(logMessage)
	
	// Perform the network request, retrying on transient errors and
	// 429/500/502/503/504 responses; throws on a final non-200 status.
	let (data, _) = try await performRequestWithRetry(
		request: request,
		maxAttempts: PgmConstants.maxWriteAttempts,
		context: "Utilities.writeSheetCells - Range: \(range), FileID: \(fileID)"
	)
	
	return completionFlag
}

// requestAdditionalScopes - calls Google Cloud API to request user permission for additional API scope to read/write spreadsheet cells and get Google Drive FileID
//	Parameters:
//		additionalScopes: an array containing the Google Cloud Scopes requested
//	Returns:
//		a boolean indicating whether the request was successful
//
func requestAdditionalScopes(additionalScopes: [String]) async -> Bool {
	var requestResult: Bool = true
	var logMessage: String
	
	// The additional scopes you want to request
	logMessage = "INFO: Additional Scopes Requested: \(additionalScopes)"
	print(logMessage)
	await AppLogger.shared.log(logMessage)
	
	
	// Ensure the user is already signed in
	guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
		logMessage = "INFO: User is not signed in"
		print(logMessage)
		await AppLogger.shared.log(logMessage)
		return(false)
	}
	
	do {
		// Use async/await to request additional scopes
		guard let presentingWindow = await NSApplication.shared.mainWindow else {
			return(false)
		}
		let _ = try await currentUser.addScopes(additionalScopes, presenting: presentingWindow)
		logMessage = "INFO: Additional scopes granted."
		print(logMessage)
		await AppLogger.shared.log(logMessage)
		
		// Access granted scopes if needed
		if let grantedScopes = currentUser.grantedScopes {
			logMessage = "INFO: Granted scopes: \(grantedScopes)"
			print(logMessage)
			await AppLogger.shared.log(logMessage)
		}
	} catch {
		// Handle errors
		logMessage = "ERROR:  Error requesting additional scopes: \(error.localizedDescription)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .error)
		requestResult = false
	}
	return(requestResult)
}

// renameGoogleDriveFile - renames a Google Drive File.  Used when a Tutor name changes to rename the Tutor's Timesheet
//	Parameters:
//		fileID: the Google Drive FileID of the file being renamed
//		newName: the name the file should be renamed to
//	Returns:
//		a boolean indicating whether the rename was successful
//
func renameGoogleDriveFile(fileID: String, newName: String) async throws -> Bool {
	var renameResult: Bool = true
	let urlString = "https://www.googleapis.com/drive/v3/files/\(fileID)"
	var logMessage: String
	    
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			guard let url = URL(string: urlString) else {
				logMessage = "ERROR: invalid URLString in renameGoogleDrive URL: \(urlString)"
				await AppLogger.shared.log(logMessage, level: .error)
				throw URLError(.badURL)
			}
			
			// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "PATCH"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			
			// Request body with the new name
			let body: [String: Any] = [
				"name": newName
			]
			request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
			
			// Perform the network request using async/await
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.renameGoogleDriveFile - for New Filename \(newName)"
			)
			
			// Handle the response
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				logMessage = "INFO: Google Drive File renamed successfully: \(json)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .info)
			}
		} else {
			renameResult = false
		}
	} else {
		renameResult = false
	}
	return(renameResult)
}

// copyGoogleDriveFile - copies a Google Drive file into a new file.  Used to create new Timesheets for new Tutors; and new Timesheets and Tutor/Student billing summary files for a new calendar year
//	Parameters:
//		sourceFileID: Google Drive FileID of the Google Drive file being copied
//		newFileName: name of the Google Drive file to create and copy into
//	Returns:
//		Success/Fail flag for copy operation
//		Optional FileID if copy successful
//
func copyGoogleDriveFile(sourceFileId: String, newFileName: String) async throws -> (Bool, String?) {
	var logMessage: String
	
	let urlString = "https://www.googleapis.com/drive/v3/files/\(sourceFileId)/copy"
	
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			guard let url = URL(string: urlString) else {
				logMessage = "ERROR: Utilities.copyGoogleDriveFile - bad URL for source file \(sourceFileId)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return (false, nil)
			}
			
			// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			
			// Request body with the new file name
			let body: [String: Any] = [
				"name": newFileName
			]
			request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
			
			// Perform the network request asynchronously
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.copyGoogleDriveFile - for New Filename \(newFileName)"
			)
			
			// Parse the response JSON and pull out the new file's ID
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			   let newFileId = json["id"] as? String {
				logMessage = "INFO: Google Drive File copied successfully: \(json)"
				print(logMessage)
				await AppLogger.shared.log(logMessage)
				return (true, newFileId)
			} else {
				logMessage = "ERROR: Utilities.copyGoogleDriveFile - copy succeeded but response had no file id for New Filename \(newFileName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return (false, nil)
			}
		}
	}
	return (false, nil)
}

// addPermissionToFile - Function to add a permission to a Google Drive file
//	Parameters:
//		fileID: the Google Drive FileID of the file
//		role: file access permission being granted to user (e.g. "reader" or "writer")
//		type: role type (e.g. "user", "group", "domain", "anyone"
//		emailAddress: email address of user being given permission to the file
//	Returns:
//		returns a response JSON
//	Throws:
//
func addPermissionToFile(fileID: String, role: String, type: String, emailAddress: String? = nil, sendNotificationEmail: Bool) async throws -> [String: Any]? {
	var logMessage: String
	
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			
			let urlString = "https://www.googleapis.com/drive/v3/files/\(fileID)/permissions?sendNotificationEmail=\(sendNotificationEmail)"
			
			guard let url = URL(string: urlString) else {
				logMessage = "ERROR: invalid URLString in addPermissionToFile URL: \(urlString)"
				await AppLogger.shared.log(logMessage, level: .error)
				throw URLError(.badURL)
			}
			
			// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			
			// Request body for the permission
			var body: [String: Any] = [
				"role": role,   // e.g., "reader" or "writer"
				"type": type    // e.g., "user", "group", "domain", "anyone"
			]
			if let email = emailAddress, type == "user" || type == "group" {
				body["emailAddress"] = email
			}
			
			request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.addPermissionToFile - URLSession request failed for File ID: \(fileID), email: \(String(describing: emailAddress)), request URL: \(request)"
			)
			
			// Parse and return the response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				logMessage = "INFO: Permission added successfully: \(json)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .info)
				return json
			}
		}
	}
	return nil
}


// getSheetIDByName- Function to get the sheet ID of an individual sheet in a Google Drive spreadsheet
//	Parameters:
//		spreadsheetID: the Google Drive FileID of the spreadsheet
//		sheetName: the name of individual sheet in the spreadsheet
//	Returns:
//		returns the fileID of the Google Drive spreadsheet sheet
//	Throws:
//
func getSheetIdByName(spreadsheetID: String, sheetName: String) async throws -> Int? {
	var logMessage: String
	    
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID)?fields=sheets.properties"
	
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			
			guard let url = URL(string: urlString) else {
				logMessage = "ERROR: invalid URLString in getSheetIDByName URL: \(urlString)"
				await AppLogger.shared.log(logMessage, level: .error)
				throw URLError(.badURL)
			}
			
			// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.getSheetID - SpreadsheetID: \(spreadsheetID)"
			)
			
			// Parse the response JSON to find the sheet ID
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			   let sheets = json["sheets"] as? [[String: Any]] {
				
				for sheet in sheets {
					if let properties = sheet["properties"] as? [String: Any],
					   let title = properties["title"] as? String,
					   let sheetId = properties["sheetId"] as? Int,
					   title == sheetName {
						return sheetId // Return the sheet ID if the name matches
					}
				}
			}
		}
	}
	// If the sheet name was not found, return nil
	return nil
}

// Function to add a new sheet to a Google Sheets spreadsheet
//	Parameters:
//		spreadsheetID: the Google Drive FileID of the spreadsheet
//		sheetTitle: the name of the new sheet being added to the spreadsheet
//	Returns:
//		returns the fileID of the new Google Drive spreadsheet sheet
//	Throws:
//
func createNewSheetInSpreadsheet(spreadsheetID: String, sheetTitle: String) async throws -> [String: Any]? {
	var logMessage: String
	
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID):batchUpdate"
    
	guard let url = URL(string: urlString) else {
		logMessage = "ERROR: invalid URLString in createNewSheetInSpreadsheet URL: \(urlString)"
		await AppLogger.shared.log(logMessage, level: .error)
		throw URLError(.badURL)
	}
	
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			
			// Request body for creating a new sheet
			let body: [String: Any] = [
				"requests": [
					[
						"addSheet": [
							"properties": [
								"title": sheetTitle
							]
						]
					]
				]
			]
			request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
			
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.createNewSheetInSpreadsheet - Sheet Title \(sheetTitle), SpreadsheetID: \(spreadsheetID)"
			)
			
			// Parse and return the response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				logMessage = "INFO: New Sheet \(sheetTitle) created successfully: \(json)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .info)
				return json
			}
		}
	}
    
	return nil
}


// renameSheetInSpreadsheet = Function to rename a specific sheet in a Google Sheets spreadsheet
//	Parameters:
//		spreadsheetID: the Google Drive FileID of the spreadsheet
//		sheetID: the ID of the individual sheet in the spreadsheet to be renamed
//		newSheetName: the name to rename the sheet in the spreadsheet to
//	Returns:
//		returns a success/fail boolean
//	Throws:
//
func renameSheetInSpreadsheet(spreadsheetID: String, sheetId: Int, newSheetName: String) async throws -> Bool {
	var renameResult: Bool = true
	var logMessage: String
	    
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			
			let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID):batchUpdate"
			
			guard let url = URL(string: urlString) else {
				logMessage = "ERROR: invalid URLString in renameGSheetInSpreadsheet URL: \(urlString)"
				await AppLogger.shared.log(logMessage, level: .error)
				throw URLError(.badURL)
			}
			
			// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			
			// Request body with batchUpdate to rename the sheet
			let body: [String: Any] = [
				"requests": [
					[
						"updateSheetProperties": [
							"properties": [
								"sheetId": sheetId,
								"title": newSheetName
							],
							"fields": "title"
						]
					]
				]
			]
			
			request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
			
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.renameSheetInSpreadsheet - New Filename \(newSheetName), SpreadsheetID: \(spreadsheetID)"
			)
			
			// Handle the response
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				logMessage = "Sheet renamed successfully: \(json)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .info)
			}
		} else {
			renameResult = false
		}
		
	} else {
		renameResult = false
	}
	
	return(renameResult)
}

// deleteSheet - Function to delete a sheet from a Google Sheets spreadsheet
//	Parameters:
//		spreadsheetID: the Google Drive FileID of the spreadsheet
//		sheetID: the ID of the individual sheet in the spreadsheet to be deleted
//		newSheetName: the name to rename the sheet in the spreadsheet to
//	Returns:
//		returns a response JSON
//	Throws:
//
func deleteSheet(spreadsheetID: String, sheetID: Int) async throws -> [String: Any]? {
	var logMessage: String
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID):batchUpdate"
	
	guard let url = URL(string: urlString) else {
		logMessage = "ERROR: invalid URLString in deleteSheet URL: \(urlString)"
		await AppLogger.shared.log(logMessage, level: .error)
		throw URLError(.badURL)
	}
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {		// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			
			// Request body to delete a sheet
			let body: [String: Any] = [
				"requests": [
					[
						"deleteSheet": [
							"sheetId": sheetID
						]
					]
				]
			]
			request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
			
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.deleteSheet - SpreadSheet ID \(spreadsheetID), Sheet Num \(sheetID)"
			)
			
			// Parse and return the response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				logMessage = "INFO: Sheet deleted successfully: \(json)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .info)
				return json
			}
		}
	}
	return nil
}

// deleteFile - Function to permanently delete an entire file from Google Drive
//	Parameters:
//		fileID: the Google Drive FileID of the file to delete
//	Returns:
//		a boolean flag as to whether the file was deleted successfully
//	Throws:
//
func deleteFile(fileID: String) async throws -> Bool {
	var logMessage: String
	let urlString = "https://www.googleapis.com/drive/v3/files/\(fileID)"

	guard let url = URL(string: urlString) else {
		logMessage = "ERROR: invalid URLString in deleteFile URL: \(urlString)"
		await AppLogger.shared.log(logMessage, level: .error)
		throw URLError(.badURL)
	}
	let tokenFound = await getAccessToken()
	guard tokenFound, let accessToken = oauth2Token.accessToken else {
		return false
	}

	var request = URLRequest(url: url)
	request.httpMethod = "DELETE"
	request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

	// Drive's DELETE endpoint returns 204 No Content on success, unlike the 200
	// performRequestWithRetry expects, so this call handles retries itself.
	let retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]
	let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
	var attempt = 0

	while true {
		attempt += 1
		let data: Data
		let response: URLResponse
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			if attempt < maxAttempts {
				let delaySeconds = 1 << (attempt - 1) // 1, 2, 4, 8...
				logMessage = "WARNING: deleteFile - URLSession request failed for FileID: \(fileID), error: \(error.localizedDescription), retrying in \(delaySeconds) seconds (attempt \(attempt))"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .warning)
				try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
				continue
			} else {
				logMessage = "ERROR: deleteFile - URLSession request failed for FileID: \(fileID), error: \(error.localizedDescription), attempt: \(attempt)"
				await AppLogger.shared.log(logMessage, level: .error)
				throw error
			}
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			logMessage = "ERROR: deleteFile - response was not an HTTPURLResponse for FileID: \(fileID)"
			await AppLogger.shared.log(logMessage, level: .error)
			throw NSError(domain: "Invalid Response", code: -1, userInfo: nil)
		}

		let statusCode = httpResponse.statusCode

		if retryableStatusCodes.contains(statusCode), attempt < maxAttempts {
			let delaySeconds = 1 << (attempt - 1) // 1, 2, 4, 8...
			logMessage = "WARNING: deleteFile - HTTP \(statusCode) for FileID: \(fileID), retrying in \(delaySeconds) seconds (attempt \(attempt))"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .warning)
			try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
			continue
		}

		guard statusCode == 204 || statusCode == 200 else {
			logMessage = "ERROR: deleteFile - HTTP Result Error Code: \(statusCode) for FileID: \(fileID)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return false
		}

		logMessage = "INFO: File deleted successfully - FileID: \(fileID)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .info)
		return true
	}
}

struct GoogleSheetsResponse: Codable {
	struct Sheet: Codable {
		let properties: Properties
	}
	
	struct Properties: Codable {
		let title: String
		let sheetId: Int
	}
	
	let sheets: [Sheet]
}

// getSheetCount - Function to return the count of sheets in a Google Drive spreadsheet
//	Parameters:
//		spreadsheetID: the Google Drive FileID of the spreadsheet
//	Returns:
//		returns an integer count of sheets
//	Throws: 
//
func getSheetCount(spreadsheetID: String) async throws -> Int {
	var logMessage: String
	var sheetCount: Int = 0
	
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID)"
	guard let url = URL(string: urlString) else {
		logMessage = "ERROR: invalid URLString in getSheetCount URL: \(urlString)"
		await AppLogger.shared.log(logMessage, level: .error)
		throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
	}
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {

			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			//		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "Utilities.getSheetCount - SpreadSheet ID \(spreadsheetID)"
			)
			
			// Parse the JSON response
			let googleSheetsResponse = try JSONDecoder().decode(GoogleSheetsResponse.self, from: data)
			sheetCount = googleSheetsResponse.sheets.count
		}
	}
	// Return the count of sheets
	return sheetCount
		
}


// getAccessToken - Function to check if the user has a valid, non-expired OAuth Access Token and
//		if not attempt to refresh the Access Token
//	Parameters:
//		none
//	Returns:
//		returns a boolean indicating whether the user has a valid OAuth Access Token
//	Throws:
//
func getAccessToken() async -> Bool {
	var returnResult: Bool = true
	var logMessage: String
	
	guard oauth2Token.accessToken != nil else {
		logMessage = "ERROR: Access Token is nil in getAccessToken"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .error)
		return false
	}
	
	guard isTokenExpired() else {
		// Access token exists and isn't expired — nothing further to do.
		return true
	}
	
	logMessage = "INFO: Access Token expired"
	print(logMessage)
	await AppLogger.shared.log(logMessage, level: .info)
	
	guard oauth2Token.refreshToken != nil else {
		logMessage = "ERROR: Refresh Token is nil in getAccessToken"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .error)
		return false
	}
	
	guard oauth2Token.clientID != nil else {
		logMessage = "ERROR: Client ID is nil in getAccessToken"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .error)
		return false
	}
	
	do {
		let time = Date()
		let timeFormatter = DateFormatter()
		timeFormatter.dateFormat = "HH:mm"
		let stringDate = timeFormatter.string(from: time)
		print("Refreshing Access Token at \(stringDate)")
		let (newExpiryDate, newAccessToken) = try await refreshAccessToken()
		
		oauth2Token.expiresAt = newExpiryDate
		oauth2Token.accessToken = newAccessToken
	} catch {
		returnResult = false
		logMessage = "WARNING: Could not refresh access Token"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .warning)
	}
	
	return returnResult
}
// isTokenExpired - Function to check if the user's OAuth token is expired (i.e. current date/time is past expiry date/time)
//	Parameters:
//		none
//	Returns:
//		returns a boolean indicating whether the user's OAuth token is expired
//	Throws:
//
func isTokenExpired() -> Bool {
	let token = oauth2Token.accessToken
	if let token = token {
		let tokenExpiry = oauth2Token.expiresAt
		// Check if current date/time > token expiry date/time and return result
		if let tokenExpiry = tokenExpiry {
			return Date() >= tokenExpiry
		} else {
			return true
		}
	} else {
		return true // No token available
	}
}

// refreshAccessToken - Function to attempt to refresh user's OAuth token
//	Parameters:
//		none
//	Returns:
//		the new token expiry date and new OAuth access token
//	Throws:
//
func refreshAccessToken() async throws -> (Date?, String?) {
	var newAccessToken: String?
	var newTokenExpiryDate: Date?
	var logMessage: String
	var data: Data
	var response: URLResponse
	
	var bodyParameters = [String: String]()
	let url = URL(string: "https://oauth2.googleapis.com/token")!
	
	// Set up the request parameters
	var request = URLRequest(url: url)
	request.httpMethod = "POST"
	request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
	
	// HTTP request body with URL-encoded parameters
	let refreshToken = oauth2Token.refreshToken
	
	if let refreshToken = refreshToken {
		let clientID = oauth2Token.clientID
		if let clientID = clientID {
			bodyParameters = [
				"client_id": clientID,
				"refresh_token": refreshToken,
				"grant_type": "refresh_token"
			]
			
			request.httpBody = bodyParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
			
			let maxAttempts = PgmConstants.maxSheetAttempts // number of times to retry
			
			let (data, response) = try await performRequestWithRetry(
				request: request,
				maxAttempts: maxAttempts,
				context: "refreshAccessToken - request url: \(request)"
			)
			
			// Parse the response JSON to retrieve the new access token
			guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			      let newAccessToken = json["access_token"] as? String,
			      let expiresIn = json["expires_in"] as? Double
			else {
				logMessage = "ERROR: Invalid JSON structure in response to Access Token refresh"
				await AppLogger.shared.log(logMessage, level: .error)
				throw NSError(domain: "Invalid JSON structure", code: -1, userInfo: nil)
			}
			let newExpirationDate = Date().addingTimeInterval(expiresIn)
			return(newExpirationDate, newAccessToken)
		} else {
			logMessage = "ERROR: Client ID is nil refreshing Access Token"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		}
	} else {
		logMessage = "Error: Refresh Token is nil refreshing Access Token"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .error)
	}
	return(newTokenExpiryDate, newAccessToken)
	
}



import Foundation

/// Performs a URLSession data task with automatic retry on transient network
/// errors and HTTP 429/500/502/503/504 responses. Honors the Retry-After
/// header for 429s (capped at `maxRetryAfterSeconds`), and falls back to
/// exponential backoff (1, 2, 4, 8... seconds) for everything else.
///
/// This centralizes the retry loop previously duplicated across
/// refreshAccessToken, getSheetCount, deleteSheet, renameSheetInSpreadsheet,
/// createNewSheetInSpreadsheet, and writeSheetCells.
///
/// - Parameters:
///   - request: the URLRequest to perform.
///   - maxAttempts: maximum number of attempts before giving up and throwing.
///   - context: a short string identifying the caller and relevant IDs, used
///     as the prefix for every log message this function writes — e.g.
///     `"writeSheetCells - Range: A1:B2, FileID abc123"`. Keep it specific
///     enough to find the right log lines, since this function's own log
///     lines no longer include per-call-site details beyond what you pass in.
/// - Returns: the successful `(Data, HTTPURLResponse)` pair once the request
///   returns HTTP 200.
/// - Throws: the underlying `URLSession` error if attempts are exhausted on
///   a transport failure; an `NSError` (domain `"Invalid Response"`) if the
///   response isn't an `HTTPURLResponse`, or if the final status code isn't
///   200 after retries are exhausted.
func performRequestWithRetry(
	request: URLRequest,
	maxAttempts: Int,
	context: String
) async throws -> (Data, HTTPURLResponse) {
	
	let retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]
	let maxRetryAfterSeconds = 60
	
	var attempt = 0
	
	while true {
		attempt += 1
		
		let data: Data
		let response: URLResponse
		
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			if attempt < maxAttempts {
				let delaySeconds = 1 << (attempt - 1) // 1, 2, 4, 8...
				let logMessage = "WARNING: \(context) - URLSession request failed: \(error.localizedDescription), retrying in \(delaySeconds) seconds (attempt \(attempt))"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .warning)
				try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
				continue
			} else {
				let logMessage = "ERROR: \(context) - URLSession request failed after \(attempt) attempts: \(error.localizedDescription)"
				await AppLogger.shared.log(logMessage, level: .error)
				throw error
			}
		}
		
		guard let httpResponse = response as? HTTPURLResponse else {
			let logMessage = "ERROR: \(context) - response was not an HTTPURLResponse"
			await AppLogger.shared.log(logMessage, level: .error)
			throw NSError(domain: "Invalid Response", code: -1, userInfo: nil)
		}
		
		let statusCode = httpResponse.statusCode
		
		if retryableStatusCodes.contains(statusCode), attempt < maxAttempts {
			let delaySeconds: Int
			if statusCode == 429, let retryAfterSeconds = retryAfterDelay(from: httpResponse) {
				delaySeconds = min(retryAfterSeconds, maxRetryAfterSeconds)
			} else {
				delaySeconds = 1 << (attempt - 1) // 1, 2, 4, 8...
			}
			
			let logMessage = "WARNING: \(context) - HTTP \(statusCode), retrying in \(delaySeconds) seconds (attempt \(attempt))"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
			continue
		}
		
		// Single throw point for a final non-200 status, whether or not it
		// was ever retryable — no separate post-loop check needed.
		guard statusCode == 200 else {
			let logMessage = "ERROR: \(context) - HTTP Result Error Code: \(statusCode)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
		}
		
		return (data, httpResponse)
	}
}

/// Parses the Retry-After header from an HTTP response, which per RFC 7231
/// can be either a delay in seconds ("120") or an HTTP-date
/// ("Wed, 21 Oct 2025 07:28:00 GMT"). Returns nil if the header is absent
/// or unparseable, so callers can fall back to their own backoff strategy.
/// Callers are responsible for capping the returned value.
func retryAfterDelay(from response: HTTPURLResponse) -> Int? {
	guard let value = response.value(forHTTPHeaderField: "Retry-After") else {
		return nil
	}
	
	// Most common case: a plain integer number of seconds
	if let seconds = Int(value) {
		return max(0, seconds)
	}
	
	// Less common: an HTTP-date giving the exact time to retry at
	let formatter = DateFormatter()
	formatter.locale = Locale(identifier: "en_US_POSIX")
	formatter.timeZone = TimeZone(identifier: "GMT")
	formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
	
	if let date = formatter.date(from: value) {
		let interval = date.timeIntervalSinceNow
		return interval > 0 ? Int(interval.rounded(.up)) : 0
	}
	
	return nil
}

func getCurrentMonthYear() -> (String, String) {
	    var currentMonthName: String = ""
	    var currentYearName: String = ""
	      
	    if let monthInt = Calendar.current.dateComponents([.month], from: Date()).month {
		    currentMonthName = monthArray[monthInt - 1]
	    }
	    
	    if let yearInt = Calendar.current.dateComponents([.year], from: Date()).year {
		    currentYearName = String(yearInt)
	    }
	    return(currentMonthName, currentYearName)
}

// getPrevMonthYear - Function to check if the user has a valid, non-expired OAuth Access Token and
//		if not attempt to refresh the Access Token
//	Parameters:
//		none
//	Returns:
//		returns strings containing the name of the previous month and the year of that month (in case previous month is December)
//	Throws:
//
func getPrevMonthYear() -> (String, String) {
	    var prevMonthName: String = ""
	    var billingYear: String = ""
	    
	    if let monthInt = Calendar.current.dateComponents([.month], from: Date()).month {
			var prevMonthInt = monthInt - 2                  // subtract 2 from current month name to get prev month with 0-based array index
			if prevMonthInt == -1 {
				prevMonthInt = 11
			}
			// Get previous month name
			prevMonthName = monthArray[prevMonthInt]
	    }
	    
		// Check if previous month is December and if so, decrement year
	    if let yearInt = Calendar.current.dateComponents([.year], from: Date()).year {
			if prevMonthName == monthArray[11] {            // if month is December than use previous year
				billingYear = String(yearInt - 1)
			} else {
				billingYear = String(yearInt)
			}
	    }
	    return(prevMonthName, billingYear)
}

// getCurrentQuarter - Returns an integer from 1-4 indicating the current quarter date
//
func getQuarterNum(monthName: String) -> Int {
	var quarterNum: Int = 0
	
	switch monthName {
		case "Jan":
			quarterNum = 1
		case "Feb":
			quarterNum = 1
		case "Mar":
			quarterNum = 1
		case "April":
			quarterNum = 2
		case "May":
			quarterNum = 2
		case "June":
			quarterNum = 2
		case "July":
			quarterNum = 3
		case "Aug":
			quarterNum = 3
		case "Sept":
			quarterNum = 3
		case "Oct":
			quarterNum = 4
		case "Nov":
			quarterNum = 4
		case "Dec":
			quarterNum = 4
		default:
			print("Error: Invalid billing quarter in getQuarterNum for \(monthName)")
			break
		}
	
	return(quarterNum)
}



// getAccessToken - Function to check if the user has a valid, non-expired OAuth Access Token and
//		if not attempt to refresh the Access Token
//	Parameters:
//		none
//	Returns:
//		returns a boolean indicating whether the user has a valid OAuth Access Token
//	Throws:
//
func findPrevMonthYear(currentMonth: String, currentYear: String) -> (String, String) {
	    var prevMonthName: String = ""
	    var prevYearName: String = ""
	    var monthNum: Int = 0
	    
	    if currentMonth == "Jan" {
			let prevYear = Int(currentYear) ?? 0
			prevYearName = String(prevYear - 1)
	    } else {
			prevYearName = currentYear
	    }
	    
	    if let index = monthArray.firstIndex(of: currentMonth) {
			if index == 0 {
				monthNum = 11
			} else {
				monthNum = index - 1
			}
			prevMonthName = monthArray[monthNum]
	    }
	    
	    return(prevMonthName, prevYearName)
}

// removeCommas - This function removes all commas from a string
//	Parameters:
//		sourceString - a string to remove commas from
//	Returns:
//		returns the sourceString with the commas removed
//	Throws:
//
func removeCommas(sourceString: String) -> String {
	return(sourceString.replacingOccurrences(of: ",", with: ""))
}

// buildTutorAvailabilityRow - This function reads in the Availability data for a Tutor from the Availability tab on their Timesheet.  The data may not be filled in.
//	Parameters:
//		tutorName -
//		timesheetFileID -
//		tutorStatus -
//		tutorStudentCount -
//	Returns:
//		returns a TutorAvailabilityRow
//	Throws:
//
func buildTutorAvailabilityRow(tutorName: String, timesheetFileID: String, tutorStatus: TutorStatusOption, tutorStudentCount: Int) async throws -> TutorAvailabilityRow {
	var logMessage: String
	
	var tutorAvailability: String = ""
	var mondayAvailability: String = ""
	var tuesdayAvailability: String = ""
	var wednesdayAvailability: String = ""
	var thursdayAvailability: String = ""
	var fridayAvailability: String = ""
	var saturdayAvailability: String = ""
	var sundayAvailability: String = ""
	var mondayLocation: String = ""
	var tuesdayLocation: String = ""
	var wednesdayLocation: String = ""
	var thursdayLocation: String = ""
	var fridayLocation: String = ""
	var saturdayLocation: String = ""
	var sundayLocation: String = ""
	
	var sheetData: SheetData?
	let range = PgmConstants.timesheetAvailabilityDataRange
	// read in the cells containing the Tutor's Availability data from the Timesheet Availability sheet
	do {
		sheetData = try await readSheetCells(fileID: timesheetFileID, range: range, logNote: "Reading Timesheet Availability for \(tutorName)")
		// Load the sheet cells into this Timesheet
		if let sheetData = sheetData {
			if sheetData.values.count > 0 {
				if !sheetData.values[0][1].isEmpty {
					tutorAvailability = sheetData.values[0][1]
				} else {
					print("Tutor Availability Not Specified for \(tutorName)")
				}
				
				if sheetData.values.indices.contains(3), sheetData.values[3].indices.contains(0) {
					if sheetData.values[3][0] == "Monday" {
						if sheetData.values.indices.contains(3), sheetData.values[3].indices.contains(1) {
							mondayAvailability = sheetData.values[3][1]
						} else {
//							print("Tutor Monday Availability Not Specified for \(tutorName)")
						}
						
						if sheetData.values.indices.contains(3), sheetData.values[3].indices.contains(2) {
							mondayLocation = sheetData.values[3][2]
						} else {
//							print("Tutor Monday Location Not Specified for \(tutorName)")
						}
					} else {
						print(" Tutor Monday Availability Data out of Line \(sheetData.values[3][0]) for \(tutorName)")
					}
				}
				
				if sheetData.values.indices.contains(4), sheetData.values[4].indices.contains(0) {
					if sheetData.values[4][0] == "Tuesday" {
						if sheetData.values.indices.contains(4), sheetData.values[4].indices.contains(1) {
							tuesdayAvailability = sheetData.values[4][1]
						} else {
//							print("Tutor Tuesday Availability Not Specified for \(tutorName)")
						}
						
						if sheetData.values.indices.contains(4), sheetData.values[4].indices.contains(2) {
							tuesdayLocation = sheetData.values[4][2]
						} else {
//							print("Tutor Tuesday Location Not Specified for \(tutorName)")
						}
					} else {
						print(" Tutor Tuesday Availability Data out of Line \(sheetData.values[4][0]) for \(tutorName)")
					}
				}
				
				if sheetData.values.indices.contains(5), sheetData.values[5].indices.contains(0) {
					if sheetData.values[5][0] == "Wednesday" {
						if sheetData.values.indices.contains(5), sheetData.values[5].indices.contains(1) {
							wednesdayAvailability = sheetData.values[5][1]
						} else {
//							print("Tutor Wednesday Availability Not Specified for \(tutorName)")
						}
						
						if sheetData.values.indices.contains(5), sheetData.values[5].indices.contains(2) {
							wednesdayLocation = sheetData.values[5][2]
						} else {
//							print( "Tutor Wednesday Location Not Specified for \(tutorName)")
						}
					} else {
						print(" Tutor Wednesday Availability Data out of Line \(sheetData.values[5][0]) for \(tutorName)")
					}
				}
				
				if sheetData.values.indices.contains(6), sheetData.values[6].indices.contains(0) {
					if  sheetData.values[6][0] == "Thursday" {
						if sheetData.values.indices.contains(6), sheetData.values[6].indices.contains(1) {
							thursdayAvailability = sheetData.values[6][1]
						} else {
//							print("Tutor Thursday Availability Not Specified for \(tutorName)")
						}
						
						if sheetData.values.indices.contains(6), sheetData.values[6].indices.contains(2) {
							thursdayLocation = sheetData.values[6][2]
						} else {
//							print( "Tutor Thursday Location Not Specified for \(tutorName)")
						}
					} else {
						print(" Tutor Thursday Availability Data out of Line \(sheetData.values[6][0]) for \(tutorName)")
					}
				}
				
				if sheetData.values.indices.contains(7), sheetData.values[7].indices.contains(0) {
					if sheetData.values[7][0] == "Friday" {
						if sheetData.values.indices.contains(7), sheetData.values[7].indices.contains(1) {
							fridayAvailability = sheetData.values[7][1]
						} else {
//							print("Tutor Friday Availability Not Specified for \(tutorName)")
						}
						
						if sheetData.values.indices.contains(7), sheetData.values[7].indices.contains(2) {
							fridayLocation = sheetData.values[7][2]
						} else {
//							print( "Tutor Friday Location Not Specified for \(tutorName)")
						}
					} else {
						print(" Tutor Friday Availability Data out of Line \(sheetData.values[7][0]) for \(tutorName)")
					}
				}
				
				if sheetData.values.indices.contains(8), sheetData.values[8].indices.contains(0) {
					if sheetData.values[8][0] == "Saturday" {
						if sheetData.values.indices.contains(8), sheetData.values[8].indices.contains(1) {
							saturdayAvailability = sheetData.values[8][1]
						} else {
//							print("Tutor Saturday Availability Not Specified for \(tutorName)")
						}
						
						if sheetData.values.indices.contains(8), sheetData.values[8].indices.contains(2) {
							saturdayLocation = sheetData.values[8][2]
						} else {
//							print( "Tutor Saturday Location Not Specified for \(tutorName)")
						}
					} else {
						print(" Tutor Saturday Availability Data out of Line \(sheetData.values[8][0]) for \(tutorName)")
					}
				}
				
				if sheetData.values.indices.contains(9), sheetData.values[9].indices.contains(0) {
					if sheetData.values[9][0] == "Sunday" {
						if sheetData.values.indices.contains(9), sheetData.values[9].indices.contains(1) {
							sundayAvailability = sheetData.values[9][1]
						} else {
//							print("Tutor Sunday Availability Not Specified for \(tutorName)")
						}
						
						if sheetData.values.indices.contains(9), sheetData.values[9].indices.contains(2) {
							sundayLocation = sheetData.values[9][2]
						} else {
//							print( "Tutor Sunday Location Not Specified for \(tutorName)")
						}
					} else {
						print(" Tutor Sunday Availability Data out of Line \(sheetData.values[9][0]) for \(tutorName)")
					}
				}
				
				
			}
		} else {
			
		}
	} catch {
		logMessage = "ERROR: could not read SheetCells for \(tutorName) Timesheet in buildTutorAvailabilityRow"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .error)
	}
	
	let tutorAvailabilityRow = TutorAvailabilityRow(tutorName: tutorName, tutorAvailability: tutorAvailability, tutorStatus: tutorStatus, tutorStudentCount: tutorStudentCount, mondayAvailability: mondayAvailability, mondayLocation: mondayLocation, tuesdayAvailability: tuesdayAvailability, tuesdayLocation: tuesdayLocation, wednesdayAvailability: wednesdayAvailability, wednesdayLocation: wednesdayLocation, thursdayAvailability: thursdayAvailability, thursdayLocation: thursdayLocation, fridayAvailability: fridayAvailability, fridayLocation: fridayLocation, saturdayAvailability: saturdayAvailability, saturdayLocation: saturdayLocation, sundayAvailability: sundayAvailability, sundayLocation: sundayLocation)
	
	return tutorAvailabilityRow
}

// validateDateField - This function checks if a Date string (from a Timesheet service entry) is for the month being billed.
//	Parameters:
//		dateField -
//		monthName -
//	Returns:
//		returns a boolean indicating whether the date is for the month being billed
//	Throws:
//
func validateDateField(dateField: String, monthName: String) -> Bool {
	var validDateField: Bool
	
	let firstSlash = dateField.firstIndex(of: "/")!
	
	let monthNumString = dateField.prefix(upTo: firstSlash)
	let monthNum = Int(monthNumString) ?? 0
	if monthArray[monthNum - 1] == monthName {
		validDateField = true
	} else {
		validDateField = false
	}
		
	return(validDateField)
}
