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
    
	// This function updates a Student to change Status to Deleted and set the Student's End Date
	func markDeleted() {
		self.studentStatus = "Deleted"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		self.studentEndDate = dateFormatter.string(from: Date())
	}
    
	// This function updates a Student to change Status to Unassigned.
	func markUndeleted() {
		self.studentStatus = "Unassigned"
		self.studentEndDate = " "
	}
	
	// This function changes a Student's Status to Suspended
	func suspendStudent() {
		self.studentStatus = "Suspended"
	}
	
	// This function updates a Student to change Status to Unassigned
	func unsuspendStudent() {
		self.studentStatus = "Unassigned"
	}
	
	// This function updates a Student to assign a Tutor and set the Assigned/Unassigned Date
	func assignTutor(tutorNum: Int, referenceData: ReferenceData) {
		self.studentStatus = "Assigned"
		self.studentTutorKey = referenceData.tutors.tutorsList[tutorNum].tutorKey
		self.studentTutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		self.studentAssignedUnassignedDate = dateFormatter.string(from: Date())
	}
	
	// This function updates a Student to unassigns a Tutor and set the Assigned/Unassigned Date
	func unassignTutor() {
		self.studentStatus = "Unassigned"
		self.studentTutorKey = " "
		self.studentTutorName = " "
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		self.studentAssignedUnassignedDate = dateFormatter.string(from: Date())
	}
    
	// This function updates a Student's billing totals to subtract the current month's Session, Cost, Revenue and Profit totals.  It is used when a Student is rebilled for a month to prevent doubling the months values in the totals
	func resetBillingStats(monthSessions: Int, monthCost: Float, monthRevenue: Float) {
		self.studentSessions -= monthSessions
		self.studentTotalCost -= monthCost
		self.studentTotalRevenue -= monthRevenue
		self.studentTotalProfit -= monthRevenue - monthCost
	}
	
	// This function updates the Student's Last Billed Date.
	func updateLastBilledDate(serviceDate: String) {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM/dd/yyyy"
		let date = dateFormatter.date(from: serviceDate)
		if let date = date {
			dateFormatter.dateFormat = "yyyy/MM/dd"
			let formattedDate = dateFormatter.string(from: date)
			self.studentLastBilledDate = formattedDate
		}
	}
	
}
