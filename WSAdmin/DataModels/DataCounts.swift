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
    var activeLocations: Int = 0
    var highestLocationKey: Int = 0
    var isDataCountsLoaded: Bool
    
    init() {
        isDataCountsLoaded = false
    }
    
    func increaseTotalStudentCount() async {
        totalStudents += 1
        activeStudents += 1
        highestStudentKey += 1
        await saveDataCounts()
    }

    func increaseActiveStudentCount() async {
        activeStudents += 1
        await saveDataCounts()
    }

    func decreaseActiveStudentCount() async {
        activeStudents -= 1
        await saveDataCounts()
    }
    
    func increaseTotalTutorCount() async {
        totalTutors += 1
        activeTutors += 1
        highestTutorKey += 1
        await saveDataCounts()
    }

    func increaseActiveTutorCount() async {
        activeTutors += 1
        await saveDataCounts()
    }

    func decreaseActiveTutorCount() async {
        activeTutors -= 1
        await saveDataCounts()
    }
    
    func increaseTotalServiceCount() async {
        totalServices += 1
        activeServices += 1
        highestServiceKey += 1
        await saveDataCounts()
    }

    func increaseActiveServiceCount() async {
        activeServices += 1
        await saveDataCounts()
    }

    func decreaseActiveServiceCount() async {
        activeServices -= 1
        await saveDataCounts()
    }
    
    func increaseTotalLocationCount() async {
        totalLocations += 1
        highestLocationKey += 1
        await saveDataCounts()
    }
    
    func increaseActiveLocationCount() async {
        activeLocations += 1
        await saveDataCounts()
    }

    func decreaseActiveLocationCount() async {
        activeLocations -= 1
        await saveDataCounts()
    }
    
    func fetchDataCounts(referenceData: ReferenceData) async {
        
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Read in the Data Counts from the Reference Data spreadsheet

            do {
                sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.dataCountRange  )
            } catch {
                
            }
            
            if let sheetData = sheetData {
                sheetCells = sheetData.values
            }
// Build the Billed Tutors list for the month from the data read in
            loadDataCountRows(sheetCells: sheetCells)
        }
    
    
    func saveDataCounts() async -> Bool {
        var result: Bool = true
// Write the Data Counts to the Reference Data spreadsheet
        let updateValues = unloadLocationRows()
    
        let range = PgmConstants.dataCountRange
        do {
            result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Data Count rows failed")
           result = false
        }
        
        return(result)
    }
    
    func loadDataCountRows(sheetCells: [[String]] ) {
     
        self.totalStudents = Int(sheetCells[PgmConstants.dataCountTotalStudentsRow][PgmConstants.dataCountTotalStudentsCol]) ?? 0
        self.activeStudents = Int(sheetCells[PgmConstants.dataCountActiveStudentsRow][PgmConstants.dataCountActiveStudentsCol]) ?? 0
        self.highestStudentKey = Int(sheetCells[PgmConstants.dataCountHighestStudentKeyRow][PgmConstants.dataCountHighestStudentKeyCol]) ?? 0
        self.totalTutors = Int(sheetCells[PgmConstants.dataCountTotalTutorsRow][PgmConstants.dataCountTotalTutorsCol]) ?? 0
        self.activeTutors = Int(sheetCells[PgmConstants.dataCountActiveTutorsRow][PgmConstants.dataCountActiveTutorsCol]) ?? 0
        self.highestTutorKey = Int(sheetCells[PgmConstants.dataCountHighestTutorKeyRow][PgmConstants.dataCountHighestTutorKeyCol]) ?? 0
        self.totalServices = Int(sheetCells[PgmConstants.dataCountTotalServicesRow][PgmConstants.dataCountTotalServicesCol]) ?? 0
        self.activeServices = Int(sheetCells[PgmConstants.dataCountActiveServicesRow][PgmConstants.dataCountActiveServicesCol]) ?? 0
        self.highestServiceKey = Int(sheetCells[PgmConstants.dataCountHighestServiceKeyRow][PgmConstants.dataCountHighestServiceKeyCol]) ?? 0
        self.totalLocations = Int(sheetCells[PgmConstants.dataCountTotalLocationsRow][PgmConstants.dataCountTotalLocationsCol]) ?? 0
        self.activeLocations = Int(sheetCells[PgmConstants.dataCountActiveLocationsRow][PgmConstants.dataCountActiveLocationsCol]) ?? 0
        self.highestLocationKey = Int(sheetCells[PgmConstants.dataCountHighestLocationKeyRow][PgmConstants.dataCountHighestLocationKeyCol]) ?? 0
        self.isDataCountsLoaded = true
        self.isDataCountsLoaded = true
    }
    
    func unloadLocationRows() -> [[String]] {
        
        var updateValues = [[String]]()
  
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
        updateValues.insert([String(activeLocations)], at: PgmConstants.dataCountActiveLocationsRow)
        updateValues.insert([String(highestLocationKey)], at: PgmConstants.dataCountHighestLocationKeyRow)
        
        return(updateValues)
    }
    
    
    func loadDataCountsOLD(referenceFileID: String, tutorDataFileID: String, referenceData: ReferenceData) {
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        
        let range = PgmConstants.dataCountRange
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: referenceFileID, range:range)
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
            self.activeLocations = Int(stringRows[PgmConstants.dataCountActiveLocationsRow][PgmConstants.dataCountActiveLocationsCol]) ?? 0
            self.highestLocationKey = Int(stringRows[PgmConstants.dataCountHighestLocationKeyRow][PgmConstants.dataCountHighestLocationKeyCol]) ?? 0
            self.isDataCountsLoaded = true
            referenceData.tutors.loadTutorDataOLD(referenceFileID: referenceFileID, tutorDataFileID: tutorDataFileID, referenceData: referenceData)
            referenceData.students.loadStudentDataOLD(referenceFileID: referenceFileID, referenceData: referenceData)
            referenceData.locations.loadLocationDataOLD(referenceFileID: referenceFileID, referenceData: referenceData)
            referenceData.services.loadServiceDataOLD(referenceFileID: referenceFileID, referenceData: referenceData)
        }
    }
        
    func saveDataCountsOLD() {

        var updateValues: [[String]] = []
        
        let sheetService = GTLRSheetsService()
        
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
        updateValues.insert([String(activeLocations)], at: PgmConstants.dataCountActiveLocationsRow)
        updateValues.insert([String(highestLocationKey)], at: PgmConstants.dataCountHighestLocationKeyRow)

        let valueRange = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
        valueRange.majorDimension = "ROWS" // Indicates horizontal row insert
        valueRange.range = range
        valueRange.values = updateValues
        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: referenceDataFileID, range: range)
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
