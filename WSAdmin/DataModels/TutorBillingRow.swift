//
//  TutorBillingRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//
// TutorBillingRow holds an instance of one tutor's billing attributes for month month.  Data is generated when a CSV file is generated and stored in the TutorBilling spreadsheet.
//
class TutorBillingRow {
	var tutorName: String
	var monthSessions: Int
	var monthCost: Float
	var monthRevenue: Float
	var monthProfit: Float
	var totalSessions: Int
	var totalCost: Float
	var totalRevenue: Float
	var totalProfit: Float
	var tutorStatus: String
	
	init(tutorName: String, monthSessions: Int, monthCost: Float, monthRevenue: Float, monthProfit: Float, totalSessions: Int, totalCost: Float, totalRevenue: Float, totalProfit: Float, tutorStatus: String) {
		self.tutorName = tutorName
		self.monthSessions = monthSessions
		self.monthCost = monthCost
		self.monthRevenue = monthRevenue
		self.monthProfit = monthProfit
		self.totalSessions = totalSessions
		self.totalCost = totalCost
		self.totalRevenue = totalRevenue
		self.totalProfit = totalProfit
		self.tutorStatus = tutorStatus
	}
	
	// Resets a Tutors's Billed Tutor session, cost, revenue and profit numbers for a month when a Tutor is billed again after being previously billed that month
	func resetBilledTutorMonth(cost: Float, revenue: Float, profit: Float) {
		
		self.monthSessions -= 1
		self.monthCost -= cost
		self.monthRevenue -= revenue
		self.monthProfit -= profit
		
		self.totalSessions -= 1
		self.totalCost -= cost
		self.totalRevenue -= revenue
		self.totalProfit -= profit
	}
    
}
