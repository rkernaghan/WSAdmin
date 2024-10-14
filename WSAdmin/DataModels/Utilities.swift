//
//  Utilities.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-13.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher




func getFileID(fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        
         print("Getting fileID for \(fileName)")
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
                     completion(.success(file.identifier ?? ""))
                 } else {
                     completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "File not found"])))
                 }
             }
         }

     

