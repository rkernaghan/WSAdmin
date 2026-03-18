//
//  Student.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

// This object contains the data and functions for a Student object
@Observable class Student: Identifiable {
	var studentKey: String				// The unique key for the Student
	var studentName: String				// Student's name
	var studentContactFirstName: String		// Client's first name  (client is not necessarily the student)
	var studentContactLastName: String		// Client's last name
	var studentContactPhone: String			// Client's phone number
	var studentContactEmail: String			// Client's email
	var studentContactZipCode: String		// Client's zip code
	var studentStartDate: String			// Date Student was added to the system
	var studentAssignedUnassignedDate: String	// Date the Student was assigned to or unassigned from a Tutor
	var studentLastBilledDate: String		// Date of Student's last billed tutoring session
	var studentEndDate: String			// Date that the Student was soft deleted
	var studentStatus: String			// Student Status (Unassigned, Assigned, Suspended, Deleted)
	var studentTutorKey: String			// Unique key of assigned Tutor, blank if unassigned
	var studentTutorName: String			// Name of assigned Tutor, blank if unassigned
	var studentLocation: String			// City of Student
	var studentSessions: Int			// Count of total sessions for this Student since Student started (or system initiated)
	var studentTotalCost: Float			// Sum of total tutoring cost for this Student since Student started (or system initiated)
	var studentTotalRevenue: Float			// Sum of total tutoring revenue for this Student since Student started (or system initiated)
	var studentTotalProfit: Float			// Sum of total tutoring profit for this Student since Student started (or system initiated)
	let id = UUID()
    
	init(studentKey: String, studentName: String, studentContactFirstName: String, studentContactLastName: String, studentContactPhone: String, studentContactEmail: String, studentContactZipCode: String, studentStartDate: String, studentAssignedUnassignedDate: String, studentLastBilledDate: String, studentEndDate: String, studentStatus: String, studentTutorKey: String, studentTutorName: String, studentLocation: String, studentSessions: Int, studentTotalCost: Float, studentTotalRevenue: Float, studentTotalProfit: Float) {
		self.studentKey = studentKey
		self.studentName = studentName
		self.studentContactFirstName = studentContactFirstName
		self.studentContactLastName = studentContactLastName
		self.studentContactPhone = studentContactPhone
		self.studentContactEmail = studentContactEmail
		self.studentContactZipCode = studentContactZipCode
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
