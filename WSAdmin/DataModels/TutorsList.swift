//
//  TutorsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class TutorsList {
    var tutorsList = [Tutor]()
    
    func addTutor(newTutor: Tutor) {
        tutorsList.append(newTutor)
    }
    
    func printAll() {
        for tutor in tutorsList {
            print ("Tutor Name is \(tutor.tutorName)")
        }
    }
    
}
