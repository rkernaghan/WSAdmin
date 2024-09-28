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
        
        let newLocation = Location(locationKey: newLocationKey, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0, locationStudentCount: 0)
        referenceData.locations.loadLocation(newLocation: newLocation)
        
        referenceData.locations.saveLocationData()
    }
    
    func deleteLocation(indexes: Set<Service.ID>, referenceData: ReferenceData) {
//    func deleteLocation(city: Location, referenceData: ReferenceData) {
        print("deleting Location")
        
       for objectID in indexes {
            if let idx = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
                referenceData.locations.locationsList.remove(at: idx)
            }
        }
        
        referenceData.locations.saveLocationData()
    }
    
}
