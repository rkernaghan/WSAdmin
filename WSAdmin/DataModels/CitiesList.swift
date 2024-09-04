//
//  CitiesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class CitiesList {
    var citiesList = [City]()
    
    func addCity(newCity: City) {
        citiesList.append(newCity)
    }
    
    func printAll() {
        for city in citiesList {
            print ("City Name is \(city.cityName)")
        }
    }
    
}
