//
//  LocationMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation

@Observable class LocationMgmtVM  {
    
	func addNewLocation(referenceData: ReferenceData, locationName: String, locationMonthRevenue: Float, locationTotalRevenue: Float) async -> (Bool, String) {
		var saveResult: Bool = true
		var saveMessage: String = ""
		
		let newLocationKey = PgmConstants.locationKeyPrefix + String(format: "%02d", referenceData.dataCounts.highestLocationKey)
		
		let newLocation = Location(locationKey: newLocationKey, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0, locationStudentCount: 0, locationStatus: "Active")
		referenceData.locations.loadLocation(newLocation: newLocation)
		
		saveResult = await referenceData.locations.saveLocationData()
		if !saveResult {
			saveMessage = "Critical Error: Could not save Location Data when adding new Location \(locationName)"
		} else {
			referenceData.dataCounts.increaseTotalLocationCount()
			referenceData.dataCounts.increaseActiveLocationCount()
			saveResult = await referenceData.dataCounts.saveDataCounts()
			if !saveResult {
				saveMessage = "Critical Error: Could not save Data Counts when adding new Location \(locationName)"
			}
		}
		return(saveResult, saveMessage)
	}
	
	func updateLocation(locationNum: Int, referenceData: ReferenceData, newLocationName: String, originalLocationName: String) async -> (Bool, String) {
		var updateResult: Bool = true
		var updateMessage: String = ""
		
		referenceData.locations.locationsList[locationNum].updateLocation(locationName: newLocationName)
		updateResult = await referenceData.locations.saveLocationData()
		if !updateResult {
			updateMessage = "Critical Error: Could not save Location Data when updating Location \(newLocationName)"
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
				updateMessage = "Critical Error: Could not update Location name in Student Data"
			}
		}
		return(updateResult, updateMessage)
	}
	
	func validateNewLocation(referenceData: ReferenceData, locationName: String) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		if locationName == "" || locationName == " " {
			validationResult = false
			validationMessage += "Error: Location Name is Blank"
		} else {
			
			let (locationFoundFlag, locationNum) = referenceData.locations.findLocationByName(locationName: locationName)
			if locationFoundFlag {
				validationResult = false
				validationMessage += "Error: Location \(locationName) already exists"
			}
			
			let commaFlag = locationName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Location Name: \(locationName) Contains a Comma "
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
//           validationMessage += "Error: Location \(locationName) already exists"
//       }
		
		let commaFlag = locationName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Error: Location Name: \(locationName) Contains a Comma "
		}
		
		return(validationResult, validationMessage)
	}
    

	func deleteLocation(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var deleteResult: Bool = true
		var deleteMessage: String = " "

		for objectID in indexes {
			if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.locations.locationsList[locationNum].locationStudentCount == 0 {
					referenceData.locations.locationsList[locationNum].markDeleted()
					referenceData.dataCounts.decreaseActiveLocationCount()
					print("          Information: Deleting Location \(referenceData.locations.locationsList[locationNum].locationName)")
					deleteResult = await referenceData.locations.saveLocationData()
					if !deleteResult {
						deleteMessage = "Critical Error: Could not save Location data"
					} else {
						deleteResult = await referenceData.dataCounts.saveDataCounts()
						if !deleteResult {
							deleteMessage = "Critical Error: Could not save Data Counts data"
						}
					}
				} else {
					deleteMessage = "Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be deleted, Students assigned"
					print("Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be deleted, Students assigned")
					deleteResult = false
				}
			}
		}
        
		return(deleteResult, deleteMessage)
	}
    
	func undeleteLocation(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unDeleteResult: Bool = true
		var unDeleteMessage: String = " "
		
		for objectID in indexes {
			if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.locations.locationsList[locationNum].locationStatus == "Deleted" {
					print("undeleting Location \(referenceData.locations.locationsList[locationNum].locationName)")
					referenceData.locations.locationsList[locationNum].markUndeleted()
					referenceData.dataCounts.increaseActiveLocationCount()
					unDeleteResult = await referenceData.locations.saveLocationData()
					if !unDeleteResult {
						unDeleteMessage = "Critical Error: Could not save Location data when undeleting Location"
					} else {
						unDeleteResult = await referenceData.dataCounts.saveDataCounts()
						if !unDeleteResult {
							unDeleteMessage = "Critical Error: Could not save Data Counts data when undeleting Location"
						}
					}
				} else {
					unDeleteMessage = "Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be undeleted"
					print("rror: \(referenceData.locations.locationsList[locationNum].locationName) can not be undeleted")
					unDeleteResult = false
				}
			}
		}

		
		return(unDeleteResult, unDeleteMessage)
	}
    
}
