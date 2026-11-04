//
//  LocationMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation

@MainActor
@Observable class LocationMgmtVM  {
    
	func addNewLocation(referenceData: ReferenceData, locationName: String, locationMonthRevenue: Double, locationTotalRevenue: Double) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

		var saveResult: Bool = true
		var logMessage: String
		
		logMessage = "INFO: Adding new Location: \(locationName)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, newLine: true)
		
		let newLocationKey = PgmConstants.locationKeyPrefix + String(format: "%02d", referenceData.dataCounts.highestLocationKey + 1)
		
		let newLocation = Location(locationKey: newLocationKey, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0, locationStudentCount: 0, locationStatus: .LocationActive)
		referenceData.locations.addLocation(newLocation: newLocation)
		
		saveResult = await referenceData.locations.saveLocationData()
		if !saveResult {
			logMessage = "ERROR: Could not save Location Data when adding new Location: \(locationName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		} else {
			referenceData.dataCounts.increaseTotalLocationCount()
			referenceData.dataCounts.increaseActiveLocationCount()
			saveResult = await referenceData.dataCounts.saveDataCounts()
			if !saveResult {
				logMessage = "ERROR: Could not save Data Counts when adding new Location: \(locationName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			} else {
				logMessage = "INFO: New Location: \(locationName) saved to ReferenceData"
			}
		}
		return(saveResult, logMessage)
	}
	
	// Updates data on a single Location
	func updateLocation(locationNum: Int, referenceData: ReferenceData, newLocationName: String, originalLocationName: String) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

		var updateResult: Bool = true
		var logMessage: String = ""
		
		logMessage = "INFO: Updating existing Location: \(originalLocationName) to new Location Name: \(newLocationName)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, newLine: true)
		
		referenceData.locations.locationsList[locationNum].setLocationName(locationName: newLocationName)
		updateResult = await referenceData.locations.saveLocationData()
		if !updateResult {
			logMessage = "ERROR: Could not save Location Data when updating Location: \(newLocationName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		} else {
			// Update the Location Name for any Students at that Location
			var studentNum = 0
			let studentCount = referenceData.students.studentsList.count
			while studentNum < studentCount {
				if referenceData.students.studentsList[studentNum].studentLocation == originalLocationName {
					referenceData.students.studentsList[studentNum].studentLocation = newLocationName
				}
				studentNum += 1
			}
			updateResult = await referenceData.students.saveStudentData()
			if !updateResult {
				logMessage = "ERROR: Could not update Location name in Student Data"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		}
		return(updateResult, logMessage)
	}
	
	func validateNewLocation(referenceData: ReferenceData, locationName: String) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		if locationName == "" || locationName == " " {
			validationResult = false
			validationMessage += "Validation Error: Location Name is Blank"
		} else {
			
			let (locationFoundFlag, _) = referenceData.locations.findLocationByName(locationName: locationName)
			if locationFoundFlag {
				validationResult = false
				validationMessage += "Validation Error: Location: \(locationName) already exists\n"
			}
			
			let commaFlag = locationName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Validation Error: Location Name: \(locationName) Contains a Comma "
			}
		}
		
		return(validationResult, validationMessage)
	}

	func validateUpdatedLocation(referenceData: ReferenceData, locationName: String) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
//       let (locationFoundFlag, locationNum) = referenceData.locations.findLocationByName(locationName: locationName)
//       if locationFoundFlag {
//           validationResult = false
//           validationMessage += "Error: Location: \(locationName) already exists"
//       }
		
		let commaFlag = locationName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Error: Location Name: \(locationName) Contains a Comma\n"
		}
		
		return(validationResult, validationMessage)
	}
    
	// Mark a set of one or more Locations as Deleted
	func deleteLocationSet(locationIndex: Set<Location.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

		var deleteResult: Bool = true
		var logMessage: String = ""
		var errorMessage: String = ""

		for objectID in locationIndex {
			if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
				logMessage = "INFO: Deleting Location: \(referenceData.locations.locationsList[locationNum].locationName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: true)
				
				if referenceData.locations.locationsList[locationNum].locationStudentCount == 0 {
					referenceData.locations.locationsList[locationNum].markDeleted()
					referenceData.dataCounts.decreaseActiveLocationCount()
				
					let saveLocationResult = await referenceData.locations.saveLocationData()
					if !saveLocationResult {
						logMessage = "ERROR: Could not save Location data deleting Location: \(referenceData.locations.locationsList[locationNum].locationName)"
						errorMessage += logMessage + "\n"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
						deleteResult = false
					} else {
						let saveDataResult = await referenceData.dataCounts.saveDataCounts()
						if !saveDataResult {
							logMessage = "ERROR: Could not save Data Counts deleting Location: \(referenceData.locations.locationsList[locationNum].locationName)"
							errorMessage += logMessage  + "\n"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
							deleteResult = false
						} else {
							logMessage = "INFO: Location: \(referenceData.locations.locationsList[locationNum].locationName) deleted and Data Counts saved"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .info)
						}
					}
				} else {
					logMessage = "WARNING: \(referenceData.locations.locationsList[locationNum].locationName) can not be deleted, Students assigned\n\n"
					errorMessage += logMessage + "\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
					deleteResult = false
				}
			}
		}
        
		return(deleteResult, errorMessage)
	}
    
	// Undelete a set of one or more Locations
	func unDeleteLocationSet(locationIndex: Set<Location.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		
		// Pre-flight optimistic lock check before anything is changed or saved
		if let conflictMessage = await referenceData.preflightReferenceDataLockCheck() {
			await AppLogger.shared.log(conflictMessage, level: .error)
			return (false, conflictMessage)
		}

		var unDeleteResult: Bool = true
		var logMessage: String = ""
		var errorMessage: String = ""
		
		for objectID in locationIndex {
			if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.locations.locationsList[locationNum].locationStatus == .LocationDeleted {
					logMessage = "INFO: Undeleting Location: \(referenceData.locations.locationsList[locationNum].locationName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
					
					referenceData.locations.locationsList[locationNum].markUndeleted()
					referenceData.dataCounts.increaseActiveLocationCount()
					let saveLocationResult = await referenceData.locations.saveLocationData()
					if !saveLocationResult {
						logMessage = "ERROR: Could not save Location data when undeleting Location: \(referenceData.locations.locationsList[locationNum].locationName)"
						errorMessage += logMessage + "\n"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
						unDeleteResult = false
					} else {
						let saveDataResult = await referenceData.dataCounts.saveDataCounts()
						if !saveDataResult {
							logMessage = "ERROR: Could not save Data Counts data when undeleting Location: \(referenceData.locations.locationsList[locationNum].locationName)"
							errorMessage += logMessage + "\n"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
							unDeleteResult = false
						} else {
							logMessage = "INFO: Location: \(referenceData.locations.locationsList[locationNum].locationName) undeleted and Data Counts saved"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .info)
						}
					}
				} else {
					logMessage = "WARNING: \(referenceData.locations.locationsList[locationNum].locationName) can not be undeleted when status is \(referenceData.locations.locationsList[locationNum].locationStatus)\n\n"
					print(logMessage)
					errorMessage += logMessage + "\n"
					await AppLogger.shared.log(logMessage, level: .warning)
					unDeleteResult = false
				}
			}
		}

		return(unDeleteResult, errorMessage)
	}
    
}
