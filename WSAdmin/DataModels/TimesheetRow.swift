//
//  TimesheetLine.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-15.
//

import Foundation

class TimesheetRow: Identifiable {
    var studentName: String
    var serviceDate: String
    var duration: Int
    var serviceName: String
    var notes: String
    var cost: Float
    var clientName: String
    var clientEmail: String
    var clientPhone: String
    var tutorName: String
    let id = UUID()
    
    init(studentName: String, serviceDate: String, duration: Int, serviceName: String, notes: String, cost: Float, clientName: String, clientEmail: String, clientPhone: String, tutorName: String) {
        self.studentName = studentName
        self.serviceDate = serviceDate
        self.duration = duration
        self.serviceName = serviceName
        self.notes = notes
        self.cost = cost
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.clientPhone = clientPhone
        self.tutorName = tutorName
    }
}


