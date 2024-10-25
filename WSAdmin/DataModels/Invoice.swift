//
//  InvoiceList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import Foundation

@Observable class Invoice: Identifiable {
    var invoiceLines = [InvoiceLine]()
    var isInvoiceLoaded: Bool
    
    init() {
        isInvoiceLoaded = false
    }
    
    func addInvoiceLine(invoiceLine: InvoiceLine) {
        self.invoiceLines.append(invoiceLine)
    }
    
    func printInvoice() {
        print("Print Invoice \(invoiceLines.count)")
        var lineNum = 0
        while lineNum < invoiceLines.count {
            print("Line: \(invoiceLines[lineNum].invoiceNum)  \(invoiceLines[lineNum].clientName)  \(invoiceLines[lineNum].locationName)  \(invoiceLines[lineNum].tutorName)  \(invoiceLines[lineNum].itemName)  \(invoiceLines[lineNum].rate)  \(invoiceLines[lineNum].amount)")
            lineNum += 1
        }
    }
    
}

