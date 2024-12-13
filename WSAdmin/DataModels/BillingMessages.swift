//
//  BillingMessage.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-12-12.
//
import Foundation

@Observable class BillingMessages {
	var billingMessageList = [BillingMessage]()
	
	func addMessage(billingMessage: BillingMessage) {
		self.billingMessageList.append(billingMessage)
	}
}


@Observable class BillingMessage: Identifiable {
	var billingMessageText: String
	let id = UUID()
	
	init(billingMessageText: String) {
		self.billingMessageText = billingMessageText
	}
}

