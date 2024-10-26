//
//  Utilities.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-13.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

func getFileID(fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
//         print("Getting fileID for \(fileName)")
         let driveService = GTLRDriveService()
         let currentUser = GIDSignIn.sharedInstance.currentUser
//        if let user = GIDSignIn.sharedInstance().currentUser {
            driveService.authorizer = currentUser?.fetcherAuthorizer
//        }
 
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "name = '\(fileName)' and trashed=false"
        query.fields = "files(id, name)"
         driveService.executeQuery(query) { (ticket, result, error) in

             if let error = error {
                 completion(.failure(error))
             } else if let fileList = result as? GTLRDrive_FileList, let files = fileList.files, let file = files.first {
                 print("FileID returned")
                     completion(.success(file.identifier ?? ""))
                 } else {
                     completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "File not found"])))
                 }
             }
         }

func getFileIDAsync(fileName: String) async throws -> (Bool, String) {
    var fileID:String = ""
    var fileFound: Bool = false
    var yourOAuthToken: String
    
    let currentUser = GIDSignIn.sharedInstance.currentUser
    if let user = currentUser {
        yourOAuthToken = user.accessToken.tokenString
        
// URL for Google Sheets API
        let urlString = "https://www.googleapis.com/drive/v3/files?q=name='\(fileName)'&fields=files(id,name)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            print("Invalid URL")
            return(false, " ")
        }
        
// Set up the request with OAuth 2.0 token
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(yourOAuthToken)", forHTTPHeaderField: "Authorization")
        
// Use async URLSession to fetch the data

        let (data, response) = try await URLSession.shared.data(for: request)
   
        if let httpResponse = response as? HTTPURLResponse {
            print("Find File ID Error: \(httpResponse.statusCode)")
        }
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


func listDriveFiles() {
    print("List files available to user")
    let driveService = GTLRDriveService()
    let currentUser = GIDSignIn.sharedInstance.currentUser
    driveService.authorizer = currentUser?.fetcherAuthorizer
    
    let dquery = GTLRDriveQuery_FilesList.query()
    dquery.pageSize = 100
    
//       let root = "name = '\(fileName)' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed=false"
//       dquery.q = root
    dquery.spaces = "drive"
    dquery.corpora = "user"
    dquery.fields = "files(id,name),nextPageToken"
// Retrieve all files
    driveService.executeQuery(dquery, completionHandler: {(ticket, files, error) in
        if let error = error {
            print(error)
            print("Error with listing files:\(error)")
            return
        } else {
            print("Retrieved list of user files")
            return()
        }
    })
}

func readSheetCells(fileID: String, range: String) async throws -> SheetData? {
    var values = [[String]]()
    var accessToken: String
    var sheetData: SheetData?
    
    let currentUser = GIDSignIn.sharedInstance.currentUser
    if let user = currentUser {
        accessToken = user.accessToken.tokenString
        
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
            print("Read Sheet HTTP Result Code: \(httpResponse.statusCode)")
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
    var accessToken: String
    
    let currentUser = GIDSignIn.sharedInstance.currentUser
    if let user = currentUser {
        accessToken = user.accessToken.tokenString
        
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
            print("writeSheetCells Response: \(json)")
        }
    } else {
        completionFlag = false
    }
    return(completionFlag)
}

func getCurrentMonthYear() -> (String, String) {
    var monthName: String = ""
    var billingYear: String = ""
    
    if let monthInt = Calendar.current.dateComponents([.month], from: Date()).month {
        var monthInt = monthInt - 1                  // subtract 1 from current month number to get  0-based array index
        monthName = monthArray[monthInt]
    }
    
    if let yearInt = Calendar.current.dateComponents([.year], from: Date()).year {
            billingYear = String(yearInt)
    }
    
    return(monthName, billingYear)
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
