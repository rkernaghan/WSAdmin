//
//  TutorServiceCostList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-07.
//
import Foundation

// This object contains the data and functions to build an array of TutorServiceCost objects, which is used to display a table of each Tutor's rates for a specific service 
@Observable class TutorServiceCostList {
    var tutorServiceCostList = [TutorServiceCost]()
    
    init() {
        
    }
    
	// Adds a TutorServiceCost to the TutorServiceCostList array
    func addTutorServiceCost(newTutorServiceCost: TutorServiceCost, referenceData: ReferenceData) {
        
        self.tutorServiceCostList.append(newTutorServiceCost)
    }
    
}
