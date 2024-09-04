//
//  StudentsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class StudentsList {
    var studentsList = [Student]()
    
    func addStudent(newStudent: Student) {
        studentsList.append(newStudent)
    }
    
    func printAll() {
        for student in studentsList {
            print ("Student Name is \(student.studentName)")
        }
    }
    
}
