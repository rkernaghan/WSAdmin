//
//  StudentBillingRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//

// StudentBillingRow holds an instance of one student's billing attributes for month month.  Data is generated when a CSV file is generated and stored in the StudentBilling spreadsheet.
//
class StudentBillingRow {
	var studentName: String
	var monthSessions: Int
	var monthCost: Float
	var monthRevenue: Float
	var monthProfit: Float
	var totalSessions: Int
	var totalCost: Float
	var totalRevenue: Float
	var totalProfit: Float
	var tutorName: String
	var studentStatus: String
	
	init(studentName: String, monthSessions: Int, monthCost: Float, monthRevenue: Float, monthProfit: Float, totalSessions: Int, totalCost: Float, totalRevenue: Float, totalProfit: Float, tutorName: String, studentStatus: String) {
		self.studentName = studentName
		self.monthSessions = monthSessions
		self.monthCost = monthCost
		self.monthRevenue = monthRevenue
		self.monthProfit = monthProfit
		self.totalSessions = totalSessions
		self.totalCost = totalCost
		self.totalRevenue = totalRevenue
		self.totalProfit = totalProfit
		self.tutorName = tutorName
		self.studentStatus = studentStatus
	}
	
	// Resets a Student's Billed Tutor session, cost, revenue and profit numbers for a month when a Student is billed again after being previously billed that month
	func resetBilledStudentMonth(cost: Float, revenue: Float, profit: Float) {
		self.totalSessions -= 1
		self.totalCost -= cost
		self.totalRevenue -= revenue
		self.totalProfit -= profit
		self.monthSessions -= 1
		self.monthCost -= cost
		self.monthRevenue -= revenue
		self.monthProfit -= profit
	}
}

