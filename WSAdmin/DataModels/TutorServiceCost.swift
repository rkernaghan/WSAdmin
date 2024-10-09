//
//  TutorServiceCost.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-07.
//
import Foundation
import GoogleAPIClientForREST

class TutorServiceCost: Identifiable {
    
    var tutorKey: String
    var tutorName: String
    var cost1: Float
    var cost2: Float
    var cost3: Float
    var totalCost: Float
    var price1: Float
    var price2: Float
    var price3: Float
    var totalPrice: Float
    let id = UUID()
    
    init(tutorKey: String, tutorName: String, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) {
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
