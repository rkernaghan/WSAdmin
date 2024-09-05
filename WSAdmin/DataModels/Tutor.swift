//
//  Tutor.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class Tutor: Identifiable {
    var tutorKey: String
    var tutorName: String
    var tutorEmail: String
    var tutorPhone: String
    var tutorStatus: String
    var tutorStartDate: Date
    var tutorEndDate: Date?
    var tutorStudentCount: Int
    var tutorServiceCount: Int
    var tutorTotalSessions: Int
    var tutorTotalCost: Float
    var tutorTotalPrice: Float
    var tutorTotalProfit: Float
    let ID = UUID()
    
    init(tutorKey: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorStatus: String, tutorStartDate: Date, tutorEndDate: Date?, tutorStudentCount: Int, tutorServiceCount: Int, tutorTotalSessions: Int, tutorTotalCost: Float, tutorTotalPrice: Float, tutorTotalProfit: Float) {
        self.tutorKey = tutorKey
        self.tutorName = tutorName
        self.tutorEmail = tutorEmail
        self.tutorPhone = tutorPhone
        self.tutorStatus = tutorStatus
        self.tutorStartDate = tutorStartDate
        self.tutorEndDate = tutorEndDate
        self.tutorStudentCount = tutorStudentCount
        self.tutorServiceCount = tutorServiceCount
        self.tutorTotalSessions = tutorTotalSessions
        self.tutorTotalCost = tutorTotalCost
        self.tutorTotalPrice = tutorTotalPrice
        self.tutorTotalProfit = tutorTotalProfit
    }
}
