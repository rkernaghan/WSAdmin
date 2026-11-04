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
	
	// Adds a New Service to the system
	// - Increase the Service count and save counts
	// - create the new Service object and save Services
	// - add the new Service to the "Regular" Tutors (not the Specialists
	func addNewService(referenceData: ReferenceData, serviceCode: String, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

		var addResult: Bool = true
		var logMessage: String = ""
		var newServiceKey: String = ""
		
		logMessage = "INFO: Adding new Service - TimesheetName: \(timesheetName), InvoiceName: \(invoiceName), ServiceType: \(serviceType), BillingType: \(billingType), Cost1: \(cost1), Cost2: \(cost2), Cost3: \(cost3), Price1: \(price1), Price2: \(price2), Price3: \(price3)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, newLine: true)
		
		referenceData.dataCounts.increaseTotalServiceCount()
		addResult = await referenceData.dataCounts.saveDataCounts()
		if !addResult {
			logMessage = "ERROR: Could not save Data Counts when adding new Service: \(timesheetName)"
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
				logMessage = "ERROR: Could not save Services data when adding new Service: \(timesheetName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			} else {
				let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: newServiceKey)
				if serviceFound, let serviceNum {
					logMessage = "INFO: Service data for \(timesheetName) saved to Reference Data sheet with key \(referenceData.services.servicesList[serviceNum].serviceKey)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				}

				if String(describing: serviceType) == "Base" {
					if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
						var tutorNum = 0
						while tutorNum < referenceData.tutors.tutorsList.count && addResult {
							if referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorDeleted && referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorSuspended &&  referenceData.tutors.tutorsList[tutorNum].tutorType != .SpecialistTutor {
								
								let tutorDetailsLoaded = await referenceData.ensureTutorDetailsLoaded(tutorID: referenceData.tutors.tutorsList[tutorNum].id)
								if !tutorDetailsLoaded {
									logMessage = "ERROR: could not load Tutor Details for Tutor: \(referenceData.tutors.tutorsList[tutorNum].tutorName) when adding new Service: \(timesheetName)"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .error)
								}
								
								let newTutorService = TutorService(serviceKey: newServiceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
								addResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
								if !addResult {
									logMessage = "ERROR: Could not save new Base Service: \(timesheetName) in Tutor Details sheet for Tutor: \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .error)
								} else {
									logMessage = "INFO: New Base Service: \(timesheetName) added to Tutor: \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .info)
								}
								if serviceFound, let serviceNum {
									referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
									referenceData.services.servicesList[serviceNum].serviceStatus = .ServiceAssigned
								} else {
									logMessage = "ERROR: Could not find new Service: \(timesheetName) with key \(newServiceKey) to increase its use count"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .error)
								}
							}
							tutorNum += 1
						}
						addResult = await referenceData.tutors.saveTutorData()
						if !addResult {
							logMessage = "ERROR: Could not save Tutors data when adding new Base Service: \(timesheetName)"
						} else {
							addResult = await referenceData.services.saveServiceData()
							if !addResult {
								logMessage = "ERROR: Could not save Services data when adding new Base Service: \(timesheetName)"
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
	
	// This function validates the data entered when creating a new Service
	func validateNewService(referenceData: ReferenceData, timesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		let (serviceFoundFlag, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetName)
		if serviceFoundFlag {
			validationResult = false
			validationMessage = "WARNING: Service: \(timesheetName) Already Exists\n"
		}
		
		let commaFlag = invoiceName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Validation Error: Invoice Name: \(timesheetName) Contains a Comma\n"
		}
		
		return(validationResult, validationMessage)
	}

	// This function validates the data entered when updating and existing Service
	func validateUpdatedService(referenceData: ReferenceData, timesheetName: String, originalTimesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		let (serviceFoundFlag, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetName)
		if serviceFoundFlag && originalTimesheetName != timesheetName {
			validationResult = false
			validationMessage = "Validation Error: Service: \(timesheetName) Already Exists\n"
		}
		
		let commaFlag = invoiceName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Validation Error: Invoice Name: \(timesheetName) Contains a Comma\n"
		}
		
		return(validationResult, validationMessage)
	}
    
	// This function updates the data for a specific Service
	func updateService(serviceNum: Int, referenceData: ReferenceData, serviceCode: String, timesheetName: String, originalTimesheetName: String, invoiceName: String, serviceType: ServiceTypeOption, billingType: BillingTypeOption, serviceCount: Int, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

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
			logMessage = "ERROR: Could not save Service data when updating Service: \(originalTimesheetName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		} else {
        
			// Go through each Tutor and check if the updated Services is assigned to that Tutor and if so, update the Service Name
			if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
				
				for tutor in referenceData.tutors.tutorsList {
					guard updateResult else { break }
					
					if tutor.tutorStatus != .TutorDeleted {
						guard await referenceData.ensureTutorDetailsLoaded(tutorID: tutor.id) else {
							logMessage = "ERROR: could not load Tutor Details for Tutor: \(tutor.tutorName) when updating Service: \(timesheetName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
							continue
						}
							
						let (serviceFound, tutorServiceNum) = tutor.findTutorServiceByKey(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey)
						if serviceFound, let tutorServiceNum {
							updateResult = await tutor.updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
							if !updateResult {
								logMessage = "ERROR: Could not save Tutor Details data when updating Service: \(originalTimesheetName) for Tutor: \(tutor.tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							} else {
								logMessage = "INFO: Tutor Service: \(timesheetName) updated for Tutor: \(tutor.tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .info)
							}
						}
					}
				}
			}
		}
		return(updateResult, logMessage)
	}
    
	
	// This function deletes (marks deleted) a set of one or more Services
	func deleteServiceSet(serviceIndex: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

		var deleteResult: Bool = true
		var logMessage: String = " "
		var errorMessage: String = ""
		
		for objectID in serviceIndex {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
				logMessage = "INFO: Deleting Service: \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: true)

				if referenceData.services.servicesList[serviceNum].serviceStatus == .ServiceUnassigned {
					referenceData.services.servicesList[serviceNum].markDeleted()
					let saveServiceResult = await referenceData.services.saveServiceData()
					if !saveServiceResult {
						logMessage = "ERROR: Could not save Services deleting \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
						errorMessage += logMessage
						deleteResult = false
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					} else {
						logMessage = "INFO: Saved Service data deleting \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .info)
						
						referenceData.dataCounts.decreaseActiveServiceCount()
						let saveDataResult = await referenceData.dataCounts.saveDataCounts()
						if !saveDataResult {
							logMessage = "ERROR: Could not update Data Counts deleting Service: \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
							errorMessage += logMessage
							deleteResult = false
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						} else {
							logMessage = "INFO: Service: \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) is deleted"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .info)
						}
					}
				} else {
					logMessage = "WARNING: \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) can not be deleted as its Status is \(referenceData.services.servicesList[serviceNum].serviceStatus)\n\n"
					errorMessage += logMessage
					deleteResult = false
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
				}
			}
		}
		return(deleteResult, errorMessage)
	}
	
	//This function Undeletes a set of one or more Services that were previously marked as Deleted
	func unDeleteServiceSet(serviceIndex: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

		var unDeleteResult: Bool = true
		var logMessage: String = ""
		var errorMessage: String = ""
		
		for objectID in serviceIndex {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
				logMessage = "Undeleting Service: \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: true)

				if referenceData.services.servicesList[serviceNum].serviceStatus == .ServiceDeleted {
					referenceData.services.servicesList[serviceNum].markUnDeleted()
					let saveServiceResult = await referenceData.services.saveServiceData()
					if !saveServiceResult {
						logMessage = "ERROR: Could not save Services deleting \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
						errorMessage += logMessage
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
						unDeleteResult = false
					} else {
						referenceData.dataCounts.increaseActiveServiceCount()
						let saveDataResult = await referenceData.dataCounts.saveDataCounts()
						if !saveDataResult {
							logMessage = "ERROR: Could not update Data Counts deleting Service: \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
							errorMessage += logMessage
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
							unDeleteResult = false
						} else {
							logMessage = "INFO: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) undeleted"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .info)
						}
					}
				} else {
					logMessage = "WARNING: \(referenceData.services.servicesList[serviceNum].serviceInvoiceName) Can not be undeleted as its Status is \(referenceData.services.servicesList[serviceNum].serviceStatus)\n\n"
					errorMessage += logMessage
					unDeleteResult = false
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
				}
			}
		}
		
	return(unDeleteResult, errorMessage)
	}
	
	// This function unassigns a specific Service from all active Tutors
	func unAssignServiceFromAllTutors(serviceNum: Int, referenceData: ReferenceData, tutorMgmtVM: TutorMgmtVM) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}
		
		var unAssignResult: Bool = true
		var logMessage: String = ""
		var errorMessage: String = ""
		
		let serviceKey = referenceData.services.servicesList[serviceNum].serviceKey
		let timesheetName = referenceData.services.servicesList[serviceNum].serviceTimesheetName
		logMessage = "INFO: Unassigning Service: \(timesheetName) from all Tutors"
		print(logMessage)
		await AppLogger.shared.log(logMessage, newLine: true)
				
		if referenceData.services.servicesList[serviceNum].serviceCount > 0 {
			// Go through each Tutor and check if the updated Services is assigned to that Tutor and if so, update the Service Name
			if referenceData.tutors.tutorsList.count > 0 {                             //ensure there are Tutors to assign new Base service to
				
				for (tutorNum, tutor) in referenceData.tutors.tutorsList.enumerated() {
					if tutor.tutorStatus != .TutorDeleted {
						
						guard await referenceData.ensureTutorDetailsLoaded(tutorID: tutor.id) else {
							logMessage = "ERROR: could not load Tutor Details for Tutor: \(tutor.tutorName) when unAssigning Service: \(timesheetName)"
							errorMessage += logMessage + "\n"
							unAssignResult = false
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
							continue
						}
						
						let (serviceFound, tutorServiceNum) = tutor.findTutorServiceByKey(serviceKey: serviceKey)
						if serviceFound, let tutorServiceNum {
							let (tutorUnassignResult, tutorUnassignMessage) = await tutorMgmtVM.unAssignServiceFromTutor(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData)
							if !tutorUnassignResult {
								logMessage = "ERROR: Could not Unassign Service: \(timesheetName) from Tutor: \(tutor.tutorName) - \(tutorUnassignMessage)"
								errorMessage += logMessage + "\n"
								print(logMessage)
								unAssignResult = false
								await AppLogger.shared.log(logMessage, level: .error)
							} else {
								logMessage = "INFO: Tutor Service: \(timesheetName) unAssigned from Tutor: \(tutor.tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .info)
							}
						}
					}
				}
			}
		} else {
			logMessage = "WARNING: Service: \(timesheetName) not assigned to any Tutors\n"
			errorMessage += logMessage + "\n"
			print(logMessage)
			unAssignResult = false
			await AppLogger.shared.log(logMessage, level: .warning)
		}
		return(unAssignResult, errorMessage)
	}
}
