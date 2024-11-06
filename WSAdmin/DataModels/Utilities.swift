//
//  Utilities.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-13.
//

import Foundation
import GoogleSignIn

func getFileIDAsync(fileName: String) async throws -> (Bool, String) {
	var fileID: String = ""
	var fileFound: Bool = false
//	var accessToken: String
	
//	let currentUser = GIDSignIn.sharedInstance.currentUser
//	if let user = currentUser {
//		accessToken = user.accessToken.tokenString
		
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
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
			throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
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
	else {
		return(false, "")
	}
}

func readSheetCells(fileID: String, range: String) async throws -> SheetData? {
	var values = [[String]]()
	var sheetData: SheetData?
	
//	let currentUser = GIDSignIn.sharedInstance.currentUser
//	if let user = currentUser {
//		accessToken = user.accessToken.tokenString
		
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
		
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
				print("Read Sheet HTTP Result Error Code: \(httpResponse.statusCode)")
			}
		}
		// Check if the response is successful
		guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
			throw URLError(.badServerResponse)
		}
		
		// Decode the JSON data into the SheetData structure
		sheetData = try JSONDecoder().decode(SheetData.self, from: data)
		
	}
	//        if let sheetData = sheetData {
	return sheetData
	//        }
}


func writeSheetCells(fileID: String, range: String, values: [[String]]) async throws -> Bool {
	var completionFlag: Bool = true
//	var accessToken: String
	
//	let currentUser = GIDSignIn.sharedInstance.currentUser
//	if let user = currentUser {
//		accessToken = user.accessToken.tokenString

	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
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
		
		// Check for HTTP response status
		guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
			let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
			throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
		}
		
		// Handle the response (if needed)
		if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
			//           print("writeSheetCells Response: \(json)")
		}
	} else {
		completionFlag = false
	}
	return(completionFlag)
}

func renameGoogleDriveFile(fileId: String, newName: String) async throws {
//	    var accessToken: String
	    
	let urlString = "https://www.googleapis.com/drive/v3/files/\(fileId)"
	    
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
	
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
	}
}

// Function to copy a Google Drive file
func copyGoogleDriveFile(sourceFileId: String, newFileName: String) async throws -> [String: Any]? {
	
	let urlString = "https://www.googleapis.com/drive/v3/files/\(sourceFileId)/copy"
	
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
		
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
				print("File copied successfully: \(json)")
				return json
		}
	}
	return nil
}

// Function to add a permission to a Google Drive file
func addPermissionToFile(fileId: String, role: String, type: String, emailAddress: String? = nil) async throws -> [String: Any]? {
	
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
		
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
			throw NSError(domain: "Invalid Response", code: statusCode, userInfo: nil)
		}
		
		// Parse and return the response JSON
		if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
			print("Permission added successfully: \(json)")
			return json
		}
	}
	return nil
}


// Function to get the sheet ID based on sheet name using spreadsheets.get
func getSheetIdByName(spreadsheetId: String, sheetName: String) async throws -> Int? {
//	    var accessToken: String
	    
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)?fields=sheets.properties"
	
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
		
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
	// If the sheet name was not found, return nil
	return nil
}

// Function to add a new sheet to a Google Sheets spreadsheet
func createNewSheetInSpreadsheet(spreadsheetId: String, sheetTitle: String) async throws -> [String: Any]? {
	
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate"
    
	guard let url = URL(string: urlString) else {
		throw URLError(.badURL)
	}
	
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {

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
    
	return nil
}


// Function to rename a specific sheet in a Google Sheets spreadsheet
func renameSheetInSpreadsheet(spreadsheetId: String, sheetId: Int, newSheetName: String) async throws {
	    
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
		 			
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
	}
}

// Function to delete a sheet from a Google Sheets spreadsheet
func deleteSheet(spreadsheetId: String, sheetId: Int) async throws -> [String: Any]? {
	let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate"
	
	guard let url = URL(string: urlString) else {
		throw URLError(.badURL)
	}
	let (tokenFound, accessToken) = await getAccessToken()
	if tokenFound {
		// Set up the request
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
	return nil
}

func getAccessToken() async -> (Bool, String) {
	var returnResult: Bool = true
	var returnToken: String = ""
	
	let accessToken = oauth2Token.accessToken
	if let accessToken = accessToken {
	
		if isTokenExpired() {
			do {
				returnToken = try await refreshAccessToken()
				oauth2Token.accessToken = returnToken
			} catch {
				print("Could not refresh access Token")
			}
		} else {
			returnToken = accessToken
			returnResult = true
		}
	} else {
		returnResult = false
	}
	
	return(returnResult, returnToken)
}
	
func isTokenExpired() -> Bool {
	let token = oauth2Token.accessToken
	if let token = token {
		let tokenExpiry = oauth2Token.expiresAt
		if let tokenExpiry = tokenExpiry {
			return Date() >= tokenExpiry
		} else {
			return true
		}
	} else {
		return true // No token available
	}
}

func refreshAccessToken() async throws -> String {
	var bodyParameters = [String: String]()
	let url = URL(string: "https://oauth2.googleapis.com/token")!
	
	// Set up the request parameters
	var request = URLRequest(url: url)
	request.httpMethod = "POST"
	request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
	
	// HTTP request body with URL-encoded parameters
	let refreshToken = oauth2Token.refreshToken
	let clientID = oauth2Token.clientID
	if let refreshToken = refreshToken {
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
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			   let accessToken = json["access_token"] as? String {
				return accessToken
			} else {
				throw NSError(domain: "Parsing Error", code: -1, userInfo: nil)
			}
		} else {
			print("Error: Client ID is nil")
			return ""
		}
	} else {
		print("Error: Refresh Token is nil")
		return ""
	}
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


