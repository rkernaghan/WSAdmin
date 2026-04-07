//
//  TutorServiceCost.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-07.
//
import Foundation

// This object contains the data and functions for an individual Tutor's rates for a specific Service
//
class TutorServiceCost: Identifiable {
    
    var tutorKey: String			// Unique key for the Tutor
    var tutorName: String			// Tutor name
    var cost1: Double
    var cost2: Double
    var cost3: Double
    var totalCost: Double
    var price1: Double
    var price2: Double
    var price3: Double
    var totalPrice: Double
    let id = UUID()
    
    init(tutorKey: String, tutorName: String, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) {
        self.tutorKey = tutorKey
        self.tutorName = tutorName
        self.cost1 = cost1
        self.cost2 = cost2
        self.cost3 = cost3
        self.totalCost = cost1 + cost2 + cost3
        self.price1 = price1
        self.price2 = price2
        self.price3 = price3
        self.totalPrice = price1 + price2 + price3
    }
 
}
