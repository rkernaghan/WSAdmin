//
//  Student.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class Student: Identifiable {
	var studentKey: String
	var studentName: String
	var studentGuardian: String
	var studentPhone: String
	var studentEmail: String
	var studentType: StudentTypeOption
	var studentStartDate: String
	var studentAssignedUnassignedDate: String
	var studentLastBilledDate: String
	var studentEndDate: String
	var studentStatus: String
	var studentTutorKey: String
	var studentTutorName: String
	var studentLocation: String
	var studentSessions: Int
	var studentTotalCost: Float
	var studentTotalRevenue: Float
	var studentTotalProfit: Float
	let id = UUID()
    
	init(studentKey: String, studentName: String, studentGuardian: String, studentPhone: String, studentEmail: String, studentType: StudentTypeOption, studentStartDate: String, studentAssignedUnassignedDate: String, studentLastBilledDate: String, studentEndDate: String, studentStatus: String, studentTutorKey: String, studentTutorName: String, studentLocation: String, studentSessions: Int, studentTotalCost: Float, studentTotalRevenue: Float, studentTotalProfit: Float) {
		self.studentKey = studentKey
		self.studentName = studentName
		self.studentGuardian = studentGuardian
		self.studentPhone = studentPhone
		self.studentEmail = studentEmail
		self.studentType = studentType
		self.studentStartDate = studentStartDate
		self.studentAssignedUnassignedDate = studentAssignedUnassignedDate
		self.studentLastBilledDate = studentLastBilledDate
		self.studentEndDate = studentEndDate
		self.studentStatus = studentStatus
		self.studentTutorKey = studentTutorKey
		self.studentTutorName = studentTutorName
		self.studentLocation = studentLocation
		self.studentSessions = studentSessions
		self.studentTotalCost = studentTotalCost
		self.studentTotalRevenue = studentTotalRevenue
		self.studentTotalProfit = studentTotalProfit
	}
    
	func markDeleted() {
		self.studentStatus = "Deleted"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		self.studentEndDate = dateFormatter.string(from: Date())
	}
    
	func markUndeleted() {
		self.studentStatus = "Unassigned"
		self.studentEndDate = " "
	}
    
	func suspendStudent() {
		self.studentStatus = "Suspended"
	}
	
	func unsuspendStudent() {
		self.studentStatus = "Unassigned"
	}
	
	func assignTutor(tutorNum: Int, referenceData: ReferenceData) {
		self.studentStatus = "Assigned"
		self.studentTutorKey = referenceData.tutors.tutorsList[tutorNum].tutorKey
		self.studentTutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		self.studentAssignedUnassignedDate = dateFormatter.string(from: Date())
	}

	func unassignTutor() {
		self.studentStatus = "Unassigned"
		self.studentTutorKey = " "
		self.studentTutorName = " "
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		self.studentAssignedUnassignedDate = dateFormatter.string(from: Date())
	}
    
	func resetBillingStats(monthSessions: Int, monthCost: Float, monthRevenue: Float) {
		self.studentSessions -= monthSessions
		self.studentTotalCost -= monthCost
		self.studentTotalRevenue -= monthRevenue
		self.studentTotalProfit -= monthRevenue - monthCost
	}
	
	func updateLastBilledDate(serviceDate: String) {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd/MM/yyyy"
		let date = dateFormatter.date(from: serviceDate)
		if let date = date {
//			dateFormatter.dateFormat = "yyyy/MM/dd"
			self.studentLastBilledDate = dateFormatter.string(from: date)
		}
	}
	
}
