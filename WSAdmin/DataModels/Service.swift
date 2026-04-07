//
//  Service.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

// The Service object contains the data for a Service and functions to manage that data
//
@Observable class Service: Identifiable {
	var serviceKey: String					// Unique key for the Service
	var serviceCode: String					// Accounting service code (not necessarily unique)
	var serviceTimesheetName: String			// Name to show on Tutor Timesheet
	var serviceInvoiceName: String				// Name to show on client invoice
	var serviceType: ServiceTypeOption			// Base (assigned to all Tutors) or Special (only one or more Tutors) Service
	var serviceBillingType: BillingTypeOption		// Fixed (fixed cost per session regardless of time) or Variable (per minute) billing
	var serviceStatus: String				// Unassigned, Assigned, or Deleted
	var serviceCount: Int					// Number of Tutors this Service is assigned to
	var serviceCost1: Double					// Tutoring cost of the service (paid to the tutor)
	var serviceCost2: Double					// Travel cost
	var serviceCost3: Double
	var serviceTotalCost: Double
	var servicePrice1: Double
	var servicePrice2: Double
	var servicePrice3: Double
	var serviceTotalPrice: Double
	let id = UUID()
	
	init(serviceKey: String, serviceCode: String, serviceTimesheetName: String, serviceInvoiceName: String, serviceType: ServiceTypeOption, serviceBillingType: BillingTypeOption, serviceStatus: String, serviceCount: Int, serviceCost1: Double, serviceCost2: Double, serviceCost3: Double, servicePrice1: Double, servicePrice2: Double, servicePrice3: Double) {
		self.serviceKey = serviceKey
		self.serviceCode = serviceCode
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
	func updateService(serviceCode: String, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) {

		self.serviceCode = serviceCode
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

