//
//  City.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class City: Identifiable {
    var cityKey: String
    var cityName: String
    var cityMonthRevenue: Float
    var cityTotalRevenue: Float
    let id = UUID()
    
    init(cityKey: String, cityName: String, cityMonthRevenue: Float, cityTotalRevenue: Float) {
        self.cityKey = cityKey
        self.cityName = cityName
        self.cityMonthRevenue = cityMonthRevenue
        self.cityTotalRevenue = cityTotalRevenue
    }
}
