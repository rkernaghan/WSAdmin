//
//  TutorMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST


@Observable class TutorMgmtVM  {
    
    
    func addNewTutor(referenceData: ReferenceData, tutorName: String, contactEmail: String, contactPhone: String, maxStudents: String) {
        
        
        let newTutorKey = PgmConstants.tutorKeyPrefix + "0034"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: Date())
        let maxStudentsInt = Int(maxStudents) ?? 0
        
        let newTutor = Tutor(tutorKey: newTutorKey, tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorStatus: "New", tutorStartDate: startDate, tutorEndDate: " ", tutorMaxStudents: maxStudentsInt, tutorStudentCount: 0, tutorServiceCount: 0, tutorTotalSessions: 0, tutorTotalCost: 0.0, tutorTotalRevenue: 0.0, tutorTotalProfit: 0.0)
        referenceData.tutors.addTutor(newTutor: newTutor)
        referenceData.tutors.saveTutorData()
        referenceData.dataCounts.increaseTutorCount()
        referenceData.dataCounts.saveDataCounts()
        
        createNewSheet(tutorName: tutorName)
    }
    
    func listTutorStudents(indexes: Set<Service.ID>, referenceData: ReferenceData) {
        for objectID in indexes {
            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                print("Student Name \(referenceData.tutors.tutorsList[idx].tutorStudents[0].studentName)")
            }
        }
    }
            
    func deleteTutor(indexes: Set<Service.ID>, referenceData: ReferenceData) {
        print("deleting Tutor")
        
        for objectID in indexes {
            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                referenceData.tutors.tutorsList.remove(at: idx)
            }
        }
        referenceData.tutors.saveTutorData()
    }
    
    
    func createNewTimesheet(tutorName: String, completionHandler: @escaping (String) -> Void) {
        print("Creating New Sheet ...\n")
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        let newSheet = GTLRSheets_Spreadsheet.init()
        let properties = GTLRSheets_SpreadsheetProperties.init()
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("YYYY")
        let currentYear = formatter.string(from: Date.now)
        properties.title = "Timesheet " + currentYear + " " + tutorName
        newSheet.properties = properties
        
        let query = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject:newSheet)
        query.fields = "spreadsheetId"
        
        sheetService.executeQuery(query) { (ticket, result, error) in
            // let sheet = result as? GTLRSheets_Spreadsheet
            if let error = error {
                completionHandler("Error:\n\(error.localizedDescription)")
                print("Error in creating the Sheet: \(error)")
                return
            }
            else {
                let response = result as! GTLRSheets_Spreadsheet
                let identifier = response.spreadsheetId
                print("Spreadsheet id: \(String(describing: identifier))")
                
                print("Success!")
            }
        }
    }
    
    func createNewSheet(tutorName: String) {
        
        var spreadsheetID: String
        
        let batchUpdate = GTLRSheets_BatchUpdateSpreadsheetRequest.init()
        let request = GTLRSheets_Request.init()
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        let properties = GTLRSheets_SheetProperties.init()
        properties.title = tutorName
        
        let sheetRequest = GTLRSheets_AddSheetRequest.init()
        sheetRequest.properties = properties
        
        request.addSheet = sheetRequest
        
        batchUpdate.requests = [request]
        
        if runMode == "PROD" {
            spreadsheetID = PgmConstants.prodTutorDataFileID
        } else {
            spreadsheetID = PgmConstants.testTutorDataFileID
        }
        
        let createQuery = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batchUpdate, spreadsheetId: spreadsheetID)
        
        sheetService.executeQuery(createQuery) { (ticket, result, err) in
            if let error = err {
                print(error)
                print("Error with creating sheet:\(error.localizedDescription)")
            } else {
                print("Success!")
                //newSheet.sheetId =
                print("Sheet added!")
            }
        }
    }
    
    func copyDriveFile(sourceFileID: String, newFileName: String) {
        print("Copying sheet")
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
// Retreive all files with Tutor timesheet name (should only be one)
        driveService.executeQuery(dquery, completionHandler: {(ticket, files, error) in
            if let error = error {
                print(error)
                print("Error with creating sheet:\(error)")
                return
            } else {
                print("Success!")
                //newSheet.sheetId =
                print("Sheet added!")
                let newFileID = " "
                return()
            }
        })
    }
    
    func printTutor(indexes: Set<Service.ID>, referenceData: ReferenceData) {
        print("Printing Tutor")
        
        for objectID in indexes {
            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                print("Tutor Name: \(referenceData.tutors.tutorsList[idx].tutorName)")
                print("Tutor Student Count: \(referenceData.tutors.tutorsList[idx].tutorStudentCount)")
                var studentNum = 0
                while studentNum < referenceData.tutors.tutorsList[idx].tutorStudentCount {
                    print("Tutor Student: \(referenceData.tutors.tutorsList[idx].tutorStudents[studentNum].studentName)")
                    studentNum += 1
                }
                print("Tutor Service Count: \(referenceData.tutors.tutorsList[idx].tutorServiceCount)")
                var serviceNum = 0
                while serviceNum < referenceData.tutors.tutorsList[idx].tutorServiceCount {
                    print("Tutor Service: \(referenceData.tutors.tutorsList[idx].tutorServices[serviceNum].timesheetServiceName)")
                    serviceNum += 1
                }
            }
        }
        referenceData.tutors.saveTutorData()
    }
    
}
