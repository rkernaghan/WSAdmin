//
//  ServiceMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation

@Observable class ServiceMgmtVM  {
  
    var cost1Float: Float = 0.0
    var cost2Float: Float = 0.0
    var cost3Float: Float = 0.0
    var price1Float: Float = 0.0
    var price2Float: Float = 0.0
    var price3Float: Float = 0.0
    
    func addNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: String, billingType: String, cost1: String, cost2: String, cost3: String, price1: String, price2: String, price3: String) {
            
        let cost1Float = Float(cost1) ?? 0
        let cost2Float = Float(cost2) ?? 0
        let cost3Float = Float(cost3) ?? 0
        let price1Float = Float(price1) ?? 0
        let price2Float = Float(price2) ?? 0
        let price3Float = Float(price3) ?? 0
        
        let newServiceKey = PgmConstants.serviceBaseKeyPrefix + String(referenceData.dataCounts.highestServiceKey)
 
        let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: "New", serviceCost1: cost1Float, serviceCost2: cost2Float, serviceCost3:  cost3Float, servicePrice1: price1Float, servicePrice2: price2Float, servicePrice3: price3Float)
        
        referenceData.services.addService(newService: newService, referenceData: referenceData)
        
        referenceData.services.saveServiceData()
        referenceData.dataCounts.increaseServiceCount()
        referenceData.dataCounts.saveDataCounts()
        
    }
    
    func deleteService(indexes: Set<Service.ID>, referenceData: ReferenceData) {
        print("deleting Service")
        
        for objectID in indexes {
            if let idx = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
                referenceData.services.servicesList.remove(at: idx)
            }
        }
        
        referenceData.services.saveServiceData()
    }
    
}
