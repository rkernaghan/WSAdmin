//
//  BillingMessage.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-12-12.
//
import Foundation

// WindowMessages is an array to hold a set of Message instances created when generating an invoice for billing.  These are displayed in the BillingProgressView.
//
@Observable class WindowMessages {
	var windowMessageList = [WindowMessageLine]()
	
	func addMessageLine(windowLineText: WindowMessageLine) {
		self.windowMessageList.append(windowLineText)
	}
}

// An individual WindowMessage instance
//
@Observable class WindowMessageLine: Identifiable {
	var windowLineText: String
	let id = UUID()
	
	init(windowLineText: String) {
		self.windowLineText = windowLineText
	}
}

