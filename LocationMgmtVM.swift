//
//  LocationMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation
@Observable class LocationMgmtVM  {
    
  
    func addNewLocation(referenceData: ReferenceData, locationName: String) {
        
        let newLocationKey = PgmConstants.locationKeyPrefix + "0034"
        

        let newLocation = Location(locationKey: newLocationKey, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0)
        referenceData.locations.addLocation(newLocation: newLocation)
        
    }
}
