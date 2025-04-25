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
	var monthBilledCost: Float
	var monthBilledRevenue: Float
	var monthBilledProfit: Float
	var totalBilledSessions: Int
	var totalBilledCost: Float
	var totalBilledRevenue: Float
	var totalBilledProfit: Float
	var tutorName: String
	var studentStatus: String
	var monthValidatedSessions: Int
	var monthValidatedCost: Float
	var monthValidatedRevenue: Float
	var monthValidatedProfit: Float
	var totalValidatedSessions: Int
	var totalValidatedCost: Float
	var totalValidatedRevenue: Float
	var totalValidatedProfit: Float
	
	init(studentName: String, monthBillingSessions: Int, monthBillingCost: Float, monthBillingRevenue: Float, monthBillingProfit: Float, totalBillingSessions: Int, totalBillingCost: Float, totalBillingRevenue: Float, totalBillingProfit: Float, tutorName: String, studentStatus: String, monthValidatedSessions: Int, monthValidatedCost: Float, monthValidatedRevenue: Float, monthValidatedProfit: Float, totalValidatedSessions: Int, totalValidatedCost: Float, totalValidatedRevenue: Float, totalValidatedProfit: Float) {
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
		self.studentStatus = studentStatus
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
	func resetBilledStudentMonth(sessions: Int, cost: Float, revenue: Float, profit: Float) {
		
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

