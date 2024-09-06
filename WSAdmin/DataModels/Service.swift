//
//  Service.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class Service: Identifiable {
    var serviceKey: String
    var serviceTimesheetName: String
    var serviceInvoiceName: String
    var serviceType: String
    var serviceBillingType: String
    var serviceStatus: String
    var serviceCost1: Float
    var serviceCost2: Float
    var serviceCost3: Float
    var servicePrice1: Float
    var servicePrice2: Float
    var servicePrice3: Float
    let id = UUID()
    
    init(serviceKey: String, serviceTimesheetName: String, serviceInvoiceName: String, serviceType: String, serviceBillingType: String, serviceStatus: String, serviceCost1: Float, serviceCost2: Float, serviceCost3: Float, servicePrice1: Float, servicePrice2: Float, servicePrice3: Float) {
        self.serviceKey = serviceKey
        self.serviceTimesheetName = serviceTimesheetName
        self.serviceInvoiceName = serviceInvoiceName
        self.serviceType = serviceType
        self.serviceBillingType = serviceBillingType
        self.serviceStatus = serviceStatus
        self.serviceCost1 = serviceCost1
        self.serviceCost2 = serviceCost2
        self.serviceCost3 = serviceCost3
        self.servicePrice1 = servicePrice1
        self.servicePrice2 = servicePrice2
        self.servicePrice3 = servicePrice3
    }
}

