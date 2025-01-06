//
//  BillItems.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//

// BillItem holds one row (tutoring session) from a Timesheet.  

class BillItem {
    
	var studentName: String
	var serviceDate: String
	var duration: Int
	var timesheetServiceName: String
	var notes: String
	var cost: Float
	//    var tutorKey: String
	var tutorName: String
	
	init(studentName: String, serviceDate: String, duration: Int, timesheetServiceName: String, notes: String, cost: Float, tutorName: String) {
		self.studentName = studentName
		self.serviceDate = serviceDate
		self.duration = duration
		self.timesheetServiceName = timesheetServiceName
		self.notes = notes
		self.cost = cost
		//        self.tutorKey = tutorKey
		self.tutorName = tutorName
    }
}
