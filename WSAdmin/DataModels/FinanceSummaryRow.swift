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
	var monthCost: Float
	var monthRevenue: Float
	var monthProfit: Float
	var yearSessions: Int
	var yearCost: Float
	var yearRevenue: Float
	var yearProfit: Float
	var totalSessions: Int
	var totalCost: Float
	var totalRevenue: Float
	var totalProfit: Float
	let id = UUID()
	
	
	init(year: String, month: String, activeTutorsForMonth: Int, billedTutorsForMonth: Int, billedStudentsForMonth: Int, monthSessions: Int, monthCost: Float, monthRevenue: Float, monthProfit: Float, yearSessions: Int, yearCost: Float, yearRevenue: Float, yearProfit: Float, totalSessions: Int, totalCost: Float, totalRevenue: Float, totalProfit: Float) {
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
	}
	
}
