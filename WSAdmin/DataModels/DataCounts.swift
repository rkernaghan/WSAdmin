//
//  DataCounts.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-10.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

class DataCounts {
    var totalStudents: Int = 0
    var activeStudents: Int = 0
    var highestStudentKey: Int = 0
    var totalTutors: Int = 0
    var activeTutors: Int = 0
    var highestTutorKey: Int = 0
    var totalServices: Int = 0
    var activeServices: Int = 0
    var highestServiceKey: Int = 0
    var totalLocations: Int = 0
    var highestLocationKey: Int = 0
    var isDataCountsLoaded: Bool
    
    init() {
        isDataCountsLoaded = false
    }
    
    func increaseTotalStudentCount() {
        totalStudents += 1
        activeStudents += 1
        highestStudentKey += 1
        saveDataCounts()
    }

    func increaseActiveStudentCount() {
        activeStudents += 1
        saveDataCounts()
    }

    func decreaseActiveStudentCount() {
        activeStudents -= 1
        saveDataCounts()
    }
    
    func increaseTotalTutorCount() {
        totalTutors += 1
        activeTutors += 1
        highestTutorKey += 1
        saveDataCounts()
    }

    func increaseActiveTutorCount() {
        activeTutors += 1
        saveDataCounts()
    }

    func decreaseActiveTutorCount() {
        activeTutors -= 1
        saveDataCounts()
    }
    
    func increaseTotalServiceCount() {
        totalServices += 1
        activeServices += 1
        highestServiceKey += 1
        saveDataCounts()
    }

    func increaseActiveServiceCount() {
        activeServices += 1
        saveDataCounts()
    }

    func decreaseActiveServiceCount() {
        activeServices -= 1
        saveDataCounts()
    }
    
    func increaseLocationCount() {
        totalLocations += 1
        highestLocationKey += 1
        saveDataCounts()
    }
    
    func loadDataCounts(referenceFileID: String, tutorDataFileID: String, referenceData: ReferenceData) {
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        
        let range = PgmConstants.dataCountRange
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: referenceFileID, range:range)
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
            
            print("Total Student count is \(rows[0][0])")
            print("Active Student count is \(rows[1][0])")
            print("Highest Student Key is \(rows[2][0])")
            print("Number of rows in sheet: \(rows.count)")
            self.totalStudents = Int(stringRows[PgmConstants.dataCountTotalStudentsRow][PgmConstants.dataCountTotalStudentsCol]) ?? 0
            self.activeStudents = Int(stringRows[PgmConstants.dataCountActiveStudentsRow][PgmConstants.dataCountActiveStudentsCol]) ?? 0
            self.highestStudentKey = Int(stringRows[PgmConstants.dataCountHighestStudentKeyRow][PgmConstants.dataCountHighestStudentKeyCol]) ?? 0
            self.totalTutors = Int(stringRows[PgmConstants.dataCountTotalTutorsRow][PgmConstants.dataCountTotalTutorsCol]) ?? 0
            self.activeTutors = Int(stringRows[PgmConstants.dataCountActiveTutorsRow][PgmConstants.dataCountActiveTutorsCol]) ?? 0
            self.highestTutorKey = Int(stringRows[PgmConstants.dataCountHighestTutorKeyRow][PgmConstants.dataCountHighestTutorKeyCol]) ?? 0
            self.totalServices = Int(stringRows[PgmConstants.dataCountTotalServicesRow][PgmConstants.dataCountTotalServicesCol]) ?? 0
            self.activeServices = Int(stringRows[PgmConstants.dataCountActiveServicesRow][PgmConstants.dataCountActiveServicesCol]) ?? 0
            self.highestServiceKey = Int(stringRows[PgmConstants.dataCountHighestServiceKeyRow][PgmConstants.dataCountHighestServiceKeyCol]) ?? 0
            self.totalLocations = Int(stringRows[PgmConstants.dataCountTotalLocationsRow][PgmConstants.dataCountTotalLocationsCol]) ?? 0
            self.highestLocationKey = Int(stringRows[PgmConstants.dataCountHighestLocationKeyRow][PgmConstants.dataCountHighestLocationKeyCol]) ?? 0
            self.isDataCountsLoaded = true
            referenceData.tutors.loadTutorData(referenceFileID: referenceFileID, tutorDataFileID: tutorDataFileID, referenceData: referenceData)
            referenceData.students.loadStudentData(referenceFileID: referenceFileID, referenceData: referenceData)
            referenceData.locations.loadLocationData(referenceFileID: referenceFileID, referenceData: referenceData)
            referenceData.services.loadServiceData(referenceFileID: referenceFileID, referenceData: referenceData)
        }
    }
        
    func saveDataCounts() {
        var referenceFileID: String
        var updateValues: [[String]] = []
        
        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
        }
        
        let sheetService = GTLRSheetsService()
        let spreadsheetID = referenceFileID
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
            
        let range = PgmConstants.dataCountRange
        print("Data Counts Range", range)
  
        updateValues.insert([String(totalStudents)], at: PgmConstants.dataCountTotalStudentsRow)
        updateValues.insert([String(activeStudents)], at: PgmConstants.dataCountActiveStudentsRow)
        updateValues.insert([String(highestStudentKey)], at: PgmConstants.dataCountHighestStudentKeyRow)
        updateValues.insert([String(totalTutors)], at: PgmConstants.dataCountTotalTutorsRow)
        updateValues.insert([String(activeTutors)], at: PgmConstants.dataCountActiveTutorsRow)
        updateValues.insert([String(highestTutorKey)], at: PgmConstants.dataCountHighestTutorKeyRow)
        updateValues.insert([String(totalServices)], at: PgmConstants.dataCountTotalServicesRow)
        updateValues.insert([String(activeServices)], at: PgmConstants.dataCountActiveServicesRow)
        updateValues.insert([String(highestServiceKey)], at: PgmConstants.dataCountHighestServiceKeyRow)
        updateValues.insert([String(totalLocations)], at: PgmConstants.dataCountTotalLocationsRow)
        updateValues.insert([String(highestLocationKey)], at: PgmConstants.dataCountHighestLocationKeyRow)

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
                print("Data Counts saved")
            }
        }
    }
    
}
