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
    
    func addService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: String, cost2: String, cost3: String, price1: String, price2: String, price3: String) {
            
        let cost1Float = Float(cost1) ?? 0
        let cost2Float = Float(cost2) ?? 0
        let cost3Float = Float(cost3) ?? 0
        let price1Float = Float(price1) ?? 0
        let price2Float = Float(price2) ?? 0
        let price3Float = Float(price3) ?? 0
        
        let newServiceKey = PgmConstants.serviceBaseKeyPrefix + String(format: "%03d", referenceData.dataCounts.highestServiceKey)
 
        let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: "New", serviceCount: serviceCount, serviceCost1: cost1Float, serviceCost2: cost2Float, serviceCost3:  cost3Float, servicePrice1: price1Float, servicePrice2: price2Float, servicePrice3: price3Float)
        
        referenceData.services.loadService(newService: newService, referenceData: referenceData)
    }
    
    func addNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) {
        
        let newServiceKey = PgmConstants.serviceBaseKeyPrefix + String(referenceData.dataCounts.highestServiceKey)
 
        let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: "New", serviceCount: 0, serviceCost1: cost1, serviceCost2: cost2, serviceCost3: cost3, servicePrice1: price1, servicePrice2: price2, servicePrice3: price3)
        
        referenceData.services.loadService(newService: newService, referenceData: referenceData)
        
        referenceData.services.saveServiceData()
        referenceData.dataCounts.increaseTotalServiceCount()
        referenceData.dataCounts.saveDataCounts()
        let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: newServiceKey)
        
        if String(describing: serviceType) == "Base" {
            if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
                var tutorNum = 0
                while tutorNum < referenceData.tutors.tutorsList.count {
                    if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
                        let newTutorService = TutorService(serviceKey: newServiceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
                        referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
                        referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
                    }
                    tutorNum += 1
                }
                referenceData.tutors.saveTutorData()
                referenceData.services.saveServiceData()
            }
        }
    }
    
    func validateNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) -> (Bool, String) {
        var validationResult: Bool = true
        var validationMessage: String = " "
        
        let (serviceFoundFlag, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetName)
        if serviceFoundFlag {
            validationResult = false
            validationMessage = "Error: Service \(timesheetName) Already Exists "
        }
        
        let commaFlag = invoiceName.contains(",")
        if commaFlag {
            validationResult = false
            validationMessage = "Error: Invoice Name: \(timesheetName) Contains a Comma "
        }
        
        return(validationResult, validationMessage)
    }

    func validateUpdatedService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) -> (Bool, String) {
        var validationResult: Bool = true
        var validationMessage: String = " "
        
        let (serviceFoundFlag, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetName)
        if !serviceFoundFlag {
            validationResult = false
            validationMessage = "Error: Service \(timesheetName) Does Not Exist "
        }
        
        let commaFlag = invoiceName.contains(",")
        if commaFlag {
            validationResult = false
            validationMessage = "Error: Invoice Name: \(timesheetName) Contains a Comma "
        }
        
        return(validationResult, validationMessage)
    }
    
    func updateService(serviceNum: Int, referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) {

//        let cost1Float = Float(cost1) ?? 0
//        let cost2Float = Float(cost2) ?? 0
//        let cost3Float = Float(cost3) ?? 0
  //      let price1Float = Float(price1) ?? 0
//        let price2Float = Float(price2) ?? 0
//        let price3Float = Float(price3) ?? 0
        
        referenceData.services.servicesList[serviceNum].updateService(timesheetName: timesheetName, invoiceName: invoiceName, serviceType: serviceType, billingType: billingType, serviceCount: serviceCount, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
        
        referenceData.services.saveServiceData()
        
        if String(describing: serviceType) == "Base" {
            if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
                var tutorNum = 0
                while tutorNum < referenceData.tutors.tutorsList.count {
                    if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
                        let (serviceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey)
                        if serviceFound {
                            referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1Float, cost2: cost2Float, cost3: cost3Float, price1: price1Float, price2: price2Float, price3: price3Float)
                        }
                    }
                    tutorNum += 1
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
