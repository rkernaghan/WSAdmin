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
    
    func addService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: String, billingType: String, cost1: String, cost2: String, cost3: String, price1: String, price2: String, price3: String) {
            
        let cost1Float = Float(cost1) ?? 0
        let cost2Float = Float(cost2) ?? 0
        let cost3Float = Float(cost3) ?? 0
        let price1Float = Float(price1) ?? 0
        let price2Float = Float(price2) ?? 0
        let price3Float = Float(price3) ?? 0
        
        let newServiceKey = PgmConstants.serviceBaseKeyPrefix + String(referenceData.dataCounts.highestServiceKey)
 
        let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: "New", serviceCost1: cost1Float, serviceCost2: cost2Float, serviceCost3:  cost3Float, servicePrice1: price1Float, servicePrice2: price2Float, servicePrice3: price3Float)
        
        referenceData.services.loadService(newService: newService, referenceData: referenceData)
    }
    
    func addNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: String, billingType: String, cost1: String, cost2: String, cost3: String, price1: String, price2: String, price3: String) {
            
        let cost1Float = Float(cost1) ?? 0
        let cost2Float = Float(cost2) ?? 0
        let cost3Float = Float(cost3) ?? 0
        let price1Float = Float(price1) ?? 0
        let price2Float = Float(price2) ?? 0
        let price3Float = Float(price3) ?? 0
        
        let newServiceKey = PgmConstants.serviceBaseKeyPrefix + String(referenceData.dataCounts.highestServiceKey)
 
        let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: "New", serviceCost1: cost1Float, serviceCost2: cost2Float, serviceCost3:  cost3Float, servicePrice1: price1Float, servicePrice2: price2Float, servicePrice3: price3Float)
        
        referenceData.services.loadService(newService: newService, referenceData: referenceData)
        
        referenceData.services.saveServiceData()
        referenceData.dataCounts.increaseTotalServiceCount()
        referenceData.dataCounts.saveDataCounts()
        
        if serviceType == "Base" {
            if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
                var tutorNum = 0
                while tutorNum < referenceData.tutors.tutorsList.count {
                    if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
                        let newTutorService = TutorService(serviceKey: newServiceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1Float, cost2: cost2Float, cost3: cost3Float, price1: price1Float, price2: price2Float, price3: price3Float)
                        referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
                        tutorNum += 1
                    }
                }
            }
        }
    }
    
    func deleteService(indexes: Set<Service.ID>, referenceData: ReferenceData) {
        print("deleting Service")
        
        for objectID in indexes {
            if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
                referenceData.services.servicesList[serviceNum].markDeleted()
                referenceData.services.saveServiceData()
                referenceData.dataCounts.decreaseActiveServiceCount()
            }
        }
    }
    
    func unDeleteService(indexes: Set<Service.ID>, referenceData: ReferenceData) -> Bool {
        var unDeleteResult = true
        print("UnDeleting Service")
        
        for objectID in indexes {
            if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.services.servicesList[serviceNum].serviceStatus == "Deleted" {
                    referenceData.services.servicesList[serviceNum].markUnDeleted()
                    referenceData.services.saveServiceData()
                    referenceData.dataCounts.increaseActiveServiceCount()
                } else {
                    let buttonMessage = "Error: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) Can not be undeleted"
                    print("Error: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) Can not be undeleted")
                    unDeleteResult = false
                }
            }
        }
        return(unDeleteResult)
    }
    
    
    
}
