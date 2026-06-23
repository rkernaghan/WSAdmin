//
//  TutorBillingMonth.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//
import Foundation
//
// TutorBillingMonth manages the Tutor billing stat data stored in the Tutor Billing Summary <year> spreadsheet.
//
class TutorBillingMonth {
	var tutorBillingRows = [TutorBillingRow]()
	var monthName: String
	
	init(monthName: String) {
		self.monthName = monthName
	}
	
	func findBilledTutorByName(billedTutorName: String) -> (Bool, Int) {
		
		if let index = tutorBillingRows.firstIndex(
			where: { $0.tutorName == billedTutorName }
		) {
			return (true, index)
		}
		return (false, 0)
	}
    
	func addNewBilledTutor(tutorName: String) {
		let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthBillingSessions: 0, monthBillingHours: 0, monthBillingCost: 0.0, monthBillingRevenue: 0.0, monthBillingProfit: 0.0,  q1BilledSessions: 0, q1BilledHours: 0, q1BilledCost: 0.0, q1BilledRevenue: 0.0, q1BilledProfit: 0.0, q2BilledSessions: 0, q2BilledHours: 0, q2BilledCost: 0.0, q2BilledRevenue: 0.0, q2BilledProfit: 0.0, q3BilledSessions: 0, q3BilledHours: 0, q3BilledCost: 0.0, q3BilledRevenue: 0.0, q3BilledProfit: 0.0, q4BilledSessions: 0, q4BilledHours: 0, q4BilledCost: 0.0, q4BilledRevenue: 0.0, q4BilledProfit: 0.0, totalBillingSessions: 0, totalBillingHours: 0, totalBillingCost: 0.0, totalBillingRevenue: 0.0, totalBillingProfit: 0.0, tutorBillingStatus: .BilledTutorActive)
		self.tutorBillingRows.append(newTutorBillingRow)
	}
	
	func insertBilledTutorRow(tutorBillingRow: TutorBillingRow) {
		self.tutorBillingRows.append(tutorBillingRow)
	}
	
	func deleteBilledTutor(billedTutorNum: Int) {
		self.tutorBillingRows[billedTutorNum].tutorBillingStatus = .BilledTutorDeleted
	}
	
	
	func getTutorBillingMonth(monthName: String, tutorBillingFileID: String, loadValidatedData: Bool) async -> Bool {
		var completionFlag = true
		var tutorBillingCount: Int = 0
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		var tutorCountData: SheetData?
		
		// Get the count of Tutors in the Billed Tutor spreadsheet
		do {
			tutorCountData = try await readSheetCells(fileID: tutorBillingFileID, range: monthName + PgmConstants.tutorBillingCountRange)
			if let tutorCountData = tutorCountData {
				tutorBillingCount = Int(tutorCountData.values[0][0]) ?? 0
				// Read in the Billed Tutors from the Billed Tutor spreadsheet
				if tutorBillingCount > 0 {			// Could be zero if loading a Billed Tutor month not yet billed
					do {
						let cellRange = monthName + PgmConstants.tutorBillingRange + String(PgmConstants.tutorBillingStartRow + tutorBillingCount - 1)
						sheetData = try await readSheetCells(fileID: tutorBillingFileID, range: cellRange)
						if let sheetData = sheetData {
							sheetCells = sheetData.values
							
							// Build the Billed Tutors list for the month from the data read in
							loadTutorBillingRows(tutorBillingCount: tutorBillingCount, sheetCells: sheetCells)
						}
						
					} catch {
						completionFlag = false
					}
					
				}
//				} else {
//					completionFlag = false
//				}
			} else {
				completionFlag = false
			}
			
		} catch {
			completionFlag = false
		}
		
		return(completionFlag)
	}
    
	// Saves a Tutor Billing Month by unloading the array to a 2 dimensional array of strings and writing those strings to a sheet (month) in the Tutor Billing spreadsheet
	// If the saveValidatedTutorData flag is True, write the Validated Data cells for the Tutors
	
	func saveTutorBillingData(tutorBillingFileID: String, billingMonth: String, saveValidatedTutorData: Bool) async -> Bool {
		var completionFlag: Bool = true
		
		// Write the Tutor Billing rows to the Billed Tutor spreadsheet
		let updateValues = unloadTutorBillingRows()
		let count = updateValues.count
		let range = billingMonth + PgmConstants.tutorBillingRange + String(PgmConstants.tutorBillingStartRow + updateValues.count - 1)
		
		do {
			var result = try await writeSheetCells(fileID: tutorBillingFileID, range: range, values: updateValues)
			if !result {
				completionFlag = false
			} else {
				// Write the count of tutor Billing rows to the Billed tutor spreadsheet
				let billedTutorCount = updateValues.count - 1              // subtract 1 for blank line at end
				do {
					let range = billingMonth + PgmConstants.tutorBillingCountRange
					result = try await writeSheetCells(fileID: tutorBillingFileID, range: range, values: [[ String(billedTutorCount) ]])
					if !result {
						completionFlag = false
					}
				} catch {
					print ("Error: Saving Billed Tutor count failed")
					completionFlag = false
				}
			}
		} catch {
			print ("Error: Saving Billed tutor rows failed")
			completionFlag = false
		}
		
		return(completionFlag)
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
			let monthBillingSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
			let monthBillingHours: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingMonthHoursCol]) ?? 0.0
			let monthBillingCost: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingMonthCostCol]) ?? 0.0
			let monthBillingRevenue: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingMonthRevenueCol]) ?? 0.0
			let monthBillingProfit: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingMonthProfitCol]) ?? 0.0
			
			let q1Sessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingQ1SessionCol]) ?? 0
			let q1Hours: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ1HoursCol]) ?? 0.0
			let q1Cost: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ1CostCol]) ?? 0.0
			let q1Revenue: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ1RevenueCol]) ?? 0.0
			let q1Profit: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ1ProfitCol]) ?? 0.0

			let q2Sessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingQ2SessionCol]) ?? 0
			let q2Hours: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ2HoursCol]) ?? 0.0
			let q2Cost: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ2CostCol]) ?? 0.0
			let q2Revenue: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ2RevenueCol]) ?? 0.0
			let q2Profit: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ2ProfitCol]) ?? 0.0
			
			let q3Sessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingQ3SessionCol]) ?? 0
			let q3Hours: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ3HoursCol]) ?? 0.0
			let q3Cost: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ3CostCol]) ?? 0.0
			let q3Revenue: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ3RevenueCol]) ?? 0.0
			let q3Profit: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ3ProfitCol]) ?? 0.0
			
			let q4Sessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingQ4SessionCol]) ?? 0
			let q4Hours: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ4HoursCol]) ?? 0.0
			let q4Cost: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ4CostCol]) ?? 0.0
			let q4Revenue: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ4RevenueCol]) ?? 0.0
			let q4Profit: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingQ4ProfitCol]) ?? 0.0
			
			let totalBillingSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingTotalSessionCol]) ?? 0
			let totalBillingHours: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingTotalHoursCol]) ?? 0.0
			let totalBillingCost: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingTotalCostCol]) ?? 0.0
			let totalBillingRevenue: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingTotalRevenueCol]) ?? 0.0
			let totalBillingProfit: Double = Double(sheetCells[rowNumber][PgmConstants.tutorBillingTotalProfitCol]) ?? 0.0
			
			let tutorBillingStatus = TutorBillingStatusOption( rawValue: sheetCells[rowNumber][PgmConstants.tutorBillingStatusCol]) ?? .BilledTutorActive
			
			let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthBillingSessions: monthBillingSessions, monthBillingHours: monthBillingHours, monthBillingCost: monthBillingCost, monthBillingRevenue: monthBillingRevenue, monthBillingProfit: monthBillingProfit, q1BilledSessions: q1Sessions, q1BilledHours: q1Hours, q1BilledCost: q1Cost, q1BilledRevenue: q1Revenue, q1BilledProfit: q1Profit, q2BilledSessions: q2Sessions, q2BilledHours: q2Hours,q2BilledCost: q2Cost, q2BilledRevenue: q2Revenue, q2BilledProfit: q2Profit, q3BilledSessions: q3Sessions, q3BilledHours: q3Hours, q3BilledCost: q3Cost, q3BilledRevenue: q3Revenue, q3BilledProfit: q3Profit, q4BilledSessions: q4Sessions, q4BilledHours: q4Hours,q4BilledCost: q4Cost, q4BilledRevenue: q4Revenue, q4BilledProfit: q4Profit, totalBillingSessions: totalBillingSessions, totalBillingHours: totalBillingHours, totalBillingCost: totalBillingCost, totalBillingRevenue: totalBillingRevenue, totalBillingProfit: totalBillingProfit, tutorBillingStatus: tutorBillingStatus)
			
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
			let monthBillingSessions: String = String(tutorBillingRows[billedTutorNum].monthBilledSessions)
			let monthBillingHours: String = String(tutorBillingRows[billedTutorNum].monthBilledHours)
			let monthBillingCost: String = String(tutorBillingRows[billedTutorNum].monthBilledCost)
			let monthBillingRevenue: String = String(tutorBillingRows[billedTutorNum].monthBilledRevenue)
			let monthBillingProfit: String = String(tutorBillingRows[billedTutorNum].monthBilledProfit)
			
			let q1Sessions: String = String(tutorBillingRows[billedTutorNum].q1BilledSessions)
			let q1Hours: String = String(tutorBillingRows[billedTutorNum].q1BilledHours)
			let q1Cost: String = String(tutorBillingRows[billedTutorNum].q1BilledCost)
			let q1Revenue: String = String(tutorBillingRows[billedTutorNum].q1BilledRevenue)
			let q1Profit: String = String(tutorBillingRows[billedTutorNum].q1BilledProfit)
			
			let q2Sessions: String = String(tutorBillingRows[billedTutorNum].q2BilledSessions)
			let q2Hours: String = String(tutorBillingRows[billedTutorNum].q2BilledHours)
			let q2Cost: String = String(tutorBillingRows[billedTutorNum].q2BilledCost)
			let q2Revenue: String = String(tutorBillingRows[billedTutorNum].q2BilledRevenue)
			let q2Profit: String = String(tutorBillingRows[billedTutorNum].q2BilledProfit)

			let q3Sessions: String = String(tutorBillingRows[billedTutorNum].q3BilledSessions)
			let q3Hours: String = String(tutorBillingRows[billedTutorNum].q3BilledHours)
			let q3Cost: String = String(tutorBillingRows[billedTutorNum].q3BilledCost)
			let q3Revenue: String = String(tutorBillingRows[billedTutorNum].q3BilledRevenue)
			let q3Profit: String = String(tutorBillingRows[billedTutorNum].q3BilledProfit)

			let q4Sessions: String = String(tutorBillingRows[billedTutorNum].q4BilledSessions)
			let q4Hours: String = String(tutorBillingRows[billedTutorNum].q4BilledHours)
			let q4Cost: String = String(tutorBillingRows[billedTutorNum].q4BilledCost)
			let q4Revenue: String = String(tutorBillingRows[billedTutorNum].q4BilledRevenue)
			let q4Profit: String = String(tutorBillingRows[billedTutorNum].q4BilledProfit)
			
			let totalBillingSessions: String = String(tutorBillingRows[billedTutorNum].totalBilledSessions)
			let totalBillingHours: String = String(tutorBillingRows[billedTutorNum].totalBilledHours)
			let totalBillingCost: String = String(tutorBillingRows[billedTutorNum].totalBilledCost)
			let totalBillingRevenue: String = String(tutorBillingRows[billedTutorNum].totalBilledRevenue)
			let totalBillingProfit: String = String(tutorBillingRows[billedTutorNum].totalBilledProfit)
			let tutorBillingStatus = String( describing: tutorBillingRows[billedTutorNum].tutorBillingStatus.rawValue)
			
			updateValues.insert([tutorName, monthBillingSessions, monthBillingHours, monthBillingCost, monthBillingRevenue, monthBillingProfit, "", q1Sessions, q1Hours, q1Cost, q1Revenue, q1Profit, "", q2Sessions, q2Hours, q2Cost, q2Revenue, q2Profit, "", q3Sessions, q3Hours, q3Cost, q3Revenue, q3Profit, "", q4Sessions, q4Hours, q4Cost, q4Revenue, q4Profit,"",totalBillingSessions, totalBillingHours, totalBillingCost, totalBillingRevenue, totalBillingProfit, tutorBillingStatus], at: billedTutorNum)
			billedTutorNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedTutorNum)
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
					if tutorBillingRows[billedTutorNum].monthBilledSessions > 0 {
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
	@MainActor func copyTutorBillingMonth(billingMonth: String, billingMonthYear: String, referenceData: ReferenceData) async -> (Bool, String) {
		var completionFlag: Bool = true
		var completionMessage: String = ""
		
		let (prevMonth, prevMonthYear) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingMonthYear)
		// Load the Billed Tutor data from the previous month's sheet
		let prevTutorBillingMonth = TutorBillingMonth(monthName: billingMonth)
		let prevMonthTutorFileName = tutorBillingFileNamePrefix + prevMonthYear
		do {
			let (resultFlag, prevMonthTutorFileID) = try await getFileID(fileName: prevMonthTutorFileName)
			guard resultFlag else {
				print("Error: could not get File ID for \(prevMonthTutorFileName)")
				return(false, "Error: could not get File ID for \(prevMonthTutorFileName)")
			}
				
			completionFlag = await prevTutorBillingMonth.getTutorBillingMonth(monthName: prevMonth, tutorBillingFileID: prevMonthTutorFileID, loadValidatedData: false)
			guard completionFlag else {
				print("Error: could not load prev month Billed Tutor month \(billingMonth) \(billingMonthYear)")
				return(false, "Error: could not load prev month Billed Tutor month \(billingMonth) \(billingMonthYear)")
			}
			
			// Loop through each Tutor from the previous month's Billed Tutor sheet
			var prevTutorNum: Int = 0
			let prevTutorCount = prevTutorBillingMonth.tutorBillingRows.count
			while prevTutorNum < prevTutorCount {
				let tutorName = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].tutorName
				let (foundTutorFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
				guard foundTutorFlag  else {
					print("Error: could not find Tutor \(tutorName) in Reference Data when copying previous months billing data")
					return(false, "Error: could not find Tutor \(tutorName) in Reference Data when copying previous months billing data")
				}
				
				// If Tutor does not already exist in Billed Tutor file for month, copy previous month's data
				let (billedTutorFoundFlag, billedTutorNum) = self.findBilledTutorByName(billedTutorName: tutorName)
				// Check if Tutor exists in previous month's TutorBilling sheet and copy data if found.
				if !billedTutorFoundFlag {
					
					let q1Sessions = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q1BilledSessions
					let q1Hours = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q1BilledHours
					let q1Cost = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q1BilledCost
					let q1Revenue = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q1BilledRevenue
					let q1Profit = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q1BilledProfit
					
					let q2Sessions = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q2BilledSessions
					let q2Hours = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q2BilledHours
					let q2Cost = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q2BilledCost
					let q2Revenue = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q2BilledRevenue
					let q2Profit = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q2BilledProfit
					
					let q3Sessions = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q3BilledSessions
					let q3Hours = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q3BilledHours
					let q3Cost = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q3BilledCost
					let q3Revenue = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q3BilledRevenue
					let q3Profit = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q3BilledProfit
					
					let q4Sessions = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q4BilledSessions
					let q4Hours = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q4BilledHours
					let q4Cost = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q4BilledCost
					let q4Revenue = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q4BilledRevenue
					let q4Profit = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].q4BilledProfit
					
					let totalBillingSessions = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledSessions
					let totalBillingHours = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledHours
					let totalBillingCost = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledCost
					let totalBillingRevenue = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledRevenue
					let totalBillingProfit = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledProfit
					let tutorBillingStatus = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].tutorBillingStatus
					
					if billingMonth != "Jan" {
						let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthBillingSessions: 0, monthBillingHours: 0.0, monthBillingCost: 0.0, monthBillingRevenue: 0.0, monthBillingProfit: 0.0, q1BilledSessions: q1Sessions, q1BilledHours: q1Hours, q1BilledCost: q1Cost, q1BilledRevenue: q1Revenue, q1BilledProfit: q1Profit, q2BilledSessions: q2Sessions, q2BilledHours: q2Hours, q2BilledCost: q2Cost, q2BilledRevenue: q2Revenue, q2BilledProfit: q2Profit, q3BilledSessions: q3Sessions, q3BilledHours: q3Hours, q3BilledCost: q3Cost, q3BilledRevenue: q3Revenue, q3BilledProfit: q3Profit, q4BilledSessions: q4Sessions, q4BilledHours: q4Hours, q4BilledCost: q4Cost, q4BilledRevenue: q4Revenue, q4BilledProfit: q4Profit, totalBillingSessions: totalBillingSessions, totalBillingHours: totalBillingHours, totalBillingCost: totalBillingCost, totalBillingRevenue: totalBillingRevenue, totalBillingProfit: totalBillingProfit, tutorBillingStatus: tutorBillingStatus)
						self.tutorBillingRows.append(newTutorBillingRow)
					} else {
						let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthBillingSessions: 0, monthBillingHours: 0.0, monthBillingCost: 0.0, monthBillingRevenue: 0.0, monthBillingProfit: 0.0, q1BilledSessions: 0, q1BilledHours: 0.0, q1BilledCost: 0.0, q1BilledRevenue: 0.0, q1BilledProfit: 0.0, q2BilledSessions: 0, q2BilledHours: 0.0, q2BilledCost: 0.0, q2BilledRevenue: 0.0, q2BilledProfit: 0.0, q3BilledSessions: 0, q3BilledHours: 0.0, q3BilledCost: 0.0, q3BilledRevenue: 0.0, q3BilledProfit: 0.0, q4BilledSessions: 0, q4BilledHours: 0.0, q4BilledCost: 0.0, q4BilledRevenue: 0.0, q4BilledProfit: 0.0, totalBillingSessions: totalBillingSessions, totalBillingHours: totalBillingHours, totalBillingCost: totalBillingCost, totalBillingRevenue: totalBillingRevenue, totalBillingProfit: totalBillingProfit, tutorBillingStatus: tutorBillingStatus)
						self.tutorBillingRows.append(newTutorBillingRow)
						}
					
					}

				//   print("Month: \(prevTutorNum)\(self.tutorBillingRows[prevTutorNum].monthBillingSessions) \(self.tutorBillingRows[prevTutorNum].monthBillingCost) \(self.tutorBillingRows[prevTutorNum].monthBillingRevenue) ")
				prevTutorNum += 1
			}
		} catch {
			print("Error: Could not load \(prevMonth) Tutor Billing Data")
			completionMessage = "Error: Could not load \(prevMonth) Tutor Billing Data"
			completionFlag = false
		}
		
		return(completionFlag,completionMessage)
	}
	
}
