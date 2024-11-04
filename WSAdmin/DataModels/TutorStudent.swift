//
//  TutorStudent.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-06.
//

import Foundation

class TutorStudent: Identifiable {
    
	var studentKey: String
	var studentName: String
	var clientName: String
	var clientEmail: String
	var clientPhone: String
	var assignedDate: String
	let id = UUID()
    
	init(studentKey: String, studentName: String, clientName: String, clientEmail: String, clientPhone: String, assignedDate: String) {
		self.studentKey = studentKey
		self.studentName = studentName
		self.clientName = clientName
		self.clientEmail = clientEmail
		self.clientPhone = clientPhone
		self.assignedDate = assignedDate
    }
    
    
}
