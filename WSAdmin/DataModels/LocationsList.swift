//
//  CitiesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class LocationsList {
    var locationsList = [Location]()
    
    func addLocation(newLocation: Location) {
        locationsList.append(newLocation)
    }
    
    func printAll() {
        for location in locationsList {
            print ("location Name is \(location.locationName)")
        }
    }
    
}
