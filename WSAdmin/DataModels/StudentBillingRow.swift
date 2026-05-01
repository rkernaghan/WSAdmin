//
//  StudentBillingRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//

// StudentBillingRow holds an instance of one student's billing data attributes for one month.  Data is generated when a CSV file is generated and stored in the StudentBilling spreadsheet.
//
class StudentBillingRow {
	var studentName: String
	var monthBilledSessions: Int
	var monthBilledCost: Double
	var monthBilledRevenue: Double
	var monthBilledProfit: Double
	var totalBilledSessions: Int
	var totalBilledCost: Double
	var totalBilledRevenue: Double
	var totalBilledProfit: Double
	var tutorName: String
	var studentBillingStatus: String
	var monthValidatedSessions: Int
	var monthValidatedCost: Double
	var monthValidatedRevenue: Double
	var monthValidatedProfit: Double
	var totalValidatedSessions: Int
	var totalValidatedCost: Double
	var totalValidatedRevenue: Double
	var totalValidatedProfit: Double
	
	init(studentName: String, monthBillingSessions: Int, monthBillingCost: Double, monthBillingRevenue: Double, monthBillingProfit: Double, totalBillingSessions: Int, totalBillingCost: Double, totalBillingRevenue: Double, totalBillingProfit: Double, tutorName: String, studentBillingStatus: String, monthValidatedSessions: Int, monthValidatedCost: Double, monthValidatedRevenue: Double, monthValidatedProfit: Double, totalValidatedSessions: Int, totalValidatedCost: Double, totalValidatedRevenue: Double, totalValidatedProfit: Double) {
		self.studentName = studentName
		self.monthBilledSessions = monthBillingSessions
		self.monthBilledCost = monthBillingCost
		self.monthBilledRevenue = monthBillingRevenue
		self.monthBilledProfit = monthBillingProfit
		self.totalBilledSessions = totalBillingSessions
		self.totalBilledCost = totalBillingCost
		self.totalBilledRevenue = totalBillingRevenue
		self.totalBilledProfit = totalBillingProfit
		self.tutorName = tutorName
		self.studentBillingStatus = studentBillingStatus
		self.monthValidatedSessions = monthValidatedSessions
		self.monthValidatedCost = monthValidatedCost
		self.monthValidatedRevenue = monthValidatedRevenue
		self.monthValidatedProfit = monthValidatedProfit
		self.totalValidatedSessions = totalValidatedSessions
		self.totalValidatedCost = totalValidatedCost
		self.totalValidatedRevenue = totalValidatedRevenue
		self.totalValidatedProfit = totalValidatedProfit
		
	}
	
	// Resets a Student's Billed Tutor session, cost, revenue and profit numbers for a month when a Student is billed again after being previously billed that month
	func resetBilledStudentMonth(sessions: Int, cost: Double, revenue: Double, profit: Double) {
		
		self.totalBilledSessions -= sessions
		self.totalBilledCost -= cost
		self.totalBilledRevenue -= revenue
		self.totalBilledProfit -= profit
		
		self.monthBilledSessions = 0
		self.monthBilledCost = 0.0
		self.monthBilledRevenue = 0.0
		self.monthBilledProfit = 0.0
	}
}

