//
//  RefDataModel.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-02.
//

import Foundation

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class RefDataVM  {
    
//
// This function loads the main reference data from the ReferenceData sheet.
// 1) Call Google Drive to search for for the Tutor's timesheet file name in order to get the file's Google File ID
// 2) If only a single file is retreived, call loadStudentServices to retrieve the Tutor's assigned Student list, Services list and Notes options as well as the Tutor service history for the month
//
  
    
   
    func loadReferenceData(referenceData: ReferenceData)  {
        var referenceFileID: String
        var tutorDataFileID: String

        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
            tutorDataFileID = PgmConstants.prodTutorDataFileID
            
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
            tutorDataFileID = PgmConstants.testTutorDataFileID
        }
        
        referenceData.dataCounts.loadDataCounts(referenceFileID: referenceFileID, tutorDataFileID: tutorDataFileID, referenceData: referenceData)
        if referenceData.dataCounts.isDataCountsLoaded {
 
        }
        
    }
    
// Load the Student and Service counts for a tutor from the Tutor Data sheet
    func loadTutorDetails(tutorDataFileID: String, dataCounts: DataCounts, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        let tutors = referenceData.tutors
        let tutorCount = dataCounts.totalTutors
        var tutorNum = 0
        while tutorNum < tutorCount {
            var tutorName = tutors.tutorsList[tutorNum].tutorName
            
            let range = tutorName + PgmConstants.tutorCountsRange
            print("Tutor details counts range is '\(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet
                .query(withSpreadsheetId: tutorDataFileID, range:range)
            // Load data counts from ReferenceData spreadsheet
            sheetService.executeQuery(query) { [tutorNum] (ticket, result, error) in
                if let error = error {
                    print(error)
                    print("Failed to read data:\(error.localizedDescription)")
                    return
                }
                guard let result = result as? GTLRSheets_ValueRange else {
                    return
                }
                
                let rows = result.values!
                var stringRows = rows as! [[String]]
                
                for row in stringRows {
                    stringRows.append(row)
                    //               print(row)
                }
                
                if rows.isEmpty {
                    print("No data found.")
                    return
                }
                
  
                let tutorStudentsCount = Int(stringRows[PgmConstants.tutorDataStudentCountRow][PgmConstants.tutorDataStudentCountCol]) ?? 0
                let tutorServicesCount = Int(stringRows[PgmConstants.tutorDataServiceCountRow][PgmConstants.tutorDataServiceCountCol]) ?? 0
                
                print("Tutor \(tutorName) Students: \(stringRows[PgmConstants.tutorDataStudentCountRow][PgmConstants.tutorDataStudentCountCol]) Services: \(stringRows[PgmConstants.tutorDataServiceCountRow][PgmConstants.tutorDataServiceCountCol])")
                
                self.loadTutorStudents(tutorNum: tutorNum, tutorDataFileID: tutorDataFileID, tutorStudentsCount: tutorStudentsCount, referenceData: referenceData, sheetService: sheetService)
                self.loadTutorServices(tutorNum: tutorNum, tutorDataFileID: tutorDataFileID, tutorServicesCount: tutorStudentsCount, referenceData: referenceData, sheetService: sheetService)
            }
            tutorNum += 1
        }
    }
    
    func loadTutorStudents(tutorNum:Int, tutorDataFileID: String, tutorStudentsCount: Int, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        print("Loading \(tutorStudentsCount) Students")
        let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
            
        let range = tutorName + PgmConstants.tutorStudentsRange + String(tutorStudentsCount + PgmConstants.tutorDataStudentsStartingRowNumber)
            print("Tutor details counts range is '\(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet
                .query(withSpreadsheetId: tutorDataFileID, range:range)
            // Load data counts from ReferenceData spreadsheet
            sheetService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print(error)
                    print("Failed to read data:\(error.localizedDescription)")
                    return
                }
                guard let result = result as? GTLRSheets_ValueRange else {
                    return
                }
                
                let rows = result.values!
                var stringRows = rows as! [[String]]
                
                for row in stringRows {
                    stringRows.append(row)
                    //               print(row)
                }
                
                if rows.isEmpty {
                    print("No data found.")
                    return
                }
                
                var rowNum = 0
                var studentNum = 0
                while studentNum < tutorStudentsCount {
                    var studentKey = stringRows[rowNum][PgmConstants.tutorDataStudentNamePosition]
                    var studentName = stringRows[rowNum][PgmConstants.tutorDataStudentNamePosition]
                    var clientName = stringRows[rowNum][PgmConstants.tutorDataStudentClientNamePosition]
                    var clientEmail = stringRows[rowNum][PgmConstants.tutorDataStudentClientEmailPosition]
                    var clientPhone = stringRows[rowNum][PgmConstants.tutorDataStudentClientPhonePosition]
                    
                    var newTutorStudent = TutorStudent(studentKey: studentKey, studentName: studentName, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone)
                    
                    referenceData.tutors.tutorsList[tutorNum].addTutorStudent( newTutorStudent: newTutorStudent)
                    rowNum += 1
                    studentNum += 1
                }
            }
        }
    
    
    func loadTutorServices(tutorNum: Int, tutorDataFileID: String, tutorServicesCount: Int, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        print("Loading \(tutorServicesCount) Students")
        
        
        
    }

    
}
