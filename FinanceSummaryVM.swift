//
//  FinanceSummaryVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-12-10.
//
import Foundation

@Observable class FinanceSummaryVM {
	
	func buildFinanceSummary() async -> [FinanceSummaryRow] {
		
		// Initialize the running totals to 0
		var financeSummaryArray = [FinanceSummaryRow]()
		
		var monthSessionTotal = 0
		var monthCostTotal: Float = 0.0
		var monthRevenueTotal: Float = 0.0
		var monthProfitTotal: Float = 0.0
		
		var yearSessionTotal = 0
		var yearCostTotal: Float = 0.0
		var yearRevenueTotal: Float = 0.0
		var yearProfitTotal: Float = 0.0

		var totalSessionTotal = 0
		var totalCostTotal: Float = 0.0
		var totalRevenueTotal: Float = 0.0
		var totalProfitTotal: Float = 0.0
		
		var billedMonthTutors: Int = 0
		var activeMonthTutors: Int = 0
		
		var monthIndex = PgmConstants.systemStartMonthIndex
		var yearIndex = PgmConstants.systemStartYearIndex
		var yearNum = yearNumbersArray[yearIndex] 		// Set year number to 2024
		let date = Date()
		let calendar = Calendar.current
		let currentYearNum = calendar.component(.year, from: date)
		let currentMonthNum = calendar.component(.month, from: date)
		var monthCount: Int = 0
		
		// Loop through each year since system started
		while yearNum <= currentYearNum {
			// Get the Google Drive File ID for the Billed Tutor spreadsheet for the year
			let tutorBillingFileName = tutorBillingFileNamePrefix + String(yearNum)
			do {
				let (tutorFileFound, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
				
				if tutorFileFound {
					// Loop through each Tutor Billing Month in the year
					if yearNum == currentYearNum {
						monthCount = currentMonthNum - 1	//assume current month not yet billed
					} else {
						monthCount = 12
					}
					while monthIndex < monthCount {
						// Get the Billed Tutor spreadsheet for the month
						let monthName = monthArray[monthIndex]
						let tutorBillingMonth = TutorBillingMonth(monthName: monthName)
						
						// Get the fileID of the Billed Tutor spreadsheet for the year containing the month's Billed Tutor data
						let readResult = await tutorBillingMonth.getTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID, loadValidatedData: false)
						if !readResult {
							print("Warning: Could not load Tutor Billing Data for \(monthName)")
						} else {
							// For each Tutor Billing Month in the year, count the total number of active Tutors and the total number who had at least one billing session
							
							// Get the number of sessions, total cost, revenue and profit for the month
							
							
							var tutorNum = 0
							let tutorCount = tutorBillingMonth.tutorBillingRows.count
							while tutorNum < tutorCount {
								if tutorBillingMonth.tutorBillingRows[tutorNum].totalBilledSessions > 0 {
//								if tutorBillingMonth.tutorBillingRows[tutorNum].monthBillingSessions > 0 {
									monthSessionTotal += tutorBillingMonth.tutorBillingRows[tutorNum].monthBilledSessions
									monthCostTotal += tutorBillingMonth.tutorBillingRows[tutorNum].monthBilledCost
									monthRevenueTotal += tutorBillingMonth.tutorBillingRows[tutorNum].monthBilledRevenue
									monthProfitTotal += tutorBillingMonth.tutorBillingRows[tutorNum].monthBilledProfit
								}
								
								if tutorBillingMonth.tutorBillingRows[tutorNum].monthBilledSessions > 0 {
									billedMonthTutors += 1
								}
								
								if tutorBillingMonth.tutorBillingRows[tutorNum].tutorStatus == "Active" {
									activeMonthTutors += 1
								}
								tutorNum += 1
								
							}
							yearSessionTotal += monthSessionTotal
							yearCostTotal += monthCostTotal
							yearRevenueTotal += monthRevenueTotal
							yearProfitTotal += monthProfitTotal
							
							totalSessionTotal += monthSessionTotal
							totalCostTotal += monthCostTotal
							totalRevenueTotal += monthRevenueTotal
							totalProfitTotal += monthProfitTotal
							// Add a new month to the array
							let newFinanceSummaryRow = FinanceSummaryRow(year: String(yearNum), month: monthArray[monthIndex], activeTutorsForMonth: activeMonthTutors, billedTutorsForMonth: billedMonthTutors, monthSessions: monthSessionTotal, monthCost: monthCostTotal, monthRevenue: monthRevenueTotal, monthProfit: monthProfitTotal, yearSessions: yearSessionTotal, yearCost: yearCostTotal, yearRevenue: yearRevenueTotal, yearProfit: yearProfitTotal, totalSessions: totalSessionTotal, totalCost: totalCostTotal, totalRevenue: totalRevenueTotal, totalProfit: totalProfitTotal )
							
							financeSummaryArray.append(newFinanceSummaryRow)
							
							billedMonthTutors = 0
							activeMonthTutors = 0
							
							monthSessionTotal = 0
							monthCostTotal = 0.0
							monthRevenueTotal = 0.0
							monthProfitTotal = 0.0
							
							monthIndex += 1
						}
						
					}
					yearNum += 1
					monthIndex = 0
					
					yearSessionTotal = 0
					yearCostTotal = 0
					yearRevenueTotal = 0
					yearProfitTotal = 0
					
				}
			} catch {
				print("Error: could not get FileID of Billed Tutor file \(tutorBillingFileName)")
			}
		}
		return(financeSummaryArray)
		
	}
}

