//
//  BillClients.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//

// BillClient holds attributes about a client being invoiced.  One instance for each client.
class BillClient {
	
	var clientName: String
	var clientEmail: String
	var clientPhone: String
	var billItems = [BillItem]()		// One BillItem for each tutoring session for that Client for the month being billed
	
	init(clientName: String, clientEmail: String, clientPhone: String) {
		self.clientName = clientName
		self.clientEmail = clientEmail
		self.clientPhone = clientPhone
	}
}
