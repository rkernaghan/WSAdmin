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
	var monthBilledCost: Float
	var monthBilledRevenue: Float
	var monthBilledProfit: Float
	var totalBilledSessions: Int
	var totalBilledCost: Float
	var totalBilledRevenue: Float
	var totalBilledProfit: Float
	var tutorStatus: String
	var monthValidatedSessions: Int
	var monthValidatedCost: Float
	var monthValidatedRevenue: Float
	var monthValidatedProfit: Float
	var totalValidatedSessions: Int
	var totalValidatedCost: Float
	var totalValidatedRevenue: Float
	var totalValidatedProfit: Float
	
	init(tutorName: String, monthBillingSessions: Int, monthBillingCost: Float, monthBillingRevenue: Float, monthBillingProfit: Float, totalBillingSessions: Int, totalBillingCost: Float, totalBillingRevenue: Float, totalBillingProfit: Float, tutorStatus: String, monthValidatedSessions: Int, monthValidatedCost: Float, monthValidatedRevenue: Float, monthValidatedProfit: Float, totalValidatedSessions: Int, totalValidatedCost: Float, totalValidatedRevenue: Float, totalValidatedProfit: Float) {
		self.tutorName = tutorName
		self.monthBilledSessions = monthBillingSessions
		self.monthBilledCost = monthBillingCost
		self.monthBilledRevenue = monthBillingRevenue
		self.monthBilledProfit = monthBillingProfit
		self.totalBilledSessions = totalBillingSessions
		self.totalBilledCost = totalBillingCost
		self.totalBilledRevenue = totalBillingRevenue
		self.totalBilledProfit = totalBillingProfit
		self.tutorStatus = tutorStatus
		
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
		self.totalBilledProfit -= self.monthBilledRevenue - self.monthBilledCost

		self.monthBilledSessions = 0
		self.monthBilledCost = 0.0
		self.monthBilledRevenue = 0.0
		self.monthBilledProfit = 0.0
		
		}
    
}
