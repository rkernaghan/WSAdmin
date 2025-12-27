//
//  StudentsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class StudentsList {
	var studentsList = [Student]()
	var isStudentDataLoaded: Bool
	
	init() {
		isStudentDataLoaded = false
	}
	
	// This function finds a Student object in the Students List object array by Student key
	func findStudentByKey(studentKey: String) -> (Bool, Int) {
		var found = false
		
		var studentNum = 0
		while studentNum < studentsList.count && !found {
			if studentsList[studentNum].studentKey == studentKey {
				found = true
			} else {
				studentNum += 1
			}
		}
		return(found, studentNum)
	}
	
	// This function finds a Student object in the Students List object array by Student name
	func findStudentByName(studentName: String) -> (Bool, Int) {
		var found = false
		
		var studentNum = 0
		while studentNum < studentsList.count && !found {
			if studentsList[studentNum].studentName == studentName {
				found = true
			} else {
				studentNum += 1
			}
		}
		return(found, studentNum)
	}
	
	// This function creates a new Student object and adds it to the Students List object array.
	func addNewStudent(studentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String,  contactZipCode: String, location: String, referenceData: ReferenceData) {
		
		let newStudentKey = PgmConstants.studentKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestStudentKey + 1)
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		let startDate = dateFormatter.string(from: Date())
		// Create new Student object
		let newStudent = Student(studentKey: newStudentKey, studentName: studentName, studentContactFirstName: contactFirstName, studentContactLastName: contactLastName, studentContactPhone: contactPhone, studentContactEmail: contactEmail, studentContactZipCode: contactZipCode, studentStartDate: startDate, studentAssignedUnassignedDate: " ", studentLastBilledDate: " ", studentEndDate: " ", studentStatus: "Unassigned", studentTutorKey: " ", studentTutorName: " ", studentLocation: location, studentSessions: 0, studentTotalCost: 0.0, studentTotalRevenue: 0.0, studentTotalProfit: 0.0)
		// Add new Student object to Students List object array
		self.studentsList.append(newStudent)
		//Sort Student list alphabetically
		self.studentsList.sort { $0.studentName < $1.studentName }
	}
    
	// This function reads all the Students into a temporary 2D array from the Reference Data spreadsheet.  It then processes the 2D array and populates
	// the Students List object array
	func fetchStudentData(studentCount: Int) async -> Bool {
		var completionFlag: Bool = true
		
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		
		if studentCount > 0 {
			do {
				// Read in the Student data from the Reference Data spreadsheet to a temporary 2D array
				sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.studentRange + String(PgmConstants.studentStartingRowNumber + studentCount - 1) )
				// Build the Students List object array from the cells read into the 2D array
				if let sheetData = sheetData {
					sheetCells = sheetData.values
					loadStudentRows(studentCount: studentCount, sheetCells: sheetCells)
					//Sort Student list alphabetically
					self.studentsList.sort { $0.studentName < $1.studentName }
				} else {
					completionFlag = false
				}
			} catch {
				completionFlag = false
				print("Error: could not read Student Data from ReferenceData spreadsheet")
			}
		}
		return(completionFlag)
	}
	
	// This function saves the Students List object data back to the Reference Data spreadsheet.
	func saveStudentData() async -> Bool {
		var completionFlag: Bool = true
		// Put the Students List object array into a temporary 2D array (one row per Student)
		let updateValues = unloadStudentRows()
		let count = updateValues.count
		let range = PgmConstants.studentRange + String(PgmConstants.studentStartingRowNumber + count - 1)
		do {
			// Write the 2D array of Student data to the Reference Data spreadsheet
			let result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
			if !result {
				completionFlag = false
			}
		} catch {
			print ("Error: Saving Student Data rows failed")
			completionFlag = false
		}
		
		return(completionFlag)
	}
	
	// This function takes a 2D array of all Student data and populates the Students List object array
	func loadStudentRows(studentCount: Int, sheetCells: [[String]] ) {
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		
		var studentIndex = 0
		var rowNumber = 0
		// Loop through each row in the array
		while studentIndex < studentCount {
			// Create a new Student object with each column of the 2D array
			let newStudentKey = sheetCells[rowNumber][PgmConstants.studentKeyPosition]
			let newStudentName = sheetCells[rowNumber][PgmConstants.studentNamePosition]
			let newContactFirstName = sheetCells[rowNumber][PgmConstants.studentContactFirstNamePosition]
			let newContactLastName = sheetCells[rowNumber][PgmConstants.studentContactLastNamePosition]
			let newContactPhone = sheetCells[rowNumber][PgmConstants.studentContactPhonePosition]
			let newContactEmail = sheetCells[rowNumber][PgmConstants.studentContactEmailPosition]
			let newContactZipCode = sheetCells[rowNumber][PgmConstants.studentContactZipCodePosition]

			let newStudentStartDateString = sheetCells[rowNumber][PgmConstants.studentStartDatePosition]
			let newStudentAssignedUnassignedDateString = sheetCells[rowNumber][PgmConstants.studentAssignedUnassignedDatePosition]
			let newStudentLastBilledDateString = sheetCells[rowNumber][PgmConstants.studentLastBilledDatePosition]
			let newStudentEndDateString = sheetCells[rowNumber][PgmConstants.studentEndDatePosition]
			let newStudentStatus = sheetCells[rowNumber][PgmConstants.studentStatusPosition]
			let newStudentTutorKey = sheetCells[rowNumber][PgmConstants.studentTutorKeyPosition]
			let newStudentTutorName = sheetCells[rowNumber][PgmConstants.studentTutorNamePosition]
			let newStudentLocation = sheetCells[rowNumber][PgmConstants.studentLocationPosition]
			let newStudentTotalSessions = Int(sheetCells[rowNumber][PgmConstants.studentSessionsPosition]) ?? 0
			let newStudentCost = Float(sheetCells[rowNumber][PgmConstants.studentTotalCostPosition]) ?? 0.0
			let newStudentRevenue = Float(sheetCells[rowNumber][PgmConstants.studentTotalRevenuePosition]) ?? 0.0
			let newStudentProfit = Float(sheetCells[rowNumber][PgmConstants.studentTotalProfitPosition]) ?? 0.0
			// Create the new Student object
			let newStudent = Student(studentKey: newStudentKey, studentName: newStudentName, studentContactFirstName: newContactFirstName, studentContactLastName: newContactLastName,studentContactPhone: newContactPhone, studentContactEmail: newContactEmail, studentContactZipCode: newContactZipCode, studentStartDate: newStudentStartDateString, studentAssignedUnassignedDate: newStudentAssignedUnassignedDateString, studentLastBilledDate: newStudentLastBilledDateString, studentEndDate: newStudentEndDateString, studentStatus: newStudentStatus, studentTutorKey: newStudentTutorKey, studentTutorName: newStudentTutorName, studentLocation: newStudentLocation, studentSessions: newStudentTotalSessions, studentTotalCost: newStudentCost, studentTotalRevenue: newStudentRevenue, studentTotalProfit: newStudentProfit)
			// Add the new Student object to the Students List array
			self.studentsList.append(newStudent)
			
			studentIndex += 1
			rowNumber += 1
		}
		// When all rows have been processed, set the Flag that all Student data has been loaded
		self.isStudentDataLoaded = true

	}
	
	// This function takes the Students List object array and creates a 2D array of all the Student object data
	func unloadStudentRows() -> [[String]] {
		
		var updateValues = [[String]]()
		var studentNum = 0
		let studentCount = self.studentsList.count
		// Loop through each Student Object and extract the attributes
		while studentNum < studentCount {
			let studentKey = studentsList[studentNum].studentKey
			let studentName = studentsList[studentNum].studentName
			let studentContactFirstName = studentsList[studentNum].studentContactFirstName
			let studentContactLastName = studentsList[studentNum].studentContactLastName
			let studentContactPhone = studentsList[studentNum].studentContactPhone
			let studentContactEmail = studentsList[studentNum].studentContactEmail
			let studentContactZipCode = studentsList[studentNum].studentContactZipCode
	
			let studentStartDate = studentsList[studentNum].studentStartDate
			let studentAssignedUnassignedDate = studentsList[studentNum].studentAssignedUnassignedDate
			let studentLastBilledDate = studentsList[studentNum].studentLastBilledDate
			let studentEndDate = studentsList[studentNum].studentEndDate
			let studentStatus = studentsList[studentNum].studentStatus
			let studentTutorKey = studentsList[studentNum].studentTutorKey
			let studentTutorName = studentsList[studentNum].studentTutorName
			let studentLocation = studentsList[studentNum].studentLocation
			let studentSessions = String(studentsList[studentNum].studentSessions)
			let studentTotalCost = String(studentsList[studentNum].studentTotalCost.formatted(.number.precision(.fractionLength(2))))
			let studentTotalRevenue = String(studentsList[studentNum].studentTotalRevenue.formatted(.number.precision(.fractionLength(2))))
			let studentTotalProfit = String(studentsList[studentNum].studentTotalProfit.formatted(.number.precision(.fractionLength(2))))
			// Add the Student object data to the 2D array
			updateValues.insert([studentKey, studentName, studentContactFirstName, studentContactLastName, studentContactPhone, studentContactEmail, studentContactZipCode, studentStartDate, studentAssignedUnassignedDate, studentLastBilledDate, studentEndDate, studentStatus, studentTutorKey, studentTutorName, studentLocation, studentSessions, studentTotalCost, studentTotalRevenue, studentTotalProfit], at: studentNum)
			studentNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " "," ", " ", " ", " "," ", " ", " ", " "," ", " ", " ", " "], at: studentNum)
		return( updateValues)
	}
	
}
