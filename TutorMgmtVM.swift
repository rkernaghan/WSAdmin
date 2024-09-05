//
//  TutorMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class TutorMgmtVM  {
    
  
    func addNewTutor(referenceData: ReferenceData, tutorName: String, contactEmail: String, contactPhone: String, maxSessions: String) {
        
        let newTutorKey = PgmConstants.tutorKeyPrefix + "0034"
        let startDate = Date()

        let newTutor = Tutor(tutorKey: newTutorKey, tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorStatus: "New", tutorStartDate: startDate, tutorEndDate: startDate, tutorStudentCount: 0, tutorServiceCount: 0, tutorTotalSessions: 0, tutorTotalCost: 0.0, tutorTotalPrice: 0.0, tutorTotalProfit: 0.0)
        referenceData.tutors.addTutor(newTutor: newTutor)
        
        
    }
    
    
}
