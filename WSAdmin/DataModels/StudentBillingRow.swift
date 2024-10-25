//
//  StudentBillingRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
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
    
    init(studentName: String, monthSessions: Int, monthCost: Float, monthRevenue: Float, monthProfit: Float, totalSessions: Int, totalCost: Float, totalRevenue: Float, totalProfit: Float, tutorName: String) {
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
    }
}

