//
//  CitiesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import GoogleSignIn


@Observable class LocationsList: Identifiable {
	var locationsList = [Location]()
	var isLocationDataLoaded: Bool
	var id = UUID()
	
	init() {
		isLocationDataLoaded = false
	}
	
	// This function finds a Location object in the Locations List object array by Location key
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
	
	// This function finds a Location object in the Locations List object array by Location name
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
	
	// This function adds a new Location object to the Locations List object array
	func addLocation(newLocation: Location) {
		self.locationsList.append(newLocation)
	}
	
	// This function reads the Location data from the Reference Data spreadsheet and builds the Locations List object array
	func fetchLocationData(locationCount: Int) async -> Bool {
		var completionFlag: Bool = true
		
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		
		// Read the Location data into a 2D array from the Reference Data spreadsheet
		if locationCount > 0 {
			do {
				sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.locationRange + String(PgmConstants.locationStartingRowNumber + locationCount - 1) )
				// Build the Locations List object array from the cells read into the 2D array
				if let sheetData = sheetData {
					sheetCells = sheetData.values
					loadLocationRows(locationCount: locationCount, sheetCells: sheetCells)
				} else {
					completionFlag = false
				}
			} catch {
				print("ERROR: could not read Locations data")
				completionFlag = false
			}
			
		}
		return(completionFlag)
	}
	
	// This function saves the Location objects in the Locations List object array back to the Reference Data spreadsheet
	func saveLocationData() async -> Bool {
		var completionFlag: Bool = true
		// Build a 2D array of Location data for writing to the Reference Data spreadsheet
		let updateValues = unloadLocationRows()
		let count = updateValues.count
		let range = PgmConstants.locationRange + String(PgmConstants.locationStartingRowNumber + updateValues.count - 1)
		do {
			// Write the 2D array of Location data to the Reference Data spreadsheet
			let result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
			if !result {
				completionFlag = false
				print("Error: saving Location data rows failed")
			}
		} catch {
			print ("Error: Saving Location Data rows failed")
			completionFlag = false
		}
		
		return(completionFlag)
	}
	
	// This function takes a 2D array of Location attributes (one row per Location) and builds the Locations List object array
	func loadLocationRows(locationCount: Int, sheetCells: [[String]] ) {
		
		var locationIndex = 0
		var rowNumber = 0
		let locationsCount = sheetCells.count
		// Loop through each row of the 2D array pulling out the Location attributes
		while rowNumber < locationsCount {
			
			let newLocationKey = sheetCells[rowNumber][PgmConstants.locationKeyPosition]
			let newLocationName = sheetCells[rowNumber][PgmConstants.locationNamePosition]
			let newLocationMonthRevenue = Float(sheetCells[rowNumber][PgmConstants.locationMonthRevenuePosition]) ?? 0.0
			let newLocationTotalRevenue = Float(sheetCells[rowNumber][PgmConstants.locationTotalRevenuePosition]) ?? 0.0
			let newLocationStudentCount = Int(sheetCells[rowNumber][PgmConstants.locationStudentCountPosition]) ?? 0
			let newLocationStatus = sheetCells[rowNumber][PgmConstants.locationStatusPosition]
			// Create a new Location object from the extracted Location attributes
			let newLocation = Location(locationKey: newLocationKey, locationName: newLocationName, locationMonthRevenue: newLocationMonthRevenue, locationTotalRevenue: newLocationTotalRevenue, locationStudentCount: newLocationStudentCount, locationStatus: newLocationStatus)
			// Add the new Location object to the Locations List object array
			self.locationsList.append(newLocation)
			
			locationIndex += 1
			rowNumber += 1
		}

		self.isLocationDataLoaded = true
	}
	
	// This function extracts the Location attributes from the Locations List object array and builds a 2D array (one row per Location) for writing to the Reference Data spreadsheet
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
			
			// Add another row to the 2D Location Data array
			updateValues.insert([locationKey, locationName, locationMonthRevenue, locationTotalRevenue, locationStudentCount, locationStatus], at: locationNum)
			locationNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " "], at: locationNum)
		
		return(updateValues)
	}
	
}
