//
//  StudentBillingMonth.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//
import Foundation

// StudentBillingMonth holds an array os StudentBillingRow instances.  Each array represents the STudent Billing data for one month.
class StudentBillingMonth {
	var studentBillingRows = [StudentBillingRow]()
	var monthName: String
	
	init(monthName: String) {
		self.monthName = monthName
	}
	
	func findBilledStudentByName(billedStudentName: String) -> (Bool, Int) {
		var found = false
		
		var billedStudentNum = 0
		while billedStudentNum < studentBillingRows.count && !found {
			if studentBillingRows[billedStudentNum].studentName == billedStudentName {
				found = true
			} else {
				billedStudentNum += 1
			}
		}
		return(found, billedStudentNum)
	}
	
	// Adds a new StudentBillingRow instance to the StudentBillingRows array.
	func addNewBilledStudent(studentName: String) {
		let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthSessions: 0, monthCost: 0.0, monthRevenue: 0.0, monthProfit: 0.0, totalSessions: 0, totalCost: 0.0, totalRevenue: 0.0, totalProfit: 0.0, tutorName: "", studentStatus: "Active")
		self.studentBillingRows.append(newStudentBillingRow)
	}
	// Adds a StudentBillingRow instance read from the StudentBilling spreadsheet to the StudentBillingRows array.
	func insertBilledStudentRow(studentBillingRow: StudentBillingRow) {
		self.studentBillingRows.append(studentBillingRow)
	}
	
	// Marks a StudentBillingRow instance as Deleted (when a Student is deleted).  StudentBillingRow is kept so the totals are kept in sync with Student data.
	func deleteBilledStudent(billedStudentNum: Int) {
		self.studentBillingRows[billedStudentNum].studentStatus = "Deleted"
	}
	
	// Builds a StudentBillingMonth array from the data read from the Student Billing sheet for a month.
	func loadStudentBillingRows(studentBillingCount: Int, sheetCells: [[String]]) {
		
		var studentBillingIndex = 0
		var rowNumber = 0
		// Loop through each row and add the data to a StudentBillingRow instance and add that instance to the StudentBillingMonth instance.
		while studentBillingIndex < studentBillingCount {
			let studentName = sheetCells[rowNumber][PgmConstants.studentBillingStudentCol]
			let monthSessions: Int = Int(sheetCells[rowNumber][PgmConstants.studentBillingMonthSessionCol]) ?? 0
			let monthCost: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthCostCol]) ?? 0.0
			let monthRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthRevenueCol]) ?? 0.0
			let monthProfit: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthProfitCol]) ?? 0.0
			
			let totalSessions: Int = Int(sheetCells[rowNumber][PgmConstants.studentBillingTotalSessionCol]) ?? 0
			let totalCost: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalCostCol]) ?? 0.0
			let totalRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalRevenueCol]) ?? 0.0
			let totalProfit: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalProfitCol]) ?? 0.0
			let studentStatus: String = sheetCells[rowNumber][PgmConstants.studentBillingStatusCol]
			
			let rowSize = sheetCells[rowNumber].count
			var tutorName = ""
			if rowSize == PgmConstants.studentBillingTutorCol + 2 {
				tutorName = sheetCells[rowNumber][PgmConstants.studentBillingTutorCol]
			}
			
			let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthSessions: monthSessions, monthCost: monthCost, monthRevenue: monthRevenue, monthProfit: monthProfit, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit, tutorName: tutorName, studentStatus: studentStatus)
			
			self.insertBilledStudentRow(studentBillingRow: newStudentBillingRow)
			
			rowNumber += 1
			studentBillingIndex += 1
		}
	}
	
	// Build a 2 dimensional array of strings to be written to the Student Billing spreadsheet for a month.
	func unloadStudentBillingRows() -> [[String]] {
		
		var updateValues = [[String]]()
		
		let billedStudentCount = studentBillingRows.count
		var billedStudentNum = 0
		while billedStudentNum < billedStudentCount {
			let studentName: String = studentBillingRows[billedStudentNum].studentName
			let monthSessions: String = String(studentBillingRows[billedStudentNum].monthSessions)
			let monthCost: String = String(studentBillingRows[billedStudentNum].monthCost)
			let monthRevenue: String = String(studentBillingRows[billedStudentNum].monthRevenue)
			let monthProfit: String = String(studentBillingRows[billedStudentNum].monthProfit)
			let totalSessions: String = String(studentBillingRows[billedStudentNum].totalSessions)
			let totalCost: String = String(studentBillingRows[billedStudentNum].totalCost)
			let totalRevenue: String = String(studentBillingRows[billedStudentNum].totalRevenue)
			let totalProfit: String = String(studentBillingRows[billedStudentNum].totalProfit)
			let tutorName: String = studentBillingRows[billedStudentNum].tutorName
			let studentStatus: String = studentBillingRows[billedStudentNum].studentStatus
			
			updateValues.insert([studentName, monthSessions, monthCost, monthRevenue, monthProfit, totalSessions, totalCost, totalRevenue, totalProfit, tutorName, studentStatus], at: billedStudentNum)
			billedStudentNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedStudentNum)
		return(updateValues)
	}

	// Reads a month from a Student Billing spreadsheet and loads a StudentBillingMonth array with a StudentBillingRow instance for each spreadsheet row.
	//
	func getStudentBillingMonth(monthName: String, studentBillingFileID: String) async -> Bool {
		var completionFlag: Bool = true
		
		var studentBillingCount: Int = 0
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		var studentCountData: SheetData?
		
		// Get the count of Students in the Billed Student spreadsheet
		do {
			studentCountData = try await readSheetCells(fileID: studentBillingFileID, range: monthName + PgmConstants.studentBillingCountRange)
			if let studentCountData = studentCountData {
				studentBillingCount = Int(studentCountData.values[0][0]) ?? 0
				// Read in the Billed Students from the Billed Student spreadsheet
				if studentBillingCount > 0 {
					do {
						sheetData = try await readSheetCells(fileID: studentBillingFileID, range: monthName + PgmConstants.studentBillingRange + String(PgmConstants.studentBillingStartRow + studentBillingCount - 1) )
						if let sheetData = sheetData {
							sheetCells = sheetData.values
							// Build the Billed Students list for the month from the data read in
							loadStudentBillingRows(studentBillingCount: studentBillingCount, sheetCells: sheetCells)
						} else {
							completionFlag = false
						}
						
					} catch {
						completionFlag = false
					}
				}
			} else {
				completionFlag = false
			}
		} catch {
			completionFlag = false
		}
		return(completionFlag)
	}
	
	// Saves a Student Billing Month by unloading the array to a 2 dimensional array of strings and writing those strings to a sheet (month) in the Student Billing spreadsheet
	//
	func saveStudentBillingMonth(studentBillingFileID: String, billingMonth: String) async -> Bool {
		var completionFlag: Bool = true
		
		// Write the Student Billing rows to the Billed Student spreadsheet
		let updateValues = unloadStudentBillingRows()
		let range = billingMonth + PgmConstants.studentBillingRange + String(PgmConstants.studentBillingStartRow + updateValues.count - 1)
		do {
			var result = try await writeSheetCells(fileID: studentBillingFileID, range: range, values: updateValues)
			if !result {
				completionFlag = false
			} else {
				// Write the count of Student Billing rows to the Billed Student spreadsheet
				let billedStudentCount = updateValues.count - 1              // subtract 1 for blank line at end
				do {
					result = try await writeSheetCells(fileID: studentBillingFileID, range: billingMonth + PgmConstants.studentBillingCountRange, values: [[ String(billedStudentCount) ]])
					if !result {
						completionFlag = false
					}
				} catch {
					print ("Error: Saving Billed Student count failed")
					completionFlag = false
				}
			}
		} catch {
			print ("Error: Saving Billed Student rows failed")
			completionFlag = false
		}
		
		return(completionFlag)
	}
	
	
	// Copies a previous month's Student Billing month rows (totals only not previous month values) into this (self) Student Billing Month instance.  Used to create a new Student Billing month instance when billing a new month that
	// hasn't been billing before.
	func copyStudentBillingMonth(billingMonth: String, billingMonthYear: String, referenceData: ReferenceData) async -> Bool {
		var completionFlag: Bool = true
		// Determine the file name of the previous month Student Billiing spreadsheet (could be a previous year)
		let (prevMonth, prevMonthYear) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingMonthYear)
		var prevStudentNum: Int = 0
		let prevStudentBillingMonth = StudentBillingMonth(monthName: prevMonth)
		
		let prevMonthStudentFileName = studentBillingFileNamePrefix + prevMonthYear
		
		do {
			// Get the File ID of the previous month Student Billing Month spreadsheet
			let (resultFlag, prevMonthStudentFileID) = try await getFileID(fileName: prevMonthStudentFileName)
			if resultFlag {
				completionFlag = await prevStudentBillingMonth.getStudentBillingMonth(monthName: prevMonth, studentBillingFileID: prevMonthStudentFileID)
				if completionFlag {
					// Loop through each row in the previous month entries and copy to self instance
					let prevStudentCount = prevStudentBillingMonth.studentBillingRows.count
					while prevStudentNum < prevStudentCount {
						let studentName = prevStudentBillingMonth.studentBillingRows[prevStudentNum].studentName
						let (foundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
						if foundFlag {
//							if referenceData.students.studentsList[studentNum].studentStatus != "Deleted" {
								let (foundFlag, billedStudentNum) = self.findBilledStudentByName(billedStudentName: studentName)
								if !foundFlag {
									let totalSessions = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalSessions
									let totalCost = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalCost
									let totalRevenue = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalRevenue
									let totalProfit = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalProfit
									let tutorName = prevStudentBillingMonth.studentBillingRows[prevStudentNum].tutorName
									let studentStatus = prevStudentBillingMonth.studentBillingRows[prevStudentNum].studentStatus
									let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthSessions: 0, monthCost: 0.0, monthRevenue: 0.0, monthProfit: 0.0, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit, tutorName: tutorName, studentStatus: studentStatus)
									self.studentBillingRows.append(newStudentBillingRow)
								}
//							}
						}
						prevStudentNum += 1
					}
				}
			} else {
				completionFlag = false
			}
		} catch {
			print("Critical Error: Could not load \(prevMonth) Student Billing Data")
			completionFlag = false
		}
		
		return(completionFlag)
	}
	
}
