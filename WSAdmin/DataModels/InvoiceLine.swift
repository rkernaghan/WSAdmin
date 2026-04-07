//
//  InvoiceLine.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import Foundation

// An InvoiceLine object contains the attributes for billing one tutoring session.
//
struct InvoiceLine: Identifiable {
	var invoiceNum: String			// Invoice number
	var clientName: String			// Client name
	var clientEmail: String			// Client email
	var invoiceDate: String			// Date of the Invoice
	var dueDate: String			// Due date of the invoice
	var terms: String			// Payment terms (e.g. net 7 days)
	var locationName: String		// Student location (city)
	var tutorName: String			// Tutor's name
	var serviceCode: String			// Accounting code for the Service
	var itemName: String			// Name of the tutoring service
	var description: String			// Description of the Service (for Xero: session date
	var quantity: String			// Number of sessions
	var rate: String			// Rate of the session
	var amount: Double			// Invoice amount
	var taxCode: String			// Tax code of the Invoice
	var serviceDate: String			// Date of the tutoring session
	var studentName: String			// Name of the Student
	var accountCode: String			// Accounting code for the invoice
	var brandingTheme: String		// Branding theme
	var cost: Double
	let id = UUID()
	
	init(invoiceNum: String, clientName: String, clientEmail: String, invoiceDate: String, dueDate: String, terms: String, locationName: String, tutorName: String, serviceCode: String, itemName: String, description: String, quantity: String, rate: String, amount: Double, taxCode: String, serviceDate: String, studentName: String, cost: Double, accountCode: String, brandingTheme: String) {
		self.invoiceNum = invoiceNum
		self.clientName = clientName
		self.clientEmail = clientEmail
		self.invoiceDate = invoiceDate
		self.dueDate = dueDate
		self.terms = terms
		self.locationName = locationName
		self.tutorName = tutorName
		self.serviceCode = serviceCode
		self.itemName = itemName
		self.description = description.replacingOccurrences(of: ",", with: "")
		self.quantity = quantity
		self.rate = rate
		self.amount = amount
		self.taxCode = taxCode
		self.serviceDate = serviceDate
		self.studentName = studentName
		self.cost = cost
		self.accountCode = accountCode
		self.brandingTheme = brandingTheme
	}
    
}
