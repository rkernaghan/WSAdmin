//
//  InvoiceLine.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import Foundation

struct InvoiceLine: Identifiable {
    var invoiceNum: String
    var clientName: String
    var clientEmail: String
    var invoiceDate: String
    var dueDate: String
    var terms: String
    var locationName: String
    var tutorName: String
    var itemName: String
    var description: String
    var quantity: String
    var rate: String
    var amount: Float
    var taxCode: String
    var serviceDate: String
    var studentName: String
    var cost: Float
    let id = UUID()
    
    init(invoiceNum: String, clientName: String, clientEmail: String, invoiceDate: String, dueDate: String, terms: String, locationName: String, tutorName: String, itemName: String, description: String, quantity: String, rate: String, amount: Float, taxCode: String, serviceDate: String, studentName: String, cost: Float) {
        self.invoiceNum = invoiceNum
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.invoiceDate = invoiceDate
        self.dueDate = dueDate
        self.terms = terms
        self.locationName = locationName
        self.tutorName = tutorName
        self.itemName = itemName
        self.description = description
        self.quantity = quantity
        self.rate = rate
        self.amount = amount
        self.taxCode = taxCode
        self.serviceDate = serviceDate
        self.studentName = studentName
        self.cost = cost
    }
    
}
