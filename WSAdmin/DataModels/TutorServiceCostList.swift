//
//  TutorServiceCostList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-07.
//
import Foundation

@Observable class TutorServiceCostList {
    var tutorServiceCostList = [TutorServiceCost]()
    
    init() {
        
    }
    
    func addTutorServiceCost(newTutorServiceCost: TutorServiceCost, referenceData: ReferenceData) {
        
        self.tutorServiceCostList.append(newTutorServiceCost)
    }
    
}
