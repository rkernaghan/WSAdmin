//
//  TutorService.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-06.
//

import Foundation
import GoogleAPIClientForREST

class TutorService: Identifiable {
    
    var serviceKey: String
    var timesheetServiceName: String
    var invoiceServiceName: String
    var serviceType: String
    var billingType: String
    var cost1: Float
    var cost2: Float
    var cost3: Float
    var totalCost: Float
    var price1: Float
    var price2: Float
    var price3: Float
    var totalPrice: Float
    var id = UUID()
    
    init(serviceKey: String, timesheetServiceName: String, invoiceServiceName: String, serviceType: String, billingType: String, cost1: Float, cost2: Float, cost3: Float, totalCost: Float, price1: Float, price2: Float, price3: Float, totalPrice: Float) {
        self.serviceKey = serviceKey
        self.timesheetServiceName = timesheetServiceName
        self.invoiceServiceName = invoiceServiceName
        self.serviceType = serviceType
        self.billingType = billingType
        self.cost1 = cost1
        self.cost2 = cost2
        self.cost3 = cost3
        self.totalCost = totalCost
        self.price1 = price1
        self.price2 = price2
        self.price3 = price3
        self.totalPrice = totalPrice
    }
 
    
}
