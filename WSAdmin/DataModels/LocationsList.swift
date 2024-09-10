//
//  CitiesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

class LocationsList {
    var locationsList = [Location]()
    
    func addLocation(newLocation: Location) {
        locationsList.append(newLocation)
    }
    
    func printAll() {
        for location in locationsList {
            print ("location Name is \(location.locationName)")
        }
    }
    
    func saveLocationData() {
        var referenceFileID: String
        var updateValues: [[String]] = []
        
        var locationKey: String = " "
        var locationName: String = " "
        var locationMonthRevenue: String = " "
        var locationTotalRevenue: String = " "
        
        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
        }
        
        let sheetService = GTLRSheetsService()
        let spreadsheetID = referenceFileID
        let locationCount = locationsList.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
            
        let range = PgmConstants.locationRange + String(locationCount + PgmConstants.locationStartingRowNumber)
        print("Range", range)
  
        var locationNum = 0
        while locationNum < locationCount {
            locationKey = locationsList[locationNum].locationKey
            locationName = locationsList[locationNum].locationName
            locationMonthRevenue = String(locationsList[locationNum].locationMonthRevenue)
            locationTotalRevenue = String(locationsList[locationNum].locationTotalRevenue)
            
            updateValues.insert([locationKey, locationName, locationMonthRevenue, locationTotalRevenue], at: locationNum)
            locationNum += 1
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
                print("locations saved")
            }
        }
    }
    
    
}
