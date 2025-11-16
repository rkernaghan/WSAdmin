//
//  Service.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class Service: Identifiable {
	var serviceKey: String					// Unique key for the Service
	var serviceTimesheetName: String			// Name to show on Tutor Timesheet
	var serviceInvoiceName: String				// Name to show on client invoice
	var serviceType: ServiceTypeOption			// Base or Variable
	var serviceBillingType: BillingTypeOption		// Fixed or Variable
	var serviceStatus: String				// Unassigned, Assigned, or Deleted
	var serviceCount: Int					// Number of Tutors the Service is assigned to
	var serviceCost1: Float
	var serviceCost2: Float
	var serviceCost3: Float
	var serviceTotalCost: Float
	var servicePrice1: Float
	var servicePrice2: Float
	var servicePrice3: Float
	var serviceTotalPrice: Float
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
		self.serviceTotalCost = serviceCost1 + serviceCost2 + serviceCost3
		self.servicePrice1 = servicePrice1
		self.servicePrice2 = servicePrice2
		self.servicePrice3 = servicePrice3
		self.serviceTotalPrice = servicePrice1 + servicePrice2 + servicePrice3
	}

	// This function changes a Service's status to "Deleted" and sets the End Date for the Service
	func markDeleted() {
		serviceStatus = "Deleted"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
//        serviceEndDate = dateFormatter.string(from: Date())
	}
    
	// This function updates the attributes of a Service object
	func updateService(timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) {

		self.serviceTimesheetName = timesheetName
		self.serviceInvoiceName = invoiceName
		self.serviceType = serviceType
		self.serviceBillingType = billingType
		self.serviceCount = serviceCount
		
		self.serviceCost1 = cost1
		self.serviceCost2 = cost2
		self.serviceCost3 = cost3
		self.serviceTotalCost = cost1 + cost2 + cost3
		
		self.servicePrice1 = price1
		self.servicePrice2 = price2
		self.servicePrice3 = price3
		self.serviceTotalPrice = price1 + price2 + price3
	}
	
	// This function changes a Service's Status to "Unassigned"
	func markUnDeleted() {
		serviceStatus = "Unassigned"
//        	serviceEndDate = " "
    }
	
	// This function increases the use counter for a Service (after a Service is assigned to a Tutor).  It sets the Service's Status to Assigned in case it was not previously used
	func increaseServiceUseCount() {
		self.serviceCount += 1
		serviceStatus = "Assigned"
    }
    
	// This function decreases the use counter for a Service (after a Service is unassigned to a Tutor).  If the use count is now zero (assigned to no Tutors), the Service Status
	// is set to "Unassigned"
	func decreaseServiceUseCount() {
		self.serviceCount -= 1
		if serviceCount == 0 {
			serviceStatus = "Unassigned"
		}
	}
}

