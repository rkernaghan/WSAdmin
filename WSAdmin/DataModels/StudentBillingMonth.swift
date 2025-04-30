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
	
	func findBilledStudentByStudentName(billedStudentName: String) -> (Bool, Int) {
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
	
	func findBilledStudentsByTutorName(tutorName: String) -> (Bool, [Int]) {
		var found = false
		var billedStudentNumbers: [Int] = []
		var billedStudentNum = 0
	
		while billedStudentNum < studentBillingRows.count {
			if studentBillingRows[billedStudentNum].tutorName == tutorName {
				found = true
				billedStudentNumbers.append(billedStudentNum)
			}
			billedStudentNum += 1
		}
		return(found, billedStudentNumbers)
	}
	
	// Adds a new StudentBillingRow instance to the StudentBillingRows array.
	func addNewBilledStudent(studentName: String) {
		let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthBillingSessions: 0, monthBillingCost: 0.0, monthBillingRevenue: 0.0, monthBillingProfit: 0.0, totalBillingSessions: 0, totalBillingCost: 0.0, totalBillingRevenue: 0.0, totalBillingProfit: 0.0, tutorName: "", studentStatus: "Active", monthValidatedSessions: 0, monthValidatedCost: 0.0, monthValidatedRevenue: 0.0, monthValidatedProfit: 0.0, totalValidatedSessions: 0, totalValidatedCost: 0.0, totalValidatedRevenue: 0.0, totalValidatedProfit: 0.0)
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
	func loadStudentBillingRows(studentBillingCount: Int, sheetCells: [[String]], loadValidationDataFlag: Bool) {
		var monthValidatedSessions: Int = 0
		var monthValidatedCost: Float =  0.0
		var monthValidatedRevenue: Float = 0.0
		var monthValidatedProfit: Float = 0.0
		
		var totalValidatedSessions: Int = 0
		var totalValidatedCost: Float = 0.0
		var totalValidatedRevenue: Float = 0.0
		var totalValidatedProfit: Float = 0.0
		
		var studentBillingIndex = 0
		var rowNumber = 0
		// Loop through each row and add the data to a StudentBillingRow instance and add that instance to the StudentBillingMonth instance.
		while studentBillingIndex < studentBillingCount {
			let studentName = sheetCells[rowNumber][PgmConstants.studentBillingStudentCol]
			let monthBillingSessions: Int = Int(sheetCells[rowNumber][PgmConstants.studentBillingMonthSessionCol]) ?? 0
			let monthBillingCost: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthCostCol]) ?? 0.0
			let monthBillingRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthRevenueCol]) ?? 0.0
			let monthBillingProfit: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthProfitCol]) ?? 0.0
			
			let totalBillingSessions: Int = Int(sheetCells[rowNumber][PgmConstants.studentBillingTotalSessionCol]) ?? 0
			let totalBillingCost: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalCostCol]) ?? 0.0
			let totalBillingRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalRevenueCol]) ?? 0.0
			let totalBillingProfit: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalProfitCol]) ?? 0.0
			let studentStatus: String = sheetCells[rowNumber][PgmConstants.studentBillingStatusCol]
			
			if loadValidationDataFlag {
				monthValidatedSessions = Int(sheetCells[rowNumber][PgmConstants.studentValidatedMonthSessionCol]) ?? 0
				monthValidatedCost = Float(sheetCells[rowNumber][PgmConstants.studentValidatedMonthCostCol]) ?? 0.0
				monthValidatedRevenue = Float(sheetCells[rowNumber][PgmConstants.studentValidatedMonthRevenueCol]) ?? 0.0
				monthValidatedProfit = Float(sheetCells[rowNumber][PgmConstants.studentValidatedMonthProfitCol]) ?? 0.0
				
				totalValidatedSessions = Int(sheetCells[rowNumber][PgmConstants.studentValidatedTotalSessionCol]) ?? 0
				totalValidatedCost = Float(sheetCells[rowNumber][PgmConstants.studentValidatedTotalCostCol]) ?? 0.0
				totalValidatedRevenue = Float(sheetCells[rowNumber][PgmConstants.studentValidatedTotalRevenueCol]) ?? 0.0
				totalValidatedProfit = Float(sheetCells[rowNumber][PgmConstants.studentValidatedTotalProfitCol]) ?? 0.0
			}
			
			let rowSize = sheetCells[rowNumber].count
			var tutorName = ""
			if rowSize == PgmConstants.studentBillingTutorCol + 2 {
				tutorName = sheetCells[rowNumber][PgmConstants.studentBillingTutorCol]
			}
			
			let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthBillingSessions: monthBillingSessions, monthBillingCost: monthBillingCost, monthBillingRevenue: monthBillingRevenue, monthBillingProfit: monthBillingProfit, totalBillingSessions: totalBillingSessions, totalBillingCost: totalBillingCost, totalBillingRevenue: totalBillingRevenue, totalBillingProfit: totalBillingProfit, tutorName: tutorName, studentStatus: studentStatus, monthValidatedSessions: monthValidatedSessions, monthValidatedCost: monthValidatedCost, monthValidatedRevenue: monthValidatedRevenue, monthValidatedProfit: monthValidatedProfit, totalValidatedSessions: totalValidatedSessions, totalValidatedCost: totalValidatedCost, totalValidatedRevenue: totalValidatedRevenue, totalValidatedProfit: totalValidatedProfit)
			
			self.insertBilledStudentRow(studentBillingRow: newStudentBillingRow)
			
			rowNumber += 1
			studentBillingIndex += 1
		}
	}
	
	// Build a 2 dimensional array of strings to be written to the Student Billing spreadsheet for a month.
	func unloadStudentBillingRows(saveValidatedStudentData: Bool) -> [[String]] {
		
		var updateValues = [[String]]()
		var monthValidatedSessions: String = ""
		var monthValidatedCost: String = ""
		var monthValidatedRevenue: String = ""
		var monthValidatedProfit: String = ""
		var totalValidatedSessions: String = ""
		var totalValidatedCost: String = ""
		var totalValidatedRevenue: String = ""
		var totalValidatedProfit: String = ""
		
		let billedStudentCount = studentBillingRows.count
		var billedStudentNum = 0
		while billedStudentNum < billedStudentCount {
			let studentName: String = studentBillingRows[billedStudentNum].studentName
			let monthBillingSessions: String = String(studentBillingRows[billedStudentNum].monthBilledSessions)
			let monthBillingCost: String = String(studentBillingRows[billedStudentNum].monthBilledCost)
			let monthBillingRevenue: String = String(studentBillingRows[billedStudentNum].monthBilledRevenue)
			let monthBillingProfit: String = String(studentBillingRows[billedStudentNum].monthBilledProfit)
			let totalBillingSessions: String = String(studentBillingRows[billedStudentNum].totalBilledSessions)
			let totalBillingCost: String = String(studentBillingRows[billedStudentNum].totalBilledCost)
			let totalBillingRevenue: String = String(studentBillingRows[billedStudentNum].totalBilledRevenue)
			let totalBillingProfit: String = String(studentBillingRows[billedStudentNum].totalBilledProfit)
			let tutorName: String = studentBillingRows[billedStudentNum].tutorName
			let studentStatus: String = studentBillingRows[billedStudentNum].studentStatus
			
			if saveValidatedStudentData {
				monthValidatedSessions = String(studentBillingRows[billedStudentNum].monthValidatedSessions)
				monthValidatedCost = String(studentBillingRows[billedStudentNum].monthValidatedCost)
				monthValidatedRevenue = String(studentBillingRows[billedStudentNum].monthValidatedRevenue)
				monthValidatedProfit = String(studentBillingRows[billedStudentNum].monthValidatedProfit)
				totalValidatedSessions = String(studentBillingRows[billedStudentNum].totalValidatedSessions)
				totalValidatedCost = String(studentBillingRows[billedStudentNum].totalValidatedCost)
				totalValidatedRevenue = String(studentBillingRows[billedStudentNum].totalValidatedRevenue)
				totalValidatedProfit = String(studentBillingRows[billedStudentNum].totalValidatedProfit)
			}
			
			updateValues.insert([studentName, monthBillingSessions, monthBillingCost, monthBillingRevenue, monthBillingProfit, totalBillingSessions, totalBillingCost, totalBillingRevenue, totalBillingProfit, tutorName, studentStatus, "", monthValidatedSessions, monthValidatedCost, monthValidatedRevenue, monthValidatedProfit, totalValidatedSessions, totalValidatedCost, totalValidatedRevenue, totalValidatedProfit], at: billedStudentNum)
			billedStudentNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedStudentNum)
		return(updateValues)
	}

	// Reads a month from a Student Billing spreadsheet and loads a StudentBillingMonth array with a StudentBillingRow instance for each spreadsheet row.
	//
	func getStudentBillingMonth(monthName: String, studentBillingFileID: String, loadValidatedData: Bool) async -> Bool {
		var completionFlag: Bool = true
		
		var studentBillingCount: Int = 0
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		var studentCountData: SheetData?
		
		
		do {
			// Get the count of Students in the Billed Student spreadsheet
			studentCountData = try await readSheetCells(fileID: studentBillingFileID, range: monthName + PgmConstants.studentBillingCountRange)
			if let studentCountData = studentCountData {
				studentBillingCount = Int(studentCountData.values[0][0]) ?? 0
				// Read in the Billed Students from the Billed Student spreadsheet based on count
				if studentBillingCount > 0 {
					do {
						let cellRange = monthName + PgmConstants.studentBillingRange + String(PgmConstants.studentBillingStartRow + studentBillingCount - 1)
						sheetData = try await readSheetCells(fileID: studentBillingFileID, range: cellRange )
						if let sheetData = sheetData {
							sheetCells = sheetData.values
							// Build the Billed Students list for the month from the data read in
							loadStudentBillingRows(studentBillingCount: studentBillingCount, sheetCells: sheetCells, loadValidationDataFlag: loadValidatedData)
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
	// If the saveValidatedStudentData flag is True, write the Validated Data cells for the Students
	//
	func saveStudentBillingMonth(studentBillingFileID: String, billingMonth: String, saveValidatedStudentData: Bool) async -> Bool {
		var completionFlag: Bool = true
		
		// Write the Student Billing rows to the Billed Student spreadsheet
		let updateValues = unloadStudentBillingRows(saveValidatedStudentData: saveValidatedStudentData)
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
				completionFlag = await prevStudentBillingMonth.getStudentBillingMonth(monthName: prevMonth, studentBillingFileID: prevMonthStudentFileID, loadValidatedData: false)
				if completionFlag {
					// Loop through each row in the previous month entries and copy to self instance
					let prevStudentCount = prevStudentBillingMonth.studentBillingRows.count
					while prevStudentNum < prevStudentCount {
						let studentName = prevStudentBillingMonth.studentBillingRows[prevStudentNum].studentName
						let (foundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
						if foundFlag {
//							if referenceData.students.studentsList[studentNum].studentStatus != "Deleted" {
								let (foundFlag, billedStudentNum) = self.findBilledStudentByStudentName(billedStudentName: studentName)
								if !foundFlag {
									let totalBillingSessions = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalBilledSessions
									let totalBillingCost = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalBilledCost
									let totalBillingRevenue = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalBilledRevenue
									let totalBillingProfit = prevStudentBillingMonth.studentBillingRows[prevStudentNum].totalBilledProfit
									let tutorName = prevStudentBillingMonth.studentBillingRows[prevStudentNum].tutorName
									let studentStatus = prevStudentBillingMonth.studentBillingRows[prevStudentNum].studentStatus
									let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthBillingSessions: 0, monthBillingCost: 0.0, monthBillingRevenue: 0.0, monthBillingProfit: 0.0, totalBillingSessions: totalBillingSessions, totalBillingCost: totalBillingCost, totalBillingRevenue: totalBillingRevenue, totalBillingProfit: totalBillingProfit, tutorName: tutorName, studentStatus: studentStatus, monthValidatedSessions: 0, monthValidatedCost: 0.0, monthValidatedRevenue: 0.0, monthValidatedProfit: 0.0, totalValidatedSessions: 0, totalValidatedCost: 0.0, totalValidatedRevenue: 0.0, totalValidatedProfit: 0.0)
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
