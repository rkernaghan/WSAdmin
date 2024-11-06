//
//  DataCounts.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-10.
//

import Foundation

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
	
	func increaseTotalStudentCount() {
		totalStudents += 1
		activeStudents += 1
		highestStudentKey += 1
	}

	func increaseActiveStudentCount() {
		activeStudents += 1
	}
	
	func decreaseActiveStudentCount() {
		activeStudents -= 1
	}
	
	func increaseTotalTutorCount() {
		totalTutors += 1
		activeTutors += 1
		highestTutorKey += 1
	}
	
	func increaseActiveTutorCount() {
		activeTutors += 1
	}
	
	func decreaseActiveTutorCount() {
		activeTutors -= 1
	}
	
	func increaseTotalServiceCount() {
		totalServices += 1
		activeServices += 1
		highestServiceKey += 1
	}
	
	func increaseActiveServiceCount() {
		activeServices += 1
	}
	
	func decreaseActiveServiceCount() {
		activeServices -= 1
	}
	
	func increaseTotalLocationCount() {
		totalLocations += 1
		highestLocationKey += 1
	}

	func increaseActiveLocationCount() {
		activeLocations += 1
	}
	
	func decreaseActiveLocationCount() {
		activeLocations -= 1
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
		if sheetCells.count > 0 {
			loadDataCountRows(sheetCells: sheetCells)
		} else {
			print("Error: could not read Data Counts")
		}
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
    
}
