//
//  TutorBillingRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//
// TutorBillingRow holds an instance of one tutor's billing attributes for monthBilling monthBilling.  Data is generated when a CSV file is generated and stored in the TutorBilling spreadsheet.
//
class TutorBillingRow {
	var tutorName: String
	var monthBilledSessions: Int		// Total sessions for the Tutor in current month
	var monthBilledHours: Double		// Total hours for the Tutor for the month
	var monthBilledCost: Double
	var monthBilledRevenue: Double
	var monthBilledProfit: Double
	
	var q1BilledSessions: Int		// Total sessions for the Tutor in first quarter of year
	var q1BilledHours: Double		// Total hours for the tutor in the quarter
	var q1BilledCost: Double		// January to March cost
	var q1BilledRevenue: Double
	var q1BilledProfit: Double

	var q2BilledSessions: Int		// Total sessions for the Tutor in second quarter of year
	var q2BilledHours: Double		// Total hours for the tutor in the quarter
	var q2BilledCost: Double		// April to June cost
	var q2BilledRevenue: Double
	var q2BilledProfit: Double

	var q3BilledSessions: Int		// Total sessions for the Tutor in third quarter of year
	var q3BilledHours: Double		// Total hours for the tutor in the quarter
	var q3BilledCost: Double		// July to September cost
	var q3BilledRevenue: Double
	var q3BilledProfit: Double

	var q4BilledSessions: Int		// Total sessions for the Tutor in fourth quarter of year
	var q4BilledHours: Double		// Total hours for the tutor in the quarter
	var q4BilledCost: Double		// October to December cost
	var q4BilledRevenue: Double
	var q4BilledProfit: Double

	var totalBilledSessions: Int
	var totalBilledHours: Double
	var totalBilledCost: Double
	var totalBilledRevenue: Double
	var totalBilledProfit: Double
	var tutorBillingStatus: TutorBillingStatusOption

	
	init(tutorName: String, monthBillingSessions: Int, monthBillingHours: Double, monthBillingCost: Double, monthBillingRevenue: Double, monthBillingProfit: Double, q1BilledSessions: Int, q1BilledHours: Double, q1BilledCost: Double, q1BilledRevenue: Double, q1BilledProfit: Double, q2BilledSessions: Int, q2BilledHours: Double, q2BilledCost: Double, q2BilledRevenue: Double, q2BilledProfit: Double, q3BilledSessions: Int, q3BilledHours: Double, q3BilledCost: Double, q3BilledRevenue: Double, q3BilledProfit: Double, q4BilledSessions: Int, q4BilledHours: Double, q4BilledCost: Double, q4BilledRevenue: Double, q4BilledProfit: Double, totalBillingSessions: Int, totalBillingHours: Double, totalBillingCost: Double, totalBillingRevenue: Double, totalBillingProfit: Double, tutorBillingStatus: TutorBillingStatusOption) {
		self.tutorName = tutorName
		self.monthBilledSessions = monthBillingSessions
		self.monthBilledHours = monthBillingHours
		self.monthBilledCost = monthBillingCost
		self.monthBilledRevenue = monthBillingRevenue
		self.monthBilledProfit = monthBillingProfit
		
		self.q1BilledSessions = q1BilledSessions
		self.q1BilledHours = q1BilledHours
		self.q1BilledCost = q1BilledCost
		self.q1BilledRevenue = q1BilledRevenue
		self.q1BilledProfit = q1BilledProfit

		self.q2BilledSessions = q2BilledSessions
		self.q2BilledHours = q2BilledHours
		self.q2BilledCost = q2BilledCost
		self.q2BilledRevenue = q2BilledRevenue
		self.q2BilledProfit = q2BilledProfit

		self.q3BilledSessions = q3BilledSessions
		self.q3BilledHours = q3BilledHours
		self.q3BilledCost = q3BilledCost
		self.q3BilledRevenue = q3BilledRevenue
		self.q3BilledProfit = q3BilledProfit

		self.q4BilledSessions = q4BilledSessions
		self.q4BilledHours = q4BilledHours
		self.q4BilledCost = q4BilledCost
		self.q4BilledRevenue = q4BilledRevenue
		self.q4BilledProfit = q4BilledProfit

		self.totalBilledSessions = totalBillingSessions
		self.totalBilledHours = totalBillingHours
		self.totalBilledCost = totalBillingCost
		self.totalBilledRevenue = totalBillingRevenue
		self.totalBilledProfit = totalBillingProfit
		
		self.tutorBillingStatus = tutorBillingStatus
	}
	
	// Resets a Tutors's Billed Tutor session, cost, revenue and profit numbers for a month when a Tutor is billed again after being previously billed that month
	func resetBilledTutorMonth(billingMonth: String) {
		
		let billingQuarter = getQuarterNum(monthName: billingMonth)
		
		self.totalBilledSessions -= self.monthBilledSessions
		self.totalBilledHours -= self.monthBilledHours
		self.totalBilledCost -= self.monthBilledCost
		self.totalBilledRevenue -= self.monthBilledRevenue
		self.totalBilledProfit -= self.monthBilledProfit
		
		switch billingQuarter {
			case 1:
				self.q1BilledSessions -= self.monthBilledSessions
				self.q1BilledHours -= self.monthBilledHours
				self.q1BilledCost -= self.monthBilledCost
				self.q1BilledRevenue -= self.monthBilledRevenue
				self.q1BilledProfit -= self.monthBilledProfit
			case 2:
				self.q2BilledSessions -= self.monthBilledSessions
				self.q2BilledHours -= self.monthBilledHours
				self.q2BilledCost -= self.monthBilledCost
				self.q2BilledRevenue -= self.monthBilledRevenue
				self.q2BilledProfit -= self.monthBilledProfit
			case 3:
				self.q3BilledSessions -= self.monthBilledSessions
				self.q3BilledHours -= self.monthBilledHours
				self.q3BilledCost -= self.monthBilledCost
				self.q3BilledRevenue -= self.monthBilledRevenue
				self.q3BilledProfit -= self.monthBilledProfit
			case 4:
				self.q4BilledSessions -= self.monthBilledSessions
				self.q4BilledHours -= self.monthBilledHours
				self.q4BilledCost -= self.monthBilledCost
				self.q4BilledRevenue -= self.monthBilledRevenue
				self.q4BilledProfit -= self.monthBilledProfit
			default:
				print("Error: Invalid billing quarter in resetBilledTutorMonth for \(billingMonth)")
				break
			}
		
		// Month stats can only be set to zero after using them to reset quarter and total stats
		self.monthBilledSessions = 0
		self.monthBilledHours = 0.0
		self.monthBilledCost = 0.0
		self.monthBilledRevenue = 0.0
		self.monthBilledProfit = 0.0
		}
    
}
