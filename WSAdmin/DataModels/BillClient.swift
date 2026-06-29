//
//  BillClients.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//

// BillClient holds attributes about a client being invoiced.  One instance for each client.
//
class BillClient {
	
	var clientName: String			// Name of Client (not necessarily Student)
	var clientEmail: String			// Client email
	var clientPhone: String			// Client phone number
	var clientAddress1: String
	var clientAddress2: String
	var clientCity: String
	var clientState: String
	var clientZipCode: String
	var billItems = [BillItem]()		// One BillItem for each tutoring session for that Client for the month being billed
	
	init(clientName: String, clientEmail: String, clientPhone: String, clientAddress1: String, clientAddress2: String, clientCity: String, clientState: String, clientZipCode: String) {
		self.clientName = clientName
		self.clientEmail = clientEmail
		self.clientPhone = clientPhone
		self.clientAddress1 = clientAddress1
		self.clientAddress2 = clientAddress2
		self.clientCity = clientCity
		self.clientState = clientState
		self.clientZipCode = clientZipCode
	}
}
