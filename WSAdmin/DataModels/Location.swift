//
//  location.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class Location: Identifiable {
    var locationKey: String
    var locationName: String
    var locationMonthRevenue: Float
    var locationTotalRevenue: Float
    let id = UUID()
    
    init(locationKey: String, locationName: String, locationMonthRevenue: Float, locationTotalRevenue: Float) {
        self.locationKey = locationKey
        self.locationName = locationName
        self.locationMonthRevenue = locationMonthRevenue
        self.locationTotalRevenue = locationTotalRevenue
    }
}