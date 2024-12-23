//
//  BillingMessage.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-12-12.
//
import Foundation

// BillingMessages is an array to hold a set of BillingMessage instances created when generating an invoice for billing.  These are displayed in the BillingProgressView.
//
@Observable class BillingMessages {
	var billingMessageList = [BillingMessage]()
	
	func addMessage(billingMessage: BillingMessage) {
		self.billingMessageList.append(billingMessage)
	}
}

// An individual BillingMessage instance
//
@Observable class BillingMessage: Identifiable {
	var billingMessageText: String
	let id = UUID()
	
	init(billingMessageText: String) {
		self.billingMessageText = billingMessageText
	}
}

