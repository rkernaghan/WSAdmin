//
//  CitiesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class LocationsList: Identifiable {
    var locationsList = [Location]()
    var isLocationDataLoaded: Bool
    var id = UUID()
    
    init() {
        isLocationDataLoaded = false
    }
    
    func findLocationByKey(locationKey: String) -> (Bool, Int) {
        var found = false
        
        var locationNum = 0
        while locationNum < locationsList.count && !found {
            if locationsList[locationNum].locationKey == locationKey {
                found = true
            } else {
                locationNum += 1
            }
        }
        return(found, locationNum)
    }

    func findLocationByName(locationName: String) -> (Bool, Int) {
        var found = false
        
        var locationNum = 0
        while locationNum < locationsList.count && !found {
            if locationsList[locationNum].locationName == locationName {
                found = true
            } else {
                locationNum += 1
            }
        }
        return(found, locationNum)
    }
    
    func loadLocation(newLocation: Location) {
        self.locationsList.append(newLocation)

    }
    
    func printAll() {
        for location in locationsList {
            print ("location Name is \(location.locationName)")
        }
    }
    
    func loadLocationDataOLD(referenceFileID: String, referenceData: ReferenceData) {
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer

        let range = PgmConstants.locationRange + String(referenceData.dataCounts.totalLocations + PgmConstants.locationStartingRowNumber - 1)
//        print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: referenceFileID, range:range)
// Load Cities from ReferenceData spreadsheet
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
            
// Load the Locations
//           referenceData.citiesList.removeAll()          // empty the array before loading as this could be a refresh
            
            var locationIndex = 0
            var rowNumber = 0
            while locationIndex < referenceData.dataCounts.totalLocations {
                
                let newLocationKey = stringRows[rowNumber][PgmConstants.locationKeyPosition]
                let newLocationName = stringRows[rowNumber][PgmConstants.locationNamePosition]
                let newLocationMonthRevenue = Float(stringRows[rowNumber][PgmConstants.locationMonthRevenuePosition]) ?? 0.0
                let newLocationTotalRevenue = Float(stringRows[rowNumber][PgmConstants.locationTotalRevenuePosition]) ?? 0.0
                let newLocationStudentCount = Int(stringRows[rowNumber][PgmConstants.locationStudentCountPosition]) ?? 0
                let newLocationStatus = stringRows[rowNumber][PgmConstants.locationStatusPosition]
                let newLocation = Location(locationKey: newLocationKey, locationName: newLocationName, locationMonthRevenue: newLocationMonthRevenue, locationTotalRevenue: newLocationTotalRevenue, locationStudentCount: newLocationStudentCount, locationStatus: newLocationStatus)
                
                self.locationsList.append(newLocation)
                
                locationIndex += 1
                rowNumber += 1
            }
  //          referenceData.cities.printAll()
            self.isLocationDataLoaded = true
        }
    }
    
 
    
    func saveLocationDataOLD() {

        var updateValues: [[String]] = []
        
        var locationKey: String = " "
        var locationName: String = " "
        var locationMonthRevenue: String = " "
        var locationTotalRevenue: String = " "
        var locationStudentCount: String = " "
        var locationStatus: String = " "
        
        let sheetService = GTLRSheetsService()
        let locationCount = locationsList.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
            
        let range = PgmConstants.locationRange + String(locationCount + PgmConstants.locationStartingRowNumber + 1)     // One extra row for blanking row at end
        print("Location Data Save Range", range)
  
        var locationNum = 0
        while locationNum < locationCount {
            locationKey = locationsList[locationNum].locationKey
            locationName = locationsList[locationNum].locationName
            locationMonthRevenue = String(locationsList[locationNum].locationMonthRevenue)
            locationTotalRevenue = String(locationsList[locationNum].locationTotalRevenue)
            locationStudentCount = String(locationsList[locationNum].locationStudentCount)
            locationStatus = locationsList[locationNum].locationStatus
            
            updateValues.insert([locationKey, locationName, locationMonthRevenue, locationTotalRevenue, locationStudentCount, locationStatus], at: locationNum)
            locationNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " "], at: locationNum)
        
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
                print("locations saved")
            }
        }
    }
    
    func fetchLocationData(locationCount: Int) async {
 
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Read in the Billed Tutors from the Billed Tutor spreadsheet
        if locationCount > 0 {
            do {
                sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.locationRange + String(PgmConstants.locationStartingRowNumber + locationCount - 1) )
            } catch {
                
            }
            
            if let sheetData = sheetData {
                sheetCells = sheetData.values
            }
// Build the Locations list from the cells read in
            loadLocationRows(locationCount: locationCount, sheetCells: sheetCells)
        }
    }
    
    func saveLocationData() async -> Bool {
        var result: Bool = true
// Write the Location rows to the Reference Data spreadsheet
        let updateValues = unloadLocationRows()
        let count = updateValues.count
        let range = PgmConstants.locationRange + String(PgmConstants.tutorBillingStartRow + updateValues.count - 1)
        do {
            result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Location Data rows failed")
           result = false
        }
        
        return(result)
    }
    
    func loadLocationRows(locationCount: Int, sheetCells: [[String]] ) {
     
        var locationIndex = 0
        var rowNumber = 0
        let locationsCount = sheetCells.count
        while rowNumber < locationsCount {
            
            let newLocationKey = sheetCells[rowNumber][PgmConstants.locationKeyPosition]
            let newLocationName = sheetCells[rowNumber][PgmConstants.locationNamePosition]
            let newLocationMonthRevenue = Float(sheetCells[rowNumber][PgmConstants.locationMonthRevenuePosition]) ?? 0.0
            let newLocationTotalRevenue = Float(sheetCells[rowNumber][PgmConstants.locationTotalRevenuePosition]) ?? 0.0
            let newLocationStudentCount = Int(sheetCells[rowNumber][PgmConstants.locationStudentCountPosition]) ?? 0
            let newLocationStatus = sheetCells[rowNumber][PgmConstants.locationStatusPosition]
            let newLocation = Location(locationKey: newLocationKey, locationName: newLocationName, locationMonthRevenue: newLocationMonthRevenue, locationTotalRevenue: newLocationTotalRevenue, locationStudentCount: newLocationStudentCount, locationStatus: newLocationStatus)
            
            self.locationsList.append(newLocation)
            
            locationIndex += 1
            rowNumber += 1
        }
//          referenceData.cities.printAll()
        self.isLocationDataLoaded = true
    }
    
    func unloadLocationRows() -> [[String]] {
        
        var updateValues = [[String]]()
        
        var locationNum = 0
        let locationCount = self.locationsList.count
        while locationNum < locationCount {
            let locationKey = locationsList[locationNum].locationKey
            let locationName = locationsList[locationNum].locationName
            let locationMonthRevenue = String(locationsList[locationNum].locationMonthRevenue)
            let locationTotalRevenue = String(locationsList[locationNum].locationTotalRevenue)
            let locationStudentCount = String(locationsList[locationNum].locationStudentCount)
            let locationStatus = locationsList[locationNum].locationStatus
            
            updateValues.insert([locationKey, locationName, locationMonthRevenue, locationTotalRevenue, locationStudentCount, locationStatus], at: locationNum)
            locationNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " "], at: locationNum)
        
        return(updateValues)
    }
}
