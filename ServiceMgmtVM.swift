//
//  ServiceMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation

@MainActor
@Observable class ServiceMgmtVM  {
  
	var cost1Double: Double = 0.0
	var cost2Double: Double = 0.0
	var cost3Double: Double = 0.0
	var price1Double: Double = 0.0
	var price2Double: Double = 0.0
	var price3Double: Double = 0.0
    
	func addNewService(referenceData: ReferenceData, serviceCode: String, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) async -> (Bool, String) {
		var addResult: Bool = true
		var logMessage: String = ""
		var newServiceKey: String = ""
		
		logMessage = "INFO: Adding new Service - TimesheetName: \(timesheetName), InvoiceName: \(invoiceName), ServiceType: \(serviceType), BillingType: \(billingType), Cost1: \(cost1), Cost2: \(cost2), Cost3: \(cost3), Price1: \(price1), Price2: \(price2), Price3: \(price3)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, newLine: true)
		
		referenceData.dataCounts.increaseTotalServiceCount()
		addResult = await referenceData.dataCounts.saveDataCounts()
		if !addResult {
			logMessage = "ERROR: Could not save Data Counts when adding new Service \(timesheetName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		} else {
			if serviceType == .Base {
				newServiceKey = PgmConstants.serviceBaseKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestServiceKey)
			} else {
				newServiceKey = PgmConstants.serviceSpecialKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestServiceKey)
			}
			
			let newService = Service(serviceKey: newServiceKey, serviceCode: serviceCode, serviceTimesheetName: timesheetName, serviceInvoiceName: invoiceName, serviceType: serviceType, serviceBillingType: billingType, serviceStatus: .ServiceUnassigned, serviceCount: 0, serviceCost1: cost1, serviceCost2: cost2, serviceCost3: cost3, servicePrice1: price1, servicePrice2: price2, servicePrice3: price3)
			
			referenceData.services.addService(newService: newService, referenceData: referenceData)
			
			addResult = await referenceData.services.saveServiceData()
			if !addResult {
				logMessage = "ERROR: Could not save Services data when adding new Service \(timesheetName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			} else {
				let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: newServiceKey)
			
				if String(describing: serviceType) == "Base" {
					if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
						var tutorNum = 0
						while tutorNum < referenceData.tutors.tutorsList.count && addResult {
							if referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorDeleted {
								let newTutorService = TutorService(serviceKey: newServiceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
								addResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
								if !addResult {
									logMessage = "ERROR: Could not save new Base Service \(timesheetName) in Tutor Details sheet for \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .error)
								}
								referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
								referenceData.services.servicesList[serviceNum].serviceStatus = .ServiceAssigned
							}
							tutorNum += 1
						}
						addResult = await referenceData.tutors.saveTutorData()
						if !addResult {
							logMessage = "ERROR: Could not save Tutors data when adding new Base Service \(timesheetName)"
						} else {
							addResult = await referenceData.services.saveServiceData()
							if !addResult {
								logMessage = "ERROR: Could not save Services data when adding new Base Service \(timesheetName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							}
						}
					}
				}
			}
		}
		return(addResult, logMessage)
	}
    
	func validateNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		let (serviceFoundFlag, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetName)
		if serviceFoundFlag {
			validationResult = false
			validationMessage = "WARNING: Service \(timesheetName) Already Exists\n"
		}
		
		let commaFlag = invoiceName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Validation Error: Invoice Name: \(timesheetName) Contains a Comma\n"
		}
		
		return(validationResult, validationMessage)
	}

	func validateUpdatedService(referenceData: ReferenceData, timesheetName: String, originalTimesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		let (serviceFoundFlag, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetName)
		if serviceFoundFlag && originalTimesheetName != timesheetName {
			validationResult = false
			validationMessage = "Validation Error: Service \(timesheetName) Already Exists\n"
		}
		
		let commaFlag = invoiceName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Validation Error: Invoice Name: \(timesheetName) Contains a Comma\n"
		}
		
		return(validationResult, validationMessage)
	}
    
	func updateService(serviceNum: Int, referenceData: ReferenceData, serviceCode: String, timesheetName: String, originalTimesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) async -> (Bool, String) {
		var updateResult: Bool = true
		var logMessage: String = ""
		
		logMessage = "INFO: Updating existing Service - New TimesheetName: \(timesheetName), Original TimesheetName: \(originalTimesheetName), InvoiceName: \(invoiceName), ServiceType: \(serviceType), BillingType: \(billingType), Cost1: \(cost1), Cost2: \(cost2), Cost3: \(cost3), Price1: \(price1), Price2: \(price2), Price3: \(price3)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, newLine: true)

		// Check if the TimesheetName has changed
		if timesheetName != originalTimesheetName {
			
		}
		
		// Update the Service in the Reference Data using the data from the update service screen
		referenceData.services.servicesList[serviceNum].updateService(serviceCode: serviceCode, timesheetName: timesheetName, invoiceName: invoiceName, serviceType: serviceType, billingType: billingType, serviceCount: serviceCount, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
        
		updateResult = await referenceData.services.saveServiceData()
		if !updateResult {
			logMessage = "ERROR: Could not save Service data when updating Service \(originalTimesheetName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		} else {
        
			// Go through each Tutor and check if the updated Services is assigned to that Tutor and if so, update the Service Name
			if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
				var tutorNum = 0
				while tutorNum < referenceData.tutors.tutorsList.count && updateResult {
					if referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorDeleted {
						let (serviceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey)
						if serviceFound {
							updateResult = await referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
							if !updateResult {
								logMessage = "ERROR: Could not save Tutor Details data when updating Service \(originalTimesheetName) for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							}
						}
					}
					tutorNum += 1
				}
			}
		}
		return(updateResult, logMessage)
	}
    

	func deleteService(serviceIndex: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var deleteResult: Bool = true
		var logMessage: String = " "
		
		for objectID in serviceIndex {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
				logMessage = "INFO: Deleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: true)

				if referenceData.services.servicesList[serviceNum].serviceStatus == .ServiceUnassigned {
					referenceData.services.servicesList[serviceNum].markDeleted()
					deleteResult = await referenceData.services.saveServiceData()
					if !deleteResult {
						logMessage = "ERROR: Could not save Services deleting \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					} else {
						referenceData.dataCounts.decreaseActiveServiceCount()
						deleteResult = await referenceData.dataCounts.saveDataCounts()
						if !deleteResult {
							logMessage = "ERROR: Could not update Data Counts deleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					}
				} else {
					logMessage = "ERROR: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) can not be deleted"
					deleteResult = false
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			}
		}
		return(deleteResult, logMessage)
	}
	
	func unDeleteService(serviceIndex: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unDeleteResult: Bool = true
		var logMessage: String = " "
		
		for objectID in serviceIndex {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
				logMessage = "Undeleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: true)

				if referenceData.services.servicesList[serviceNum].serviceStatus == .ServiceDeleted {
					referenceData.services.servicesList[serviceNum].markUnDeleted()
					unDeleteResult = await referenceData.services.saveServiceData()
					if !unDeleteResult {
						logMessage = "ERROR: Could not save Services deleting \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					} else {
						referenceData.dataCounts.increaseActiveServiceCount()
						unDeleteResult = await referenceData.dataCounts.saveDataCounts()
						if !unDeleteResult {
							logMessage = "ERROR: Could not update Data Counts deleting Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					}
				} else {
					logMessage = "ERROR: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) Can not be undeleted as its Status is \(referenceData.services.servicesList[serviceNum].serviceStatus)"
					unDeleteResult = false
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)

				}
			}
		}
		
		return(unDeleteResult, logMessage)
	}
    
}
