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
	var monthBilledSessions: Int
	var monthBilledCost: Double
	var monthBilledRevenue: Double
	var monthBilledProfit: Double
	var totalBilledSessions: Int
	var totalBilledCost: Double
	var totalBilledRevenue: Double
	var totalBilledProfit: Double
	var tutorBillingStatus: String
	var monthValidatedSessions: Int
	var monthValidatedCost: Double
	var monthValidatedRevenue: Double
	var monthValidatedProfit: Double
	var totalValidatedSessions: Int
	var totalValidatedCost: Double
	var totalValidatedRevenue: Double
	var totalValidatedProfit: Double
	
	init(tutorName: String, monthBillingSessions: Int, monthBillingCost: Double, monthBillingRevenue: Double, monthBillingProfit: Double, totalBillingSessions: Int, totalBillingCost: Double, totalBillingRevenue: Double, totalBillingProfit: Double, tutorBillingStatus: String, monthValidatedSessions: Int, monthValidatedCost: Double, monthValidatedRevenue: Double, monthValidatedProfit: Double, totalValidatedSessions: Int, totalValidatedCost: Double, totalValidatedRevenue: Double, totalValidatedProfit: Double) {
		self.tutorName = tutorName
		self.monthBilledSessions = monthBillingSessions
		self.monthBilledCost = monthBillingCost
		self.monthBilledRevenue = monthBillingRevenue
		self.monthBilledProfit = monthBillingProfit
		self.totalBilledSessions = totalBillingSessions
		self.totalBilledCost = totalBillingCost
		self.totalBilledRevenue = totalBillingRevenue
		self.totalBilledProfit = totalBillingProfit
		self.tutorBillingStatus = tutorBillingStatus
		
		self.monthValidatedSessions = monthValidatedSessions
		self.monthValidatedCost = monthValidatedCost
		self.monthValidatedRevenue = monthValidatedRevenue
		self.monthValidatedProfit = monthValidatedProfit
		self.totalValidatedSessions = totalValidatedSessions
		self.totalValidatedCost = totalValidatedCost
		self.totalValidatedRevenue = totalValidatedRevenue
		self.totalValidatedProfit = totalValidatedProfit
	}
	
	// Resets a Tutors's Billed Tutor session, cost, revenue and profit numbers for a month when a Tutor is billed again after being previously billed that month
	func resetBilledTutorMonth() {
		
		self.totalBilledSessions -= self.monthBilledSessions
		self.totalBilledCost -= self.monthBilledCost
		self.totalBilledRevenue -= self.monthBilledRevenue
		self.totalBilledProfit -= self.monthBilledProfit

		self.monthBilledSessions = 0
		self.monthBilledCost = 0.0
		self.monthBilledRevenue = 0.0
		self.monthBilledProfit = 0.0
		
		}
    
}
