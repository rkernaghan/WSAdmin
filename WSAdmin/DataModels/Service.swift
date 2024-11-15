//
//  Service.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class Service: Identifiable {
	var serviceKey: String
	var serviceTimesheetName: String
	var serviceInvoiceName: String
	var serviceType: ServiceTypeOption
	var serviceBillingType: BillingTypeOption
	var serviceStatus: String
	var serviceCount: Int
	var serviceCost1: Float
	var serviceCost2: Float
	var serviceCost3: Float
	var servicePrice1: Float
	var servicePrice2: Float
	var servicePrice3: Float
	let id = UUID()
	
	init(serviceKey: String, serviceTimesheetName: String, serviceInvoiceName: String, serviceType: ServiceTypeOption, serviceBillingType: BillingTypeOption, serviceStatus: String, serviceCount: Int, serviceCost1: Float, serviceCost2: Float, serviceCost3: Float, servicePrice1: Float, servicePrice2: Float, servicePrice3: Float) {
		self.serviceKey = serviceKey
		self.serviceTimesheetName = serviceTimesheetName
		self.serviceInvoiceName = serviceInvoiceName
		self.serviceType = serviceType
		self.serviceBillingType = serviceBillingType
		self.serviceStatus = serviceStatus
		self.serviceCount = serviceCount
		self.serviceCost1 = serviceCost1
		self.serviceCost2 = serviceCost2
		self.serviceCost3 = serviceCost3
		self.servicePrice1 = servicePrice1
		self.servicePrice2 = servicePrice2
		self.servicePrice3 = servicePrice3
	}

	func markDeleted() {
		serviceStatus = "Deleted"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
//        serviceEndDate = dateFormatter.string(from: Date())
	}
    
	func updateService(timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) {

		self.serviceTimesheetName = timesheetName
		self.serviceInvoiceName = invoiceName
		self.serviceType = serviceType
		self.serviceBillingType = billingType
		self.serviceCount = serviceCount
		
		self.serviceCost1 = cost1
		self.serviceCost2 = cost2
		self.serviceCost3 = cost3
		
		self.servicePrice1 = price1
		self.servicePrice2 = price2
		self.servicePrice3 = price3
	}
    
	func markUnDeleted() {
		serviceStatus = "Unassigned"
//        	serviceEndDate = " "
    }
    
	func increaseServiceUseCount() {
		self.serviceCount += 1
		serviceStatus = "Assigned"
    }
    
	func decreaseServiceUseCount() {
		self.serviceCount -= 1
		if serviceCount == 0 {
			serviceStatus = "Unassigned"
		}
	}
}

