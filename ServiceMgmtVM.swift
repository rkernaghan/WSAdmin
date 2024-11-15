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
    
	func addNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) async -> (Bool, String) {
		var addResult: Bool = true
		var addMessage: String = ""
		var newServiceKey: String = ""
		
		referenceData.dataCounts.increaseTotalServiceCount()
		addResult = await referenceData.dataCounts.saveDataCounts()
		if !addResult {
			addMessage = "Critical Error: Could not save Data Counts when adding new Service \(timesheetName)"
		} else {
			if serviceType == .Base {
				newServiceKey = PgmConstants.serviceBaseKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestServiceKey)
			} else {
				newServiceKey = PgmConstants.serviceSpecialKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestServiceKey)
			}
			
			let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: "Unassigned", serviceCount: 0, serviceCost1: cost1, serviceCost2: cost2, serviceCost3: cost3, servicePrice1: price1, servicePrice2: price2, servicePrice3: price3)
			
			referenceData.services.loadService(newService: newService, referenceData: referenceData)
			
			addResult = await referenceData.services.saveServiceData()
			if !addResult {
				addMessage = "Critical Error: Could not save Services data when adding new Service \(timesheetName)"
			} else {
				let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: newServiceKey)
			
				if String(describing: serviceType) == "Base" {
					if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
						var tutorNum = 0
						while tutorNum < referenceData.tutors.tutorsList.count && addResult {
							if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
								let newTutorService = TutorService(serviceKey: newServiceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
								addResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
								if !addResult {
									addMessage = "Critical Error: Could not save new Base Service \(timesheetName) in Tutor Details sheet for \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								}
								referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
								referenceData.services.servicesList[serviceNum].serviceStatus = "Assigned"
							}
							tutorNum += 1
						}
						addResult = await referenceData.tutors.saveTutorData()
						if !addResult {
							addMessage = "Critical Error: Could not save Tutors data when adding new Base Service \(timesheetName)"
						} else {
							addResult = await referenceData.services.saveServiceData()
							if !addResult {
								addMessage = "Critical Error: Could not save Services data when adding new Base Service \(timesheetName)"
							}
						}
					}
				}
			}
		}
		return(addResult, addMessage)
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

	func validateUpdatedService(referenceData: ReferenceData, timesheetName: String, originalTimesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		let (serviceFoundFlag, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetName)
		if serviceFoundFlag && originalTimesheetName != timesheetName {
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
    
	func updateService(serviceNum: Int, referenceData: ReferenceData, timesheetName: String, originalTimesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) async -> (Bool, String) {
		var updateResult: Bool = true
		var updateMessage: String = ""
		
		// Check if the TimesheetName has changed
		if timesheetName != originalTimesheetName {
			
		}
		referenceData.services.servicesList[serviceNum].updateService(timesheetName: timesheetName, invoiceName: invoiceName, serviceType: serviceType, billingType: billingType, serviceCount: serviceCount, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
        
		updateResult = await referenceData.services.saveServiceData()
		if !updateResult {
			updateMessage = "Critical Error: Could not save Service data when updating Service \(originalTimesheetName)"
		} else {
        
			// Go through each Tutor and check if the updated Services is assigned to that Tutor and if so, update the Service Name
			if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
				var tutorNum = 0
				while tutorNum < referenceData.tutors.tutorsList.count && updateResult {
					if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
						let (serviceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey)
						if serviceFound {
							updateResult = await referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
							if !updateResult {
								updateMessage = "Critical Error: Could not save Tutor Details data when updating Service \(originalTimesheetName) for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							}
						}
					}
					tutorNum += 1
				}
			}
		}
		return(updateResult, updateMessage)
	}
    

	func deleteService(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var deleteResult: Bool = true
		var deleteMessage: String = " "
		
		for objectID in indexes {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.services.servicesList[serviceNum].serviceStatus == "Unassigned" {
					print("deleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)")
					referenceData.services.servicesList[serviceNum].markDeleted()
					deleteResult = await referenceData.services.saveServiceData()
					if !deleteResult {
						deleteMessage = "Critical Error: Could not save Services deleting \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
					} else {
						referenceData.dataCounts.decreaseActiveServiceCount()
						deleteResult = await referenceData.dataCounts.saveDataCounts()
						if !deleteResult {
							deleteMessage = "Critical Error: Could not update Data Counts deleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
						}
					}
				} else {
					deleteMessage = "Error: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) can not be deleted"
					print("Error: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) Can not be deleted")
					deleteResult = false
				}
			}
		}
		return(deleteResult, deleteMessage)
	}
	
	func unDeleteService(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unDeleteResult: Bool = true
		var unDeleteMessage: String = " "
		
		for objectID in indexes {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.services.servicesList[serviceNum].serviceStatus == "Deleted" {
					print("Undeleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)")
					referenceData.services.servicesList[serviceNum].markUnDeleted()
					unDeleteResult = await referenceData.services.saveServiceData()
					if !unDeleteResult {
						unDeleteMessage = "Critical Error: Could not save Services deleting \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
					} else {
						referenceData.dataCounts.increaseActiveServiceCount()
						unDeleteResult = await referenceData.dataCounts.saveDataCounts()
						if !unDeleteResult {
							unDeleteMessage = "Critical Error: Could not update Data Counts deleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
						}
					}
				} else {
					unDeleteMessage = "Error: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) Can not be undeleted"
					print("Error: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) Can not be undeleted")
					unDeleteResult = false
				}
			}
		}
		
		return(unDeleteResult, unDeleteMessage)
	}
    
}
