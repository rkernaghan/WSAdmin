//
//  BillItems.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//

class BillItem {
    
    var studentName: String
    var serviceDate: String
    var duration: Int
    var serviceName: String
    var notes: String
//    var tutorKey: String
    var tutorName: String
    
    init(studentName: String, serviceDate: String, duration: Int, serviceName: String, notes: String, tutorName: String) {
        self.studentName = studentName
        self.serviceDate = serviceDate
        self.duration = duration
        self.serviceName = serviceName
        self.notes = notes
//        self.tutorKey = tutorKey
        self.tutorName = tutorName
    }
}
