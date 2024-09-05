//
//  Student.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class Student: Identifiable {
    var studentKey: String
    var studentName: String
    var studentGuardian: String
    var studentPhone: String
    var studentEmail: String
    var studentType: String
    var studentStartDate: Date
    var studentEndData: Date?
    var studentStatus: String
    var studentTutorKey: String?
    var studentTutorName: String?
    var studentLocation: String
    var studentSessions: Int
    var studentTotalCost: Float
    var studentTotalPrice: Float
    var studentTotalProfit: Float
    let ID = UUID()
    
    init(studentKey: String, studentName: String, studentGuardian: String, studentPhone: String, studentEmail: String, studentType: String, studentStartDate: Date, studentEndData: Date?, studentStatus: String, studentTutorKey: String?, studentTutorName: String?, studentLocation: String, studentSessions: Int, studentTotalCost: Float, studentTotalPrice: Float, studentTotalProfit: Float) {
        self.studentKey = studentKey
        self.studentName = studentName
        self.studentGuardian = studentGuardian
        self.studentPhone = studentPhone
        self.studentEmail = studentEmail
        self.studentType = studentType
        self.studentStartDate = studentStartDate
        self.studentEndData = studentEndData
        self.studentStatus = studentStatus
        self.studentTutorKey = studentTutorKey
        self.studentTutorName = studentTutorName
        self.studentLocation = studentLocation
        self.studentSessions = studentSessions
        self.studentTotalCost = studentTotalCost
        self.studentTotalPrice = studentTotalPrice
        self.studentTotalProfit = studentTotalProfit
    }
}
