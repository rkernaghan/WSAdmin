//
//  TutorBillingRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
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
    
    init(tutorName: String, monthSessions: Int, monthCost: Float, monthRevenue: Float, monthProfit: Float, totalSessions: Int, totalCost: Float, totalRevenue: Float, totalProfit: Float) {
        self.tutorName = tutorName
        self.monthSessions = monthSessions
        self.monthCost = monthCost
        self.monthRevenue = monthRevenue
        self.monthProfit = monthProfit
        self.totalSessions = totalSessions
        self.totalCost = totalCost
        self.totalRevenue = totalRevenue
        self.totalProfit = totalProfit
    }
}
