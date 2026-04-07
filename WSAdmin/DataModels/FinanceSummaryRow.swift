//
//  FinanceSummaryRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-12-10.
//
import Foundation

// FinanceSummaryRow is a class to hold a financial summary for one month's billing. Used to hold data for display in the Finance Summary view.
//
class FinanceSummaryRow: Identifiable {
	var year: String
	var month: String
	var activeTutorsForMonth: Int
	var billedTutorsForMonth: Int
	var billedStudentsForMonth: Int
	var monthSessions: Int
	var monthCost: Double
	var monthRevenue: Double
	var monthProfit: Double
	var yearSessions: Int
	var yearCost: Double
	var yearRevenue: Double
	var yearProfit: Double
	var totalSessions: Int
	var totalCost: Double
	var totalRevenue: Double
	var totalProfit: Double
	var monthProfitChange: String
	let id = UUID()
	
	
	init(year: String, month: String, activeTutorsForMonth: Int, billedTutorsForMonth: Int, billedStudentsForMonth: Int, monthSessions: Int, monthCost: Double, monthRevenue: Double, monthProfit: Double, yearSessions: Int, yearCost: Double, yearRevenue: Double, yearProfit: Double, totalSessions: Int, totalCost: Double, totalRevenue: Double, totalProfit: Double, monthProfitChange: String) {
		self.year = year
		self.month = month
		self.activeTutorsForMonth = activeTutorsForMonth
		self.billedTutorsForMonth = billedTutorsForMonth
		self.billedStudentsForMonth = billedStudentsForMonth
		self.monthSessions = monthSessions
		self.monthCost = monthCost
		self.monthRevenue = monthRevenue
		self.monthProfit = monthProfit
		self.yearSessions = yearSessions
		self.yearCost = yearCost
		self.yearRevenue = yearRevenue
		self.yearProfit = yearProfit
		self.totalSessions = totalSessions
		self.totalCost = totalCost
		self.totalRevenue = totalRevenue
		self.totalProfit = totalProfit
		self.monthProfitChange = monthProfitChange
	}
	
}
