//
//  StudentMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class StudentMgmtVM  {
    
    func addNewStudent(referenceData: ReferenceData, studentName: String, guardianName: String, contactEmail: String, contactPhone: String, location: String) {
        
        let newStudentKey = PgmConstants.studentKeyPrefix + String(referenceData.dataCounts.highestStudentKey)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: Date())
        let newStudent = Student(studentKey: newStudentKey, studentName: studentName, studentGuardian: guardianName, studentPhone: contactPhone, studentEmail: contactEmail, studentType: " ", studentStartDate: startDate, studentEndDate: " ", studentStatus: "New", studentTutorKey: " ", studentTutorName: " ", studentLocation: location, studentSessions: 0, studentTotalCost: 0.0, studentTotalRevenue: 0.0, studentTotalProfit: 0.0)
        referenceData.students.addStudent(newStudent: newStudent, referenceData: referenceData)
        
        referenceData.students.saveStudentData()
        referenceData.dataCounts.increaseStudentCount()
        referenceData.dataCounts.saveDataCounts()
    }
    
    func deleteStudent(indexes: Set<Service.ID>, referenceData: ReferenceData) {
        print("deleting Student")
        
        for objectID in indexes {
            if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                referenceData.students.studentsList[index].markDeleted()
            }
        }
        referenceData.students.saveStudentData()
        referenceData.dataCounts.decreaseStudentCount()
    }
    
}
