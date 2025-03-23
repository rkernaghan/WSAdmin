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
	var fileID: String = ""
	var fileFound: Bool = false
		
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			// URL for Google Sheets API
			let urlString = "https://www.googleapis.com/drive/v3/files?q=name='\(fileName)'&fields=files(id,name)"
			guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
				print("Invalid URL")
				return(false, " ")
			}
			
			// Set up the request with OAuth 2.0 token
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			
			// Use async URLSession to fetch the data
			
			let (data, response) = try await URLSession.shared.data(for: request)
			
			//        if let httpResponse = response as? HTTPURLResponse {
			//            print("Find File ID Error: \(httpResponse.statusCode)")
			//        }
			// Check if the response is successful
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid HTTP Response in getFileID", code: statusCode, userInfo: nil)
			}
			
			// Parse the JSON response
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			   let files = json["files"] as? [[String: Any]], !files.isEmpty,
			   let fileId = files.first?["id"] as? String {
				return (true, fileId)
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
func readSheetCells(fileID: String, range: String) async throws -> SheetData? {
	var values = [[String]]()
	var sheetData: SheetData?
		
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			// URL for Google Sheets API
			let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(fileID)/values/\(range)"
			guard let url = URL(string: urlString) else {
				throw URLError(.badURL)
			}
			
			// Set up the request with OAuth 2.0 token
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			
			// Use async URLSession to fetch the data
			//    print("Before Read Cells URL Session call \(fileID)")
			let (data, response) = try await URLSession.shared.data(for: request)
			//    print("After Read Cells URL Session call \(fileID)")
			if let httpResponse = response as? HTTPURLResponse {
				if httpResponse.statusCode != 200 {
					print("Read Sheet Cells HTTP Result Error Code: \(httpResponse.statusCode)")
				}
			}
			// Check if the response is successful
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				throw URLError(.badServerResponse)
			}
			
			// Decode the JSON data into the SheetData structure
			sheetData = try JSONDecoder().decode(SheetData.self, from: data)
		}
		
	}
	//        if let sheetData = sheetData {
	return sheetData
	//        }
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
func writeSheetCells(fileID: String, range: String, values: [[String]]) async throws -> Bool {
	var completionFlag: Bool = true

	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(fileID)/values/\(range)?valueInputOption=USER_ENTERED"
			guard let url = URL(string: urlString) else {
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
			
			// Perform the network request asynchronously using async/await
			let (data, response) = try await URLSession.shared.data(for: request)
			
			if let httpResponse = response as? HTTPURLResponse {
				if httpResponse.statusCode != 200 {
					print("Write Sheet Cells HTTP Result Error Code: \(httpResponse.statusCode)")
					completionFlag = false
				}
			}
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			// Handle the response (if needed)
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				//           print("writeSheetCells Response: \(json)")
			}
		}
	} else {
		completionFlag = false
	}
	return(completionFlag)
}

// requestAdditionalScopes - calls Google Cloud API to request user permission for additional API scope to read/write spreadsheet cells and get Google Drive FileID
//	Parameters:
//		additionalScopes: an array containing the Google Cloud Scopes requested
//	Returns:
//		a boolean indicating whether the request was successful
//
func requestAdditionalScopes(additionalScopes: [String]) async -> Bool {
	var requestResult: Bool = true
	
	// The additional scopes you want to request
	print("Additional Scopes Requested: \(additionalScopes)")
	
	// Ensure the user is already signed in
	guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
		print("User is not signed in.")
		return(false)
	}
	
	do {
		// Use async/await to request additional scopes
		guard let presentingWindow = await NSApplication.shared.mainWindow else {
			return(false)
		}
		let user = try await currentUser.addScopes(additionalScopes, presenting: presentingWindow)
		print("Additional scopes granted.")
		
		// Access granted scopes if needed
		if let grantedScopes = currentUser.grantedScopes {
			print("Granted scopes: \(grantedScopes)")
		}
	} catch {
		// Handle errors
		print("Error requesting additional scopes: \(error.localizedDescription)")
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
func renameGoogleDriveFile(fileId: String, newName: String) async throws -> Bool {
	var renameResult: Bool = true
	let urlString = "https://www.googleapis.com/drive/v3/files/\(fileId)"
	    
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			guard let url = URL(string: urlString) else {
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
			let (data, response) = try await URLSession.shared.data(for: request)
			
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			// Handle the response
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				print("File renamed successfully: \(json)")
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
//
//	Throws
//

func copyGoogleDriveFile(sourceFileId: String, newFileName: String) async throws -> [String: Any]? {
	
	let urlString = "https://www.googleapis.com/drive/v3/files/\(sourceFileId)/copy"
	
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			guard let url = URL(string: urlString) else {
				throw URLError(.badURL)
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
			let (data, response) = try await URLSession.shared.data(for: request)
			
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			// Parse and return the response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//				print("File copied successfully: \(json)")
				return json
			}
		}
	}
	return nil
}

// Function to add a permission to a Google Drive file
func addPermissionToFile(fileId: String, role: String, type: String, emailAddress: String? = nil) async throws -> [String: Any]? {
	
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			
			let urlString = "https://www.googleapis.com/drive/v3/files/\(fileId)/permissions"
			
			guard let url = URL(string: urlString) else {
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
			
			// Perform the network request asynchronously
			let (data, response) = try await URLSession.shared.data(for: request)
						
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				print("Error could not add permission: \(statusCode) for user \(String(describing: emailAddress)) on fileId \(fileId)")
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			
			// Parse and return the response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				print("Permission added successfully: \(json)")
				return json
			}
		}
	}
	return nil
}


// Function to get the sheet ID based on sheet name using spreadsheets.get
func getSheetIdByName(spreadsheetId: String, sheetName: String) async throws -> Int? {
	    
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)?fields=sheets.properties"
	
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			
			guard let url = URL(string: urlString) else {
				throw URLError(.badURL)
			}
			
			// Set up the request
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			
			// Perform the network request asynchronously
			let (data, response) = try await URLSession.shared.data(for: request)
			
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
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
func createNewSheetInSpreadsheet(spreadsheetId: String, sheetTitle: String) async throws -> [String: Any]? {
	
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate"
    
	guard let url = URL(string: urlString) else {
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
			
			// Perform the network request asynchronously
			let (data, response) = try await URLSession.shared.data(for: request)
			
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			// Parse and return the response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				print("Sheet created successfully: \(json)")
				return json
			}
		}
	}
    
	return nil
}


// Function to rename a specific sheet in a Google Sheets spreadsheet
func renameSheetInSpreadsheet(spreadsheetId: String, sheetId: Int, newSheetName: String) async throws -> Bool {
	var renameResult: Bool = true
	    
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
			
			let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate"
			
			guard let url = URL(string: urlString) else {
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
			
			// Perform the network request asynchronously
			let (data, response) = try await URLSession.shared.data(for: request)
			
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			// Handle the response
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				print("Sheet renamed successfully: \(json)")
			}
		} else {
			renameResult = false
		}
		
	} else {
		renameResult = false
	}
	
	return(renameResult)
}

// Function to delete a sheet from a Google Sheets spreadsheet
func deleteSheet(spreadsheetId: String, sheetId: Int) async throws -> [String: Any]? {
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate"
	
	guard let url = URL(string: urlString) else {
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
							"sheetId": sheetId
						]
					]
				]
			]
			request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
			
			// Perform the network request asynchronously
			let (data, response) = try await URLSession.shared.data(for: request)
			
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			// Parse and return the response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				print("Sheet deleted successfully: \(json)")
				return json
			}
		}
	}
	return nil
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

func getSheetCount(spreadsheetId: String) async throws -> Int {
	var sheetCount: Int = 0
	
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)"
	guard let url = URL(string: urlString) else {
		throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
	}
	let tokenFound = await getAccessToken()
	if tokenFound {
		let accessToken = oauth2Token.accessToken
		if let accessToken = accessToken {
//			let accessToken = oauth2Token.accessToken
//			if let accessToken = accessToken {
				var request = URLRequest(url: url)
				request.httpMethod = "GET"
				request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
				//		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
				
				// Send the request with async/await
				let (data, response) = try await URLSession.shared.data(for: request)
				
				// Check for HTTP errors
				if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
					throw NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)
				}
				
				// Parse the JSON response
				let googleSheetsResponse = try JSONDecoder().decode(GoogleSheetsResponse.self, from: data)
				sheetCount = googleSheetsResponse.sheets.count
//			}
		}
	}
	// Return the count of sheets
	return sheetCount
		
}


func getAccessToken() async -> (Bool) {
	var returnResult: Bool = true
	
	let accessToken = oauth2Token.accessToken
	
	if let accessToken = accessToken {
//		print("Access Token before check \(accessToken)")
		if isTokenExpired() {
			print("access token expired")
			do {
				let time = Date()
				let timeFormatter = DateFormatter()
				timeFormatter.dateFormat = "HH:mm"
				let stringDate = timeFormatter.string(from: time)
				print("Refreshing Access Token at \(stringDate)")
				let (newExpiryDate, newAccessToken) = try await refreshAccessToken()
				
				oauth2Token.expiresAt = newExpiryDate
				print("New Token expires at \(oauth2Token.expiresAt!)")
				oauth2Token.accessToken = newAccessToken
//				print("Access Token after refresh \(oauth2Token.accessToken!)")
//				print("Refresh Token after refresh \(oauth2Token.refreshToken!)")
			} catch {
				print("Could not refresh access Token")
			}
		} else {
//			print("Utilities-getAccessToken: Access Token is not expired")
			returnResult = true
		}
	} else {
		returnResult = false
		print("ERROR: Access Token is nil in getAccessToken")
	}
	
	return(returnResult)
}
	
func isTokenExpired() -> Bool {
	let token = oauth2Token.accessToken
	if let token = token {
		let tokenExpiry = oauth2Token.expiresAt
		if let tokenExpiry = tokenExpiry {
//			print("Checking token expiry - time: \(Date()) expires at: \(tokenExpiry)")
//			if Date() >= tokenExpiry {
//				print("Checking token expiry - time: \(Date()) expires at: \(tokenExpiry)")
//			} else {
//				print("Token not expired")
//			}
			return Date() >= tokenExpiry
		} else {
			return true
		}
	} else {
		return true // No token available
	}
}

func refreshAccessToken() async throws -> (Date?, String?) {
	var newAccessToken: String?
	var newTokenExpiryDate: Date?
	
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
			
			// Perform the network request asynchronously
			let (data, response) = try await URLSession.shared.data(for: request)
			
			// Check for HTTP response status
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
				throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
			}
			
			// Parse the response JSON to retrieve the new access token
			guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			      let newAccessToken = json["access_token"] as? String,
			      let expiresIn = json["expires_in"] as? Double
			else {
				throw NSError(domain: "Invalid JSON structure", code: -1, userInfo: nil)
			}
			let newExpirationDate = Date().addingTimeInterval(expiresIn)
			return(newExpirationDate, newAccessToken)
		} else {
			print("Error: Client ID is nil")
	
		}
	} else {
		print("Error: Refresh Token is nil")
		
	}
	return(newTokenExpiryDate, newAccessToken)
	
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

func getPrevMonthYear() -> (String, String) {
	    var prevMonthName: String = ""
	    var billingYear: String = ""
	    
	    if let monthInt = Calendar.current.dateComponents([.month], from: Date()).month {
			var prevMonthInt = monthInt - 2                  // subtract 2 from current month name to get prev month with 0-based array index
			if prevMonthInt == -1 {
				prevMonthInt = 11
			}
			prevMonthName = monthArray[prevMonthInt]
	    }
	    
	    if let yearInt = Calendar.current.dateComponents([.year], from: Date()).year {
			if prevMonthName == monthArray[11] {            // if month is December than use previous year
				billingYear = String(yearInt - 1)
			} else {
				billingYear = String(yearInt)
			}
	    }
	    return(prevMonthName, billingYear)
}

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

func removeCommas(sourceString: String) -> String {
	return(sourceString.replacingOccurrences(of: ",", with: ""))
}

// This function reads in the Availability data for a Tutor from the Availability tab on their Timesheet.  The data may not be filled in.
func buildTutorAvailabilityRow(tutorName: String, timesheetFileID: String, tutorStatus: String, tutorStudentCount: Int) async throws -> TutorAvailabilityRow {
	
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
		sheetData = try await readSheetCells(fileID: timesheetFileID, range: range)
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
		print("ERROR: could not read SheetCells for \(tutorName) Timesheet")
		
		
	}
	let tutorAvailabilityRow = TutorAvailabilityRow(tutorName: tutorName, tutorAvailability: tutorAvailability, tutorStatus: tutorStatus, tutorStudentCount: tutorStudentCount, mondayAvailability: mondayAvailability, mondayLocation: mondayLocation, tuesdayAvailability: tuesdayAvailability, tuesdayLocation: tuesdayLocation, wednesdayAvailability: wednesdayAvailability, wednesdayLocation: wednesdayLocation, thursdayAvailability: thursdayAvailability, thursdayLocation: thursdayLocation, fridayAvailability: fridayAvailability, fridayLocation: fridayLocation, saturdayAvailability: saturdayAvailability, saturdayLocation: saturdayLocation, sundayAvailability: sundayAvailability, sundayLocation: sundayLocation)
	
	return tutorAvailabilityRow
}
