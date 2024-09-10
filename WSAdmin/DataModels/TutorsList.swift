//
//  TutorsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class TutorsList {
    var tutorsList = [Tutor]()
    
    func addTutor(newTutor: Tutor) {
        tutorsList.append(newTutor)
    }
    
    func printAll() {
        for tutor in tutorsList {
            print ("Tutor Name is \(tutor.tutorName)")
        }
    }
    
    func saveTutorData() {
        var referenceFileID: String
        var tutorDataFileID: String
        var updateValues: [[String]] = []
        
        var tutorKey: String = " "
        var tutorName: String = " "
        var tutorPhone: String = " "
        var tutorEmail: String = " "
        
        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
            tutorDataFileID = PgmConstants.prodTutorDataFileID
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
            tutorDataFileID = PgmConstants.testTutorDataFileID
        }
        
        let sheetService = GTLRSheetsService()
        let spreadsheetID = referenceFileID
        let tutorCount = tutorsList.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
            
        let newRow = PgmConstants.firstTimesheetRow + tutorCount
        print("New row", newRow)
        let newRowString = String(newRow)
        let range = PgmConstants.tutorRange + String(tutorCount + PgmConstants.tutorStartingRowNumber)
        print("Range", range)
  
        var tutorNum = 0
        while tutorNum < tutorCount {
            tutorKey = tutorsList[tutorNum].tutorKey
            tutorName = tutorsList[tutorNum].tutorName
            tutorPhone = tutorsList[tutorNum].tutorPhone
            tutorEmail = tutorsList[tutorNum].tutorEmail
            
            updateValues.insert([tutorKey, tutorName, tutorEmail, tutorPhone], at: tutorNum)
            tutorNum += 1
        }
        
        
        let valueRange = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
        valueRange.majorDimension = "ROWS" // Indicates horizontal row insert
        valueRange.range = range
        valueRange.values = updateValues
        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: spreadsheetID, range: range)
        query.valueInputOption = "USER_ENTERED"
        sheetService.executeQuery(query) { ticket, object, error in
            if let error = error {
                print(error)
                print("Failed to save data:\(error.localizedDescription)")
                return
            }
            else {
                print("Tutors saved")
            }
        }
    }
    
}
