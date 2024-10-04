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
    var isTutorDataLoaded: Bool
    
    init() {
        isTutorDataLoaded = false
    }
    
    func loadTutor(newTutor: Tutor) {
        self.tutorsList.append(newTutor)
    }
    
    func printAll() {
        for tutor in tutorsList {
            print ("Tutor Name is \(tutor.tutorName)")
        }
    }
    
    func findTutorByKey(tutorKey: String) -> (Bool, Int) {
        var found = false
        
        var tutorNum = 0
        while tutorNum < tutorsList.count && !found {
            if tutorsList[tutorNum].tutorKey == tutorKey {
                found = true
            } else {
                tutorNum += 1
            }
        }
        return(found, tutorNum)
    }
    
    func findTutorByName(tutorName: String) -> (Bool, Int) {
        var found = false
        
        var tutorNum = 0
        while tutorNum < tutorsList.count && !found {
            if tutorsList[tutorNum].tutorName == tutorName {
                found = true
            } else {
                tutorNum += 1
            }
        }
        return(found, tutorNum)
    }
    
    func loadTutorData(referenceFileID: String, tutorDataFileID: String, referenceData: ReferenceData) {
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer

        let range = PgmConstants.tutorRange + String(referenceData.dataCounts.totalTutors + PgmConstants.tutorStartingRowNumber - 1)
//    print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: referenceFileID, range:range)
// Load Tutors from ReferenceData spreadsheet
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
        
// Load the Tutors
//            referenceData.tutorsList.removeAll()          // empty the array before loading as this could be a refresh
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var tutorIndex = 0
            var rowNumber = 0
            while tutorIndex < referenceData.dataCounts.totalTutors {
                
                let newTutorKey = stringRows[rowNumber][PgmConstants.tutorKeyPosition]
                let newTutorName = stringRows[rowNumber][PgmConstants.tutorNamePosition]
                let newTutorEmail = stringRows[rowNumber][PgmConstants.tutorEmailPosition]
                let newTutorPhone = stringRows[rowNumber][PgmConstants.tutorPhonePosition]
                let newTutorStatus = stringRows[rowNumber][PgmConstants.tutorStatusPosition]
                let newTutorStartDateString = stringRows[rowNumber][PgmConstants.tutorStartDatePosition]
//                let newTutorStartDate = dateFormatter.date(from: newTutorStartDateString)
                let newTutorEndDateString = stringRows[rowNumber][PgmConstants.tutorEndDatePosition]
//                var newTutorEndDate: Date? = dateFormatter.date(from: newTutorEndDateString)
//                if var newTutorEndDate = newTutorEndDate {} else {
//                    newTutorEndDate = nil
//                }
                let newTutorMaxStudents = Int(stringRows[rowNumber][PgmConstants.tutorMaxStudentPosition]) ?? 0
                let newTutorStudentCount = Int(stringRows[rowNumber][PgmConstants.tutorStudentCountPosition]) ?? 0
                let newTutorServiceCount = Int(stringRows[rowNumber][PgmConstants.tutorServiceCountPosition]) ?? 0
                let newTutorTotalSessions = Int(stringRows[rowNumber][PgmConstants.tutorSessionCountPosition]) ?? 0
                let newTutorCost = Float(stringRows[rowNumber][PgmConstants.tutorTotalCostPosition]) ?? 0.0
                let newTutorRevenue = Float(stringRows[rowNumber][PgmConstants.tutorTotalRevenuePosition]) ?? 0.0
                let newTutorProfit = Float(stringRows[rowNumber][PgmConstants.tutorTotalProfitPosition]) ?? 0.0
                
                let newTutor = Tutor(tutorKey: newTutorKey, tutorName: newTutorName, tutorEmail: newTutorEmail, tutorPhone: newTutorPhone, tutorStatus: newTutorStatus, tutorStartDate: newTutorStartDateString, tutorEndDate: newTutorEndDateString, tutorMaxStudents: newTutorMaxStudents, tutorStudentCount: newTutorStudentCount, tutorServiceCount: newTutorServiceCount, tutorTotalSessions: newTutorTotalSessions, tutorTotalCost: newTutorCost, tutorTotalRevenue: newTutorRevenue, tutorTotalProfit: newTutorProfit)
                self.tutorsList.append(newTutor)
                
                if newTutorStatus != "Deleted" {
                    self.tutorsList[tutorIndex].loadTutorDetails(tutorNum: tutorIndex, tutorDataFileID: tutorDataFileID, referenceData: referenceData)
                }
                
                tutorIndex += 1
                rowNumber += 1
            }
 //           referenceData.tutors.printAll()
            self.isTutorDataLoaded = true

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
        var tutorStatus: String = " "
        var tutorStartDate: String = " "
        var tutorEndDate: String = " "
        var tutorMaxStudents: String = " "
        var tutorTotalStudents: String = " "
        var tutorTotalServices: String = " "
        var tutorTotalSessions: String = " "
        var tutorTotalCost: String = " "
        var tutorTotalRevenue: String = " "
        var tutorTotalProfit: String = " "
        
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

        let range = PgmConstants.tutorRange + String(tutorCount + PgmConstants.tutorStartingRowNumber + 1)              //One extra row for blanking line at end
        print("Tutor Data Save Range", range)
  
        var tutorNum = 0
        while tutorNum < tutorCount {
            tutorKey = tutorsList[tutorNum].tutorKey
            tutorName = tutorsList[tutorNum].tutorName
            tutorPhone = tutorsList[tutorNum].tutorPhone
            tutorEmail = tutorsList[tutorNum].tutorEmail
            tutorStatus = tutorsList[tutorNum].tutorStatus
            tutorStartDate = tutorsList[tutorNum].tutorStartDate
            tutorEndDate = tutorsList[tutorNum].tutorEndDate
            tutorMaxStudents = String(tutorsList[tutorNum].tutorMaxStudents)
            tutorTotalStudents = String(tutorsList[tutorNum].tutorStudentCount)
            tutorTotalServices = String(tutorsList[tutorNum].tutorServiceCount)
            tutorTotalSessions = String(tutorsList[tutorNum].tutorTotalSessions)
            tutorTotalCost = String(tutorsList[tutorNum].tutorTotalCost.formatted(.number.precision(.fractionLength(2))))
            tutorTotalRevenue = String(tutorsList[tutorNum].tutorTotalRevenue.formatted(.number.precision(.fractionLength(2))))
            tutorTotalProfit = String(tutorsList[tutorNum].tutorTotalProfit.formatted(.number.precision(.fractionLength(2))))
            
            updateValues.insert([tutorKey, tutorName, tutorEmail, tutorPhone, tutorStatus, tutorStartDate, tutorEndDate, tutorMaxStudents, tutorTotalStudents, tutorTotalServices, tutorTotalSessions, tutorTotalCost, tutorTotalRevenue, tutorTotalProfit], at: tutorNum)
            tutorNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " "], at: tutorNum)
        
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
