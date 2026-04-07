//
//  InvoiceList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import Foundation

// An Invoice onject holds a collection of InvoiceLines and the totals for the invoice.
//
@Observable class Invoice: Identifiable {
	var invoiceLines = [InvoiceLine]()
	var totalCost: Double = 0.0
	var totalRevenue: Double = 0.0
	var totalProfit: Double = 0.0
	var totalSessions: Int = 0
	var monthName: String = ""
	var isInvoiceLoaded: Bool
	
	init() {
		isInvoiceLoaded = false
	}
//
// Adds an InvoiceLine to the Invoice
	func addInvoiceLine(invoiceLine: InvoiceLine) {
		self.invoiceLines.append(invoiceLine)
	}
    
// Prints an invoice to the console
	func printInvoice() {
		print("Print Invoice \(invoiceLines.count)")
		var lineNum = 0
		while lineNum < invoiceLines.count {
			print("Line: \(invoiceLines[lineNum].invoiceNum)  \(invoiceLines[lineNum].clientName)  \(invoiceLines[lineNum].locationName)  \(invoiceLines[lineNum].tutorName)  \(invoiceLines[lineNum].itemName)  \(invoiceLines[lineNum].rate)  \(invoiceLines[lineNum].amount)")
			lineNum += 1
		}
	}
    
}


