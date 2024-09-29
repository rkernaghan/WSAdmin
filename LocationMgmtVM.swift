//
//  LocationMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation
@Observable class LocationMgmtVM  {
    
  
    func addNewLocation(referenceData: ReferenceData, locationName: String, locationMonthRevenue: Float, locationTotalRevenue: Float) {
        
        let newLocationKey = PgmConstants.locationKeyPrefix + "0034"
        
        let newLocation = Location(locationKey: newLocationKey, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0, locationStudentCount: 0, locationStatus: "Active")
        referenceData.locations.loadLocation(newLocation: newLocation)
        
        referenceData.locations.saveLocationData()
        
        referenceData.dataCounts.increaseTotalLocationCount()
        referenceData.dataCounts.saveDataCounts()
    }
    
    func deleteLocation(indexes: Set<Service.ID>, referenceData: ReferenceData) {
//    func deleteLocation(city: Location, referenceData: ReferenceData) {
        print("deleting Location")
        
       for objectID in indexes {
            if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
                referenceData.locations.locationsList[locationNum].markDeleted()
                referenceData.dataCounts.decreaseActiveLocationCount()
            }
        }
        
        referenceData.locations.saveLocationData()
    }
    
    func undeleteLocation(indexes: Set<Service.ID>, referenceData: ReferenceData) {
//    func deleteLocation(city: Location, referenceData: ReferenceData) {
        print("deleting Location")
        
       for objectID in indexes {
            if let locationNum = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
                referenceData.locations.locationsList[locationNum].markUndeleted()
                referenceData.dataCounts.increaseActiveLocationCount()
            }
        }        
        referenceData.locations.saveLocationData()
    }
    
}
