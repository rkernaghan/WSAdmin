//
//  StudentMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class StudentMgmtVM  {
    
    func addNewStudent(referenceData: ReferenceData, studentName: String, guardianName: String, contactEmail: String, contactPhone: String) {
        
        let newStudentKey = PgmConstants.studentKeyPrefix + "0034"
        let startDate = Date()
        let newStudent = Student(studentKey: newStudentKey, studentName: studentName, studentGuardian: guardianName, studentPhone: contactPhone, studentEmail: contactEmail, studentType: " ", studentStartDate: startDate, studentEndData: startDate, studentStatus: " ", studentTutorKey: " ", studentTutorName: " ", studentCity: " ", studentSessions: 0, studentTotalCost: 0.0, studentTotalPrice: 0.0, studentTotalProfit: 0.0)
        referenceData.students.addStudent(newStudent: newStudent)
        
    }
}
