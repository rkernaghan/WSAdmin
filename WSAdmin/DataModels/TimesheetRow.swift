//
//  TimesheetLine.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-15.
//

import Foundation

// A TimesheetRow object contains all the fields from a Timesheet row (tutoring session)
class TimesheetRow: Identifiable {
	var studentName: String			// Student name
	var serviceDate: String			// Date the session was conducted
	var duration: Int			// Session duration in minutes
	var timesheetServiceName: String	// Service name from Timesheet
	var notes: String			// Tutor's note for the session (if any)
	var cost: Float				// Cost to be paid to Tutor
	var clientName: String			// Name of Client (not necessarily Student)
	var clientEmail: String			// Client Email
	var clientPhone: String			// Client Phone
	var tutorName: String			// Tutor who conducted session
	let id = UUID()
	
	init(studentName: String, serviceDate: String, duration: Int, timesheetServiceName: String, notes: String, cost: Float, clientName: String, clientEmail: String, clientPhone: String, tutorName: String) {
		self.studentName = studentName
		self.serviceDate = serviceDate
		self.duration = duration
		self.timesheetServiceName = timesheetServiceName
		self.notes = notes
		self.cost = cost
		self.clientName = clientName
		self.clientEmail = clientEmail
		self.clientPhone = clientPhone
		self.tutorName = tutorName
	}
}


