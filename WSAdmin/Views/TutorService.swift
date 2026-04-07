//
//  TutorService.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-06.
//

import Foundation

@Observable class TutorService: Identifiable {
	
	var serviceKey: String
	var timesheetServiceName: String
	var invoiceServiceName: String
	var billingType: BillingTypeOption
	var cost1: Double
	var cost2: Double
	var cost3: Double
	var totalCost: Double
	var price1: Double
	var price2: Double
	var price3: Double
	var totalPrice: Double
	let id = UUID()
	
	init(serviceKey: String, timesheetName: String, invoiceName: String,  billingType: BillingTypeOption, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) {
		self.serviceKey = serviceKey
		self.timesheetServiceName = timesheetName
		self.invoiceServiceName = invoiceName
		self.billingType = billingType
		self.cost1 = cost1
		self.cost2 = cost2
		self.cost3 = cost3
		self.totalCost = cost1 + cost2 + cost3
		self.price1 = price1
		self.price2 = price2
		self.price3 = price3
		self.totalPrice = price1 + price2 + price3
	}
	
	func computeSessionCostPrice(duration: Int) -> (Double, Double, Double, Double) {
		
		var cost: Double = 0.0
		var price: Double = 0.0
		var quantity: Double = 0.0
		var rate: Double = 0.0
		
		rate = price1 + price2 + price3
		if billingType == .Fixed {
			quantity = 1.0
			cost = cost1 + cost2 + cost3
			price = rate
		} else {
			quantity = Double(duration) / 60.0
			cost = quantity * cost1 + cost2 + cost3
			price = quantity * price1 + price2 + price3
		}
		
		return(quantity, rate, cost, price)
	}
	
}
