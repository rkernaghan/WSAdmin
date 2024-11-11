//
//  LocationMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation

@Observable class LocationMgmtVM  {
    
	func addNewLocation(referenceData: ReferenceData, locationName: String, locationMonthRevenue: Float, locationTotalRevenue: Float) async {
		
		let newLocationKey = PgmConstants.locationKeyPrefix + String(format: "%02d", referenceData.dataCounts.highestLocationKey)
		
		let newLocation = Location(locationKey: newLocationKey, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0, locationStudentCount: 0, locationStatus: "Active")
		referenceData.locations.loadLocation(newLocation: newLocation)
		
		let saveLocationDataResult = await referenceData.locations.saveLocationData()
		
		referenceData.dataCounts.increaseTotalLocationCount()
		referenceData.dataCounts.increaseActiveLocationCount()
		let saveCountsResult = await referenceData.dataCounts.saveDataCounts()
	}
	
	func updateLocation(locationNum: Int, referenceData: ReferenceData, newLocationName: String, originalLocationName: String) async {
		
		referenceData.locations.locationsList[locationNum].updateLocation(locationName: newLocationName)
		let saveLocationDataResult = await referenceData.locations.saveLocationData()
// Update the Location Name for any Students at that Location
		var studentNum = 0
		let studentCount = referenceData.students.studentsList.count
		while studentNum < studentCount {
			if referenceData.students.studentsList[studentNum].studentLocation == originalLocationName {
				referenceData.students.studentsList[studentNum].studentLocation = newLocationName
			}
			studentNum += 1
		}
		
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

//    func deleteLocation(city: Location, referenceData: ReferenceData) {

        
		for objectID in indexes {
			if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.locations.locationsList[locationNum].locationStudentCount == 0 {
					referenceData.locations.locationsList[locationNum].markDeleted()
					referenceData.dataCounts.decreaseActiveLocationCount()
					print("          Information: Deleting Location \(referenceData.locations.locationsList[locationNum].locationName)")
				} else {
					deleteMessage = "Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be deleted, Students assigned"
					print("Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be deleted, Students assigned")
					deleteResult = false
				}
			}
		}
		await referenceData.locations.saveLocationData()
		await referenceData.dataCounts.saveDataCounts()
        
		return(deleteResult, deleteMessage)
	}
    
    func undeleteLocation(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
        var unDeleteResult: Bool = true
        var unDeleteMessage: String = " "
        
        print("undeleting Location")
        
       for objectID in indexes {
            if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.locations.locationsList[locationNum].locationStatus == "Deleted" {
                    referenceData.locations.locationsList[locationNum].markUndeleted()
                    referenceData.dataCounts.increaseActiveLocationCount()
                } else {
                    unDeleteMessage = "Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be undeleted"
                    print("rror: \(referenceData.locations.locationsList[locationNum].locationName) can not be undeleted")
                    unDeleteResult = false
                }
            }
        }
        await referenceData.locations.saveLocationData()
        
        return(unDeleteResult, unDeleteMessage)
    }
    
}
