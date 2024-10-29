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
        
        await referenceData.locations.saveLocationData()
        
        await referenceData.dataCounts.increaseTotalLocationCount()
        await referenceData.dataCounts.saveDataCounts()
    }
    
    func updateLocation(locationNum: Int, referenceData: ReferenceData, locationName: String, locationMonthRevenue: Float, locationTotalRevenue: Float) async {
        
        referenceData.locations.locationsList[locationNum].updateLocation(locationName: locationName)
        await referenceData.locations.saveLocationData()
        
    }
    
    func validateNewLocation(referenceData: ReferenceData, locationName: String) -> (Bool, String) {
        var validationResult: Bool = true
        var validationMessage: String = " "
        
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
        print("deleting Location")
        
       for objectID in indexes {
            if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.locations.locationsList[locationNum].locationStudentCount == 0 {
                    referenceData.locations.locationsList[locationNum].markDeleted()
                    await referenceData.dataCounts.decreaseActiveLocationCount()
                } else {
                    deleteMessage = "Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be deleted, Students assigned"
                    print("Error: \(referenceData.locations.locationsList[locationNum].locationName) can not be deleted, Students assigned")
                    deleteResult = false
                }
            }
        }
        await referenceData.locations.saveLocationData()
        
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
                    await referenceData.dataCounts.increaseActiveLocationCount()
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
