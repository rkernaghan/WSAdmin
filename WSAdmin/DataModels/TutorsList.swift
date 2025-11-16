//
//  TutorsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class TutorsList {
	var tutorsList = [Tutor]()
	var isTutorDataLoaded: Bool
	
	init() {
		isTutorDataLoaded = false
	}
	
	// This function finds a Tutor object in the Tutors List object array by Tutor key
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
	
	// This function finds a Tutor object in the Tutors List object array by Tutor name
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
	
	// This function adds a new Tutor object to the Tutors List object array
	func addTutor(newTutor: Tutor) {
		self.tutorsList.append(newTutor)
	}
	
	// This function reads the Tutor data from the Reference Data spreadsheet into the Tutors List object array.  It does not read in the Tutor's
	// Students or Services.
	func fetchTutorData(tutorCount: Int) async -> Bool {
		var completionFlag: Bool = true
		
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		
		if tutorCount > 0 {
			do {
				// Read the Tutor data from the Reference Data spreadsheet into a 2D array of data (one row per Tutor)
				sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.tutorRange + String(PgmConstants.tutorStartingRowNumber + tutorCount - 1) )
				// Build the Tutors List object array from the cells read into the 2D array
				if let sheetData = sheetData {
					sheetCells = sheetData.values
					completionFlag = await loadTutorRows(tutorCount: tutorCount, sheetCells: sheetCells)
				} else {
					completionFlag = false
				}
			} catch {
				print("Critical Error: Could not read in Tutor data from ReferenceData spreadsheet")
				completionFlag = false
			}
			
		}
		return(completionFlag)
	}
	//
	// This function saves the Tutors List object array data back to the ReferenceData spreadsheet.
	// It returns a success/fail boolean.  There will always be at least one (blank) row.
	//
	func saveTutorData() async -> Bool {
		var result: Bool = true
		// Create a 2D array of Tutor data from the Tutors List object array
		let updateValues = unloadTutorRows()
		// Write the 2D array back to the Reference Data spreadsheet
		let count = updateValues.count
		let range = PgmConstants.tutorRange + String(PgmConstants.tutorStartingRowNumber + updateValues.count - 1)
		do {
			result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
		} catch {
			print ("Critical Error: Saving Tutor Data rows failed")
			result = false
		}
		
		return(result)
	}
	//
	// This function takes a 2 dimensional array of Tutor data, read from the ReferenceData spreadsheet, and
	// populates the Tutors List object array
	//
	func loadTutorRows(tutorCount: Int, sheetCells: [[String]] ) async -> Bool {
		var completionFlag: Bool = true
		
		print("\n** Starting Load Tutor Data **")
		var tutorIndex = 0
		var rowNumber = 0
		// Loop through each row in the 2D Tutor data array.  Each row contains the data for one Tutor
		while tutorIndex < tutorCount && completionFlag {
			
			let newTutorKey = sheetCells[rowNumber][PgmConstants.tutorKeyPosition]
			let newTutorName = sheetCells[rowNumber][PgmConstants.tutorNamePosition]
			let newTutorEmail = sheetCells[rowNumber][PgmConstants.tutorEmailPosition]
			let newTutorPhone = sheetCells[rowNumber][PgmConstants.tutorPhonePosition]
			let newTutorStatus = sheetCells[rowNumber][PgmConstants.tutorStatusPosition]
			let newTutorStartDateString = sheetCells[rowNumber][PgmConstants.tutorStartDatePosition]
			let newTutorEndDateString = sheetCells[rowNumber][PgmConstants.tutorEndDatePosition]
			let newTutorMaxStudents = Int(sheetCells[rowNumber][PgmConstants.tutorMaxStudentPosition]) ?? 0
			let newTutorStudentCount = Int(sheetCells[rowNumber][PgmConstants.tutorStudentCountPosition]) ?? 0
			let newTutorServiceCount = Int(sheetCells[rowNumber][PgmConstants.tutorServiceCountPosition]) ?? 0
			let newTutorTotalSessions = Int(sheetCells[rowNumber][PgmConstants.tutorSessionCountPosition]) ?? 0
			let newTutorCost = Float(sheetCells[rowNumber][PgmConstants.tutorTotalCostPosition]) ?? 0.0
			let newTutorRevenue = Float(sheetCells[rowNumber][PgmConstants.tutorTotalRevenuePosition]) ?? 0.0
			let newTutorProfit = Float(sheetCells[rowNumber][PgmConstants.tutorTotalProfitPosition]) ?? 0.0
			// Create a new Tutor object
			let newTutor = Tutor(tutorKey: newTutorKey, tutorName: newTutorName, tutorEmail: newTutorEmail, tutorPhone: newTutorPhone, tutorStatus: newTutorStatus, tutorStartDate: newTutorStartDateString, tutorEndDate: newTutorEndDateString, tutorMaxStudents: newTutorMaxStudents, tutorStudentCount: newTutorStudentCount, tutorServiceCount: newTutorServiceCount, tutorTotalSessions: newTutorTotalSessions, tutorTotalCost: newTutorCost, tutorTotalRevenue: newTutorRevenue, tutorTotalProfit: newTutorProfit, timesheetFileID: "")
			// Add the new Tutor object to the Tutors List object array
			self.tutorsList.append(newTutor)
			
			// If the Tutor Status is not "Deleted", load in the Tutors Services and Students data
			if newTutorStatus != "Deleted" {
				completionFlag = await self.tutorsList[tutorIndex].loadTutorDetails(tutorNum: tutorIndex, tutorName: newTutorName, tutorDataFileID: tutorDetailsFileID)
			}
			print("Loaded Tutor \(newTutorName)")
			
			tutorIndex += 1
			rowNumber += 1
		}
		print("** Loaded Base Tutor Data for \(tutorIndex) Tutors - Tutor Loading Complete **\n")
		self.isTutorDataLoaded = true
		
		return(completionFlag)
	}
	//
	// This function takes the attributes for each Tutor object in the Tutors List object array and copies them to a 2 dimensional array, which it returns,
	// for saving to the ReferenceData spreadsheet
	//
	func unloadTutorRows() -> [[String]] {
		
		var updateValues = [[String]]()
		// Loop through each Tutor copying the attributes to a 2D array
		var tutorNum = 0
		let tutorCount = self.tutorsList.count
		while tutorNum < tutorCount {
			let tutorKey = tutorsList[tutorNum].tutorKey
			let tutorName = tutorsList[tutorNum].tutorName
			let tutorPhone = tutorsList[tutorNum].tutorPhone
			let tutorEmail = tutorsList[tutorNum].tutorEmail
			let tutorStatus = tutorsList[tutorNum].tutorStatus
			let tutorStartDate = tutorsList[tutorNum].tutorStartDate
			let tutorEndDate = tutorsList[tutorNum].tutorEndDate
			let tutorMaxStudents = String(tutorsList[tutorNum].tutorMaxStudents)
			let tutorTotalStudents = String(tutorsList[tutorNum].tutorStudentCount)
			let tutorTotalServices = String(tutorsList[tutorNum].tutorServiceCount)
			let tutorTotalSessions = String(tutorsList[tutorNum].tutorTotalSessions)
			let tutorTotalCost = String(tutorsList[tutorNum].tutorTotalCost.formatted(.number.precision(.fractionLength(2))))
			let tutorTotalRevenue = String(tutorsList[tutorNum].tutorTotalRevenue.formatted(.number.precision(.fractionLength(2))))
			let tutorTotalProfit = String(tutorsList[tutorNum].tutorTotalProfit.formatted(.number.precision(.fractionLength(2))))
			// Add a new row to the 2D array containing the Tutor object attributes
			updateValues.insert([tutorKey, tutorName, tutorEmail, tutorPhone, tutorStatus, tutorStartDate, tutorEndDate, tutorMaxStudents, tutorTotalStudents, tutorTotalServices, tutorTotalSessions, tutorTotalCost, tutorTotalRevenue, tutorTotalProfit], at: tutorNum)
			tutorNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " "," ", " ", " ", " "," ", " ", " ", " "," ", " "], at: tutorNum)
		
		return( updateValues)
	}

}


