//
//  TutorBillingMonth.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//
import Foundation

class TutorBillingMonth {
	var tutorBillingRows = [TutorBillingRow]()
	
	func findBilledTutorByName(billedTutorName: String) -> (Bool, Int) {
		var found = false
		
		var billedTutorNum = 0
		while billedTutorNum < tutorBillingRows.count && !found {
			if tutorBillingRows[billedTutorNum].tutorName == billedTutorName {
				found = true
			} else {
				billedTutorNum += 1
			}
		}
		return(found, billedTutorNum)
	}
    
	func addNewBilledTutor(tutorName: String) {
		let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthSessions: 0, monthCost: 0.0, monthRevenue: 0.0, monthProfit: 0.0, totalSessions: 0, totalCost: 0.0, totalRevenue: 0.0, totalProfit: 0.0)
		self.tutorBillingRows.append(newTutorBillingRow)
	}
	
	func insertBilledTutorRow(tutorBillingRow: TutorBillingRow) {
		self.tutorBillingRows.append(tutorBillingRow)
	}
	
	func deleteBilledTutor(billedTutorNum: Int) {
		self.tutorBillingRows.remove(at: billedTutorNum)
	}
	
	
	func loadTutorBillingMonth(monthName: String, tutorBillingFileID: String) async {
		var tutorBillingCount: Int = 0
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		
		// Get the count of Tutors in the Billed Tutor spreadsheet
		do {
			sheetData = try await readSheetCells(fileID: tutorBillingFileID, range: monthName + PgmConstants.tutorBillingCountRange)
		} catch {
			
		}
		
		if let sheetData = sheetData {
			tutorBillingCount = Int(sheetData.values[0][0]) ?? 0
		}
		// Read in the Billed Tutors from the Billed Tutor spreadsheet
		if tutorBillingCount > 0 {
			do {
				sheetData = try await readSheetCells(fileID: tutorBillingFileID, range: monthName + PgmConstants.tutorBillingRange + String(PgmConstants.tutorBillingStartRow + tutorBillingCount - 1) )
			} catch {
				
			}
			
			if let sheetData = sheetData {
				sheetCells = sheetData.values
			}
			// Build the Billed Tutors list for the month from the data read in
			loadTutorBillingRows(tutorBillingCount: tutorBillingCount, sheetCells: sheetCells)
		}
	}
    
    
	func saveTutorBillingData(tutorBillingFileID: String, billingMonth: String) async -> Bool {
		var result: Bool = true
		// Write the Tutor Billing rows to the Billed Tutor spreadsheet
		let updateValues = unloadTutorBillingRows()
		let count = updateValues.count
		let range = billingMonth + PgmConstants.tutorBillingRange + String(PgmConstants.tutorBillingStartRow + updateValues.count - 1)
		do {
			result = try await writeSheetCells(fileID: tutorBillingFileID, range: range, values: updateValues)
		} catch {
			print ("Error: Saving Billed tutor rows failed")
			result = false
		}
		// Write the count of tutor Billing rows to the Billed tutor spreadsheet
		let billedTutorCount = updateValues.count - 1              // subtract 1 for blank line at end
		do {
			let range = billingMonth + PgmConstants.tutorBillingCountRange
			result = try await writeSheetCells(fileID: tutorBillingFileID, range: range, values: [[ String(billedTutorCount) ]])
		} catch {
			print ("Error: Saving Billed Tutor count failed")
			result = false
		}
		
		return(result)
	}
//
// This function take an array of strings read from a Billed Tutor sheet and builds an instance of a
// Tutor Billing class with the data.
//
	func loadTutorBillingRows(tutorBillingCount: Int, sheetCells: [[String]]) {
		
		var tutorBillingIndex = 0
		var rowNumber = 0
		while tutorBillingIndex < tutorBillingCount {
			let tutorName = sheetCells[rowNumber][PgmConstants.tutorBillingTutorCol]
			let monthSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
			let monthCost: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthCostCol]) ?? 0.0
			let monthRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthRevenueCol]) ?? 0.0
			let monthProfit: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthProfitCol]) ?? 0.0
			
			let totalSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
			let totalCost: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalCostCol]) ?? 0.0
			let totalRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalRevenueCol]) ?? 0.0
			let totalProfit: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalProfitCol]) ?? 0.0
			
			let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthSessions: monthSessions, monthCost: monthCost, monthRevenue: monthRevenue, monthProfit: monthProfit, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit)
			
			self.insertBilledTutorRow(tutorBillingRow: newTutorBillingRow)
			
			rowNumber += 1
			tutorBillingIndex += 1
		}
	}

//
// This functions takes a Billed Tutor month class and creates an array of strings for writing to a Billed Tutor
// sheet.
//
	func unloadTutorBillingRows() -> [[String]] {
		
		var updateValues = [[String]]()
		
		let billedTutorCount = tutorBillingRows.count
		var billedTutorNum = 0
		while billedTutorNum < billedTutorCount {
			let tutorName: String = tutorBillingRows[billedTutorNum].tutorName
			let monthSessions: String = String(tutorBillingRows[billedTutorNum].monthSessions)
			let monthCost: String = String(tutorBillingRows[billedTutorNum].monthCost)
			let monthRevenue: String = String(tutorBillingRows[billedTutorNum].monthRevenue)
			let monthProfit: String = String(tutorBillingRows[billedTutorNum].monthProfit)
			let totalSessions: String = String(tutorBillingRows[billedTutorNum].totalSessions)
			let totalCost: String = String(tutorBillingRows[billedTutorNum].totalCost)
			let totalRevenue: String = String(tutorBillingRows[billedTutorNum].totalRevenue)
			let totalProfit: String = String(tutorBillingRows[billedTutorNum].totalProfit)
			
			updateValues.insert([tutorName, monthSessions, monthCost, monthRevenue, monthProfit, totalSessions, totalCost, totalRevenue, totalProfit], at: billedTutorNum)
			billedTutorNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedTutorNum)
		return(updateValues)
	}
//
// This function checks if a Tutor has already been billed (i.e. session count > 0) in this Billed Tutor month
//
	func checkAlreadyBilled(tutorList: [String]) -> (Bool, [String]) {
		var resultFlag: Bool = false
		var alreadyBilledTutors = [String]()
		var tutorName: String = ""
		
		let tutorListCount = tutorList.count
		var tutorListNum = 0
		let billedTutorCount = self.tutorBillingRows.count
		if billedTutorCount != 0 {
			
			while tutorListNum < tutorListCount {
				tutorName = tutorList[tutorListNum]
				let (foundFlag, billedTutorNum) = findBilledTutorByName(billedTutorName: tutorName)
				if foundFlag {
					if tutorBillingRows[billedTutorNum].monthSessions > 0 {
						alreadyBilledTutors.append(tutorName)
						resultFlag = true
					}
				}
				tutorListNum += 1
			}
		}
		
		return(resultFlag, alreadyBilledTutors)
	}
//
// This function copies the Tutors from the previous month's sheet from the Billed Tutor spreadsheet to the current (billing) month's
// sheet.  It sets the current month data columns to zero and the total data columns to the totals from the previous month.
// So if March is being billed it copies the Tutor data from February.  If a Tutor already exists in the current month's sheet
// that Tutor is not copied again.
//
	func copyTutorBillingMonth(billingMonth: String, billingMonthYear: String, referenceData: ReferenceData) async {
		
		let (prevMonth, prevMonthYear) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingMonthYear)
		// Load the Billed Tutor data from the previous month's sheet
		let prevTutorBillingMonth = TutorBillingMonth()
		let prevMonthTutorFileName = tutorBillingFileNamePrefix + prevMonthYear
		do {
			let (resultFlag, prevMonthTutorFileID) = try await getFileID(fileName: prevMonthTutorFileName)
			if resultFlag {
				await prevTutorBillingMonth.loadTutorBillingMonth(monthName: prevMonth, tutorBillingFileID: prevMonthTutorFileID)
			}
		} catch {
			print("ERROR: Could not load \(prevMonth) Tutor Billing Data")
		}
		// Loop through each Tutor from the previous month's Billed Tutor sheet
		var prevTutorNum: Int = 0
		let prevTutorCount = prevTutorBillingMonth.tutorBillingRows.count
		while prevTutorNum < prevTutorCount {
			let tutorName = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].tutorName
			let (foundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
			if foundFlag {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
					let (foundFlag, billedTutorNum) = self.findBilledTutorByName(billedTutorName: tutorName)
					if !foundFlag {
						let totalSessions = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalSessions
						let totalCost = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalCost
						let totalRevenue = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalRevenue
						let totalProfit = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalProfit
						let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthSessions: 0, monthCost: 0.0, monthRevenue: 0.0, monthProfit: 0.0, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit)
						self.tutorBillingRows.append(newTutorBillingRow)
					}
				}
			}
			//   print("Month: \(prevTutorNum)\(self.tutorBillingRows[prevTutorNum].monthSessions) \(self.tutorBillingRows[prevTutorNum].monthCost) \(self.tutorBillingRows[prevTutorNum].monthRevenue) ")
			prevTutorNum += 1
		}
	}
	
}
