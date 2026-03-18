//
//  BillItems.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//

// A BillItem holds one row (tutoring session) from a Timesheet as part of an Invoice under a BillClient in a BillArray.

class BillItem {
    
	var studentName: String			// Student Name
	var serviceDate: String			// Date of tutoring session
	var duration: Int			// Duration of tutoring session in minutes
	var timesheetServiceName: String	// Service name from Timesheet
	var invoiceServiceName: String		// Service name for Invoice
	var notes: String			// Tutor's notes for the session
	var cost: Float				// Cost of session (amount for tutor)
	//    var tutorKey: String
	var tutorName: String			// Name of Tutor who did session
	
	init(studentName: String, serviceDate: String, duration: Int, timesheetServiceName: String, invoiceServiceName: String, notes: String, cost: Float, tutorName: String) {
		self.studentName = studentName
		self.serviceDate = serviceDate
		self.duration = duration
		self.timesheetServiceName = timesheetServiceName
		self.invoiceServiceName = invoiceServiceName
		self.notes = notes
		self.cost = cost
		//        self.tutorKey = tutorKey
		self.tutorName = tutorName
    }
}
