//
//  GoogleSignIn.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-20.
//

import Foundation
import Alamofire
import SwiftJWT
import GoogleAPIClientForREST


struct GoogleAPIClaims: Claims {
    var iss: String
    var sub: String
    var scope: String
    var aud: String
    var exp: Date
    var iat: Date
}

func getAuthToken() {
    let header = Header(kid: "1789f64393244102118ae4e1a93b0cd0182ff7cc")
    
    let claims = GoogleAPIClaims (
        iss: "service-account1@writeSeattle2.iam.gserviceaccount.com",
        sub: "service-account1@writeSeattle2.iam.gserviceaccount.com",
        scope: "https://www.googleapis.com/auth/documents.readonly",
        aud: "https://oauth2.googleapis.com/token",
        exp: Date().addingTimeInterval(3600),
        iat: Date()
     )
    
    var jwt = JWT(header: header, claims: claims)

    let privateKey =  """
    -----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCvPxln3yaW6OEK\nd3xFtnUqQAHyGNnwGAsoVPO9Csj77ckKcyLqDvUNfTNrKmEOpTRsrw+Ab1jzmQRD\nUKhZkySEEokr8fxNjkN6TRCIMT9i33QSe+aMO6Y1XvbEWJExlai7BgU3CbkAkpdZ\np2nnFptsqwOQEbYtRPO60nJPR3zMgg9+5nxkA5EeHh+NUQWTKKQYC0OoqfaWGF9b\nG4uZ6wGa63aDtxyLHKiwPNe35dmSJZrGEindMBF/ymwiSSJGsF4IMhclJxCbDWnI\nDhxXuGRm8buG0ecodYJ0cZWar6caAGwpdaifOh3L3euGjxYLJ7KnkBNWKVaf064w\nnkw2fazTAgMBAAECggEACo1soxx4HBjMY3Woou2Z/+zLXf+3Sj9QY+HVrKaN53Zw\nJ1pugEfDsGFZHsgpZv91ePpQa/K7svnRHJj3Qi/1JqTGsMHWAcXuwNo+6n+4qheV\nfpij9c7DsxQGtotn8GOE8QB4TbhrdO7ezgdU/hUwHIRU5xbbiiQZEkDvOpN6uGyE\n+yA9Dv65o+xUomYp1eh7Sm4mBjMNoIKA1AFlXsFRTFugG3dEiQQ9E2lIiEhfcbKV\nygHfpAOfa01OGQyrqzwfFqGRfyg855v2PafgUcRQqdhB2STutwF/qnrt3lR1cTki\njFE0j8STlSkMpJrn9Aqqv6NGFzuOa6velz186klIeQKBgQDUpIUi8aZuI5o/CwTq\ncnSa6lcEGk8a1S4NXSulN/M7iNXwsUGdKulTAriSIXSh3GQBSQPvpGFTeg9UwbOl\n8kZrfgOno5dKvjrqMUTXXAS5ZHOlZ1Tqmv/eaYKFAZmhu8yo8yvK9wrvJG32+hB0\nsRenRGqAWiZZWp0XgD3DoHm+CQKBgQDS+pS3Fe/Trwos6yD4l6Lt8ej4x2C9kKfo\n1ETbP13U5S3MuFZLakvPmxvl8bjEum55kObpnTeVnoNfrB8j9//ZfV2e8CNm7W5u\nii/qkeHXVQbDa0PiInk8iTzf0wBAibMZd65xa++tRe2E5wgiIWI3kg9Y+E+cg31s\nccWFXRQK+wKBgQCLoq260KzVzpNPqtDDk/12bURO8WfY2vyu0ewDRsZ25dh3gi7w\nImmtlS/W5hlM4QjavzPSfkNbKeA/bCOoaXxMwidsQkTrVBgkCc6HDWocxBYdG8nr\ndXVofCi1ZuOYDVbL60NquOd5OpbrhDKiLli2AntdZdWg/5wA/rmQaSUI4QKBgQDR\nvh4UefGH789c4pBPs2hdx45FrOjG7EWRWV3u3WsqGIDUsjnQFaeyh9BPZGS8516m\n6mA1xX+Z9hFDDrmSp50qGdD2DmQTkl2j9Ss3trnfuf7UThIZgQ4oGYN0PK9Wec6c\ntfeteJG5H/jGlGvoimm7NzCc0ZdL0Qjiw6SLNgKT+wKBgG5R0vkwl0zG/epk1yH1\nW5HzLJl3cV3+BE67Fh40s4UEo6FIb9sR2C2zd7jqd7dKGoF3zrbYn5OHEoYPNvEa\n8Mp+wv7/PSqk5iK2w8Wa3Zor8oier62bxeXIVCHH6xJ95MXDiq6h8w4lhsVI/mYL\nBhk8iIQTpYC7Jp8ayoWxa/+F\n-----END PRIVATE KEY-----\n
    """

    guard let privateKeyData = privateKey.data(using: .utf8) else {
        // Handle the case where the conversion fails
        print("Failed to convert string to data")
        return
    }
    var signedJWT = ""
    do {
        signedJWT = try jwt.sign(using: .rs256(privateKey: privateKeyData))
    } catch  {
        print("Failed to sign JWT: \(error)")
    }
        
    //==================== Exchange the JWT token for a Google OAuth2 access token: ====
        
    let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
    let params: Parameters = [
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": signedJWT,
        "scope": "https://www.googleapis.com/auth/documents.readonly"
    ]
    
    print( "Before AF request")
    
    AF.request("https://oauth2.googleapis.com/token",
               method: .post,
               parameters: params,
               encoding: URLEncoding.httpBody,
               headers: headers).responseJSON { response in
        print (response.result)
        switch response.result {
            //        <------------------------------------------------ Error message is returned here
        case .success(let value):
            let json = value as? [String: Any]
            if let json = json {
                let accessToken = json["access_token"] as? String
                print(accessToken)
                if let accessToken = accessToken {
 //                   fetchGoogleDocContent(accessToken: accessToken)
                }
            }
        case .failure(let error):
            print("Error getting access token: \(error)")
        }
    }
}

func fetchGoogleDocContent(accessToken: String) {
    
    let driveService = GTLRDriveService()
    //   driveService.authorizer = currentUser?.fetcherAuthorizer
 //   driveService.authorizer = accessToken

    let dquery = GTLRDriveQuery_FilesList.query()
    dquery.pageSize = 100
    let fileName = "ReferenceData"
    let root = "name = '\(fileName)' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed=false"
    dquery.q = root
    dquery.spaces = "drive"
    dquery.corpora = "user"
    dquery.fields = "files(id,name),nextPageToken"

    driveService.executeQuery(dquery, completionHandler: {(ticket, files, error) in
        if let filesList : GTLRDrive_FileList = files as? GTLRDrive_FileList {
            
            if let filesShow : [GTLRDrive_File] = filesList.files {
                var fileCount = filesShow.count
                switch fileCount {
                case 0:
                    print("Tutor timesheet file not found - '\(fileName)")
//                    GIDSignIn.sharedInstance.signOut()
    //                        isLoggedIn = false
                case 1:
                    let name = filesShow[0].name ?? ""
  //                  timesheetData.fileID = filesShow[0].identifier ?? ""
                    print(name)
 //                   self.loadStudentsServices(timesheetData: timesheetData, spreadsheetYear: spreadsheetYear, spreadsheetMonth: spreadsheetMonth)
                default:
                    print("Error: more than one tutor timesheet for '\(fileName)")
 //                   GIDSignIn.sharedInstance.signOut()
    //                       isLoggedIn = false
                }
                //                 print("files \(filesShow)")
                //                  for ArrayList in filesShow {
                //                      let name = ArrayList.name ?? ""
                //                      timesheetData.fileID = ArrayList.identifier ?? ""
                //                      print(name, timesheetData.fileID)
                //                  }
                
                
                
            } else {
                print("no files returned")
            }
        }
        else {
                print("error no files returned from Drive search call")
                return
            }
        
    })
}

