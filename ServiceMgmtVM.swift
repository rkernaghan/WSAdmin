//
//  ServiceMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation

@Observable class ServiceMgmtVM  {
    
  
    func addNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: String, billingType: String) {
        
        let newServiceKey = PgmConstants.serviceBaseKeyPrefix + "0034"
 
        let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: "New", serviceCost1: 0.0, serviceCost2: 0.0, serviceCost3: 0.0, servicePrice1: 0.0, servicePrice2: 0.0, servicePrice3: 0.0)
        referenceData.services.addService(newService: newService)
        
    }
}
