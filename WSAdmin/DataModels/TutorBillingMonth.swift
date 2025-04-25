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
		let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthBillingSessions: 0, monthBillingCost: 0.0, monthBillingRevenue: 0.0, monthBillingProfit: 0.0, totalBillingSessions: 0, totalBillingCost: 0.0, totalBillingRevenue: 0.0, totalBillingProfit: 0.0, tutorStatus: "Active", monthValidatedSessions: 0, monthValidatedCost: 0.0, monthValidatedRevenue: 0.0, monthValidatedProfit: 0.0, totalValidatedSessions: 0, totalValidatedCost: 0.0, totalValidatedRevenue: 0.0, totalValidatedProfit: 0.0)
		self.tutorBillingRows.append(newTutorBillingRow)
	}
	
	func insertBilledTutorRow(tutorBillingRow: TutorBillingRow) {
		self.tutorBillingRows.append(tutorBillingRow)
	}
	
	func deleteBilledTutor(billedTutorNum: Int) {
		self.tutorBillingRows[billedTutorNum].tutorStatus = "Deleted"
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
							loadTutorBillingRows(tutorBillingCount: tutorBillingCount, sheetCells: sheetCells, loadValidatedData: loadValidatedData)
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
		let updateValues = unloadTutorBillingRows(saveValidatedTutorData: saveValidatedTutorData)
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
	func loadTutorBillingRows(tutorBillingCount: Int, sheetCells: [[String]], loadValidatedData: Bool) {
		
		var monthValidatedSessions: Int = 0
		var monthValidatedCost: Float =  0.0
		var monthValidatedRevenue: Float = 0.0
		var monthValidatedProfit: Float = 0.0
		
		var totalValidatedSessions: Int = 0
		var totalValidatedCost: Float = 0.0
		var totalValidatedRevenue: Float = 0.0
		var totalValidatedProfit: Float = 0.0
		
		var tutorBillingIndex = 0
		var rowNumber = 0
		while tutorBillingIndex < tutorBillingCount {
			let tutorName = sheetCells[rowNumber][PgmConstants.tutorBillingTutorCol]
			let monthBillingSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
			let monthBillingCost: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthCostCol]) ?? 0.0
			let monthBillingRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthRevenueCol]) ?? 0.0
			let monthBillingProfit: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthProfitCol]) ?? 0.0
			
			let totalBillingSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingTotalSessionCol]) ?? 0
			let totalBillingCost: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalCostCol]) ?? 0.0
			let totalBillingRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalRevenueCol]) ?? 0.0
			let totalBillingProfit: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalProfitCol]) ?? 0.0
			
			let tutorStatus: String = sheetCells[rowNumber][PgmConstants.tutorBillingStatusCol]
			
			if loadValidatedData {
				monthValidatedSessions = Int(sheetCells[rowNumber][PgmConstants.tutorValidatedMonthSessionCol]) ?? 0
				monthValidatedCost = Float(sheetCells[rowNumber][PgmConstants.tutorValidatedMonthCostCol]) ?? 0.0
				monthValidatedRevenue = Float(sheetCells[rowNumber][PgmConstants.tutorValidatedMonthRevenueCol]) ?? 0.0
				monthValidatedProfit = Float(sheetCells[rowNumber][PgmConstants.tutorValidatedMonthProfitCol]) ?? 0.0
				
				totalValidatedSessions = Int(sheetCells[rowNumber][PgmConstants.tutorValidatedTotalSessionCol]) ?? 0
				totalValidatedCost = Float(sheetCells[rowNumber][PgmConstants.tutorValidatedTotalCostCol]) ?? 0.0
				totalValidatedRevenue = Float(sheetCells[rowNumber][PgmConstants.tutorValidatedTotalRevenueCol]) ?? 0.0
				totalValidatedProfit = Float(sheetCells[rowNumber][PgmConstants.tutorValidatedTotalProfitCol]) ?? 0.0
			}
			
			let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthBillingSessions: monthBillingSessions, monthBillingCost: monthBillingCost, monthBillingRevenue: monthBillingRevenue, monthBillingProfit: monthBillingProfit, totalBillingSessions: totalBillingSessions, totalBillingCost: totalBillingCost, totalBillingRevenue: totalBillingRevenue, totalBillingProfit: totalBillingProfit, tutorStatus: tutorStatus, monthValidatedSessions: monthValidatedSessions, monthValidatedCost: monthValidatedCost, monthValidatedRevenue: monthValidatedRevenue, monthValidatedProfit: monthValidatedProfit, totalValidatedSessions: totalValidatedSessions, totalValidatedCost: totalValidatedCost, totalValidatedRevenue: totalValidatedRevenue, totalValidatedProfit: totalValidatedProfit)
			
			self.insertBilledTutorRow(tutorBillingRow: newTutorBillingRow)
			
			rowNumber += 1
			tutorBillingIndex += 1
		}
	}

//
// This functions takes a Billed Tutor month class and creates an array of strings for writing to a Billed Tutor
// sheet.
//
	func unloadTutorBillingRows(saveValidatedTutorData: Bool) -> [[String]] {
		
		var updateValues = [[String]]()
		var monthValidatedSessions: String = ""
		var monthValidatedCost: String = ""
		var monthValidatedRevenue: String = ""
		var monthValidatedProfit: String = ""
		var totalValidatedSessions: String = ""
		var totalValidatedCost: String = ""
		var totalValidatedRevenue: String = ""
		var totalValidatedProfit: String = ""
		
		let billedTutorCount = tutorBillingRows.count
		var billedTutorNum = 0
		while billedTutorNum < billedTutorCount {
			let tutorName: String = tutorBillingRows[billedTutorNum].tutorName
			let monthBillingSessions: String = String(tutorBillingRows[billedTutorNum].monthBilledSessions)
			let monthBillingCost: String = String(tutorBillingRows[billedTutorNum].monthBilledCost)
			let monthBillingRevenue: String = String(tutorBillingRows[billedTutorNum].monthBilledRevenue)
			let monthBillingProfit: String = String(tutorBillingRows[billedTutorNum].monthBilledProfit)
			let totalBillingSessions: String = String(tutorBillingRows[billedTutorNum].totalBilledSessions)
			let totalBillingCost: String = String(tutorBillingRows[billedTutorNum].totalBilledCost)
			let totalBillingRevenue: String = String(tutorBillingRows[billedTutorNum].totalBilledRevenue)
			let totalBillingProfit: String = String(tutorBillingRows[billedTutorNum].totalBilledProfit)
			let tutorStatus: String = tutorBillingRows[billedTutorNum].tutorStatus
			
			if saveValidatedTutorData {
				monthValidatedSessions = String(tutorBillingRows[billedTutorNum].monthValidatedSessions)
				monthValidatedCost = String(tutorBillingRows[billedTutorNum].monthValidatedCost)
				monthValidatedRevenue = String(tutorBillingRows[billedTutorNum].monthValidatedRevenue)
				monthValidatedProfit = String(tutorBillingRows[billedTutorNum].monthValidatedProfit)
				totalValidatedSessions = String(tutorBillingRows[billedTutorNum].totalValidatedSessions)
				totalValidatedCost = String(tutorBillingRows[billedTutorNum].totalValidatedCost)
				totalValidatedRevenue = String(tutorBillingRows[billedTutorNum].totalValidatedRevenue)
				totalValidatedProfit = String(tutorBillingRows[billedTutorNum].totalValidatedProfit)
			}
			
			updateValues.insert([tutorName, monthBillingSessions, monthBillingCost, monthBillingRevenue, monthBillingProfit, totalBillingSessions, totalBillingCost, totalBillingRevenue, totalBillingProfit, tutorStatus, " ", monthValidatedSessions, monthValidatedCost, monthValidatedRevenue, monthValidatedProfit, totalValidatedSessions, totalValidatedCost, totalValidatedRevenue, totalValidatedProfit], at: billedTutorNum)
			billedTutorNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedTutorNum)
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
	func copyTutorBillingMonth(billingMonth: String, billingMonthYear: String, referenceData: ReferenceData) async -> Bool {
		var completionFlag: Bool = true
		
		let (prevMonth, prevMonthYear) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingMonthYear)
		// Load the Billed Tutor data from the previous month's sheet
		let prevTutorBillingMonth = TutorBillingMonth(monthName: billingMonth)
		let prevMonthTutorFileName = tutorBillingFileNamePrefix + prevMonthYear
		do {
			let (resultFlag, prevMonthTutorFileID) = try await getFileID(fileName: prevMonthTutorFileName)
			if resultFlag {
				completionFlag = await prevTutorBillingMonth.getTutorBillingMonth(monthName: prevMonth, tutorBillingFileID: prevMonthTutorFileID, loadValidatedData: false)
				if completionFlag {
					// Loop through each Tutor from the previous month's Billed Tutor sheet
					var prevTutorNum: Int = 0
					let prevTutorCount = prevTutorBillingMonth.tutorBillingRows.count
					while prevTutorNum < prevTutorCount {
						let tutorName = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].tutorName
						let (foundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
						if foundFlag {
//							if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
								let (foundFlag, billedTutorNum) = self.findBilledTutorByName(billedTutorName: tutorName)
								if !foundFlag {
									let totalBillingSessions = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledSessions
									let totalBillingCost = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledCost
									let totalBillingRevenue = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledRevenue
									let totalBillingProfit = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].totalBilledProfit
									let tutorStatus = prevTutorBillingMonth.tutorBillingRows[prevTutorNum].tutorStatus
									let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthBillingSessions: 0, monthBillingCost: 0.0, monthBillingRevenue: 0.0, monthBillingProfit: 0.0, totalBillingSessions: totalBillingSessions, totalBillingCost: totalBillingCost, totalBillingRevenue: totalBillingRevenue, totalBillingProfit: totalBillingProfit, tutorStatus: tutorStatus,  monthValidatedSessions: 0, monthValidatedCost: 0.0, monthValidatedRevenue: 0.0, monthValidatedProfit: 0.0, totalValidatedSessions: 0, totalValidatedCost: 0.0, totalValidatedRevenue: 0.0, totalValidatedProfit: 0.0)
									self.tutorBillingRows.append(newTutorBillingRow)
								}
//							}
						}
						//   print("Month: \(prevTutorNum)\(self.tutorBillingRows[prevTutorNum].monthBillingSessions) \(self.tutorBillingRows[prevTutorNum].monthBillingCost) \(self.tutorBillingRows[prevTutorNum].monthBillingRevenue) ")
						prevTutorNum += 1
					}
					
				} else {
					print("Error: could not load prev month Billed Tutor month")
					completionFlag = false
				}
			} else {
				print("Error: could not get File ID for \(prevMonthTutorFileName)")
				completionFlag = false
			}
		} catch {
			print("Error: Could not load \(prevMonth) Tutor Billing Data")
			completionFlag = false
		}
		
		return(completionFlag)
		
	}
	
}
