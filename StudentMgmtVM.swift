//
//  StudentMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class StudentMgmtVM  {
    
    func addNewStudent(referenceData: ReferenceData, studentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, location: String) {
        
        let newStudentKey = PgmConstants.studentKeyPrefix + String(referenceData.dataCounts.highestStudentKey)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: Date())
        let newStudent = Student(studentKey: newStudentKey, studentName: studentName, studentGuardian: guardianName, studentPhone: contactPhone, studentEmail: contactEmail, studentType: studentType, studentStartDate: startDate, studentEndDate: " ", studentStatus: "New", studentTutorKey: " ", studentTutorName: " ", studentLocation: location, studentSessions: 0, studentTotalCost: 0.0, studentTotalRevenue: 0.0, studentTotalProfit: 0.0)
        referenceData.students.loadStudent(newStudent: newStudent, referenceData: referenceData)
        
        referenceData.students.saveStudentData()
        referenceData.dataCounts.increaseTotalStudentCount()
        referenceData.dataCounts.saveDataCounts()
    }
    
    func updateStudent(referenceData: ReferenceData, studentKey: String, studentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, location: String) {
        
        let (foundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
        
        referenceData.students.studentsList[studentNum].studentName = studentName
        referenceData.students.studentsList[studentNum].studentGuardian = guardianName
        referenceData.students.studentsList[studentNum].studentEmail = contactEmail
        referenceData.students.studentsList[studentNum].studentPhone = contactPhone
        referenceData.students.studentsList[studentNum].studentLocation = location
        referenceData.students.studentsList[studentNum].studentType = studentType
        
        referenceData.students.saveStudentData()
        
        var tutorNum = 0
        while tutorNum < referenceData.tutors.tutorsList.count {
            let (tutorStudentFound, tutorStudentNum) = referenceData.tutors.tutorsList[tutorNum].findTutorStudentByKey(studentKey: studentKey)
            if tutorStudentFound {
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentName = studentName
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientName = guardianName
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientEmail = contactEmail
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientPhone = contactPhone
                referenceData.tutors.tutorsList[tutorNum].saveTutorStudents()
                
            }
            tutorNum += 1
        }
    }
    
    func validateNewStudent(referenceData: ReferenceData, studentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, locationName: String) -> (Bool, String) {
        var validationResult: Bool = true
        var validationMessage: String = " "
        
        let (studentFoundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
        if studentFoundFlag {
            validationResult = false
            validationMessage = "Student Name \(studentName) Already Exists"
        }
        
        var commaFlag = studentName.contains(",")
        if commaFlag {
            validationResult = false
            validationMessage = "Error: Student Name: \(studentName) Contains a Comma "
        }
        
        commaFlag = guardianName.contains(",")
        if commaFlag {
            validationResult = false
            validationMessage = "Error: Guadian Name: \(guardianName) Contains a Comma "
        }
        
        let validEmailFlag = isValidEmail(contactEmail)
        if !validEmailFlag {
            validationResult = false
            validationMessage += " Error: Email \(contactEmail) is Not Valid"
        }
        
        let validPhoneFlag = isValidPhone(contactPhone)
        if !validPhoneFlag {
            validationResult = false
            validationMessage += "Error: Phone Number \(contactPhone) Is Not Valid"
        }
    
        if locationName == " " || locationName == "" {
            validationResult = false
            validationMessage += "Error: No Location selected"
        }
        
        return(validationResult, validationMessage)
    }

    func validateUpdatedStudent(referenceData: ReferenceData, studentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, locationName: String) -> (Bool, String) {
        var validationResult: Bool = true
        var validationMessage: String = " "
        
        let (studentFoundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
        if !studentFoundFlag {
            validationResult = false
            validationMessage = "Student Name \(studentName) Does Not Exist"
        }
        
        var commaFlag = studentName.contains(",")
        if commaFlag {
            validationResult = false
            validationMessage = "Error: Student Name: \(studentName) Contains a Comma "
        }
        
        commaFlag = guardianName.contains(",")
        if commaFlag {
            validationResult = false
            validationMessage = "Error: Guadian Name: \(guardianName) Contains a Comma "
        }
        
        let validEmailFlag = isValidEmail(contactEmail)
        if !validEmailFlag {
            validationResult = false
            validationMessage += " Error: Email \(contactEmail) is Not Valid"
        }
        
        let validPhoneFlag = isValidPhone(contactPhone)
        if !validPhoneFlag {
            validationResult = false
            validationMessage += "Error: Phone Number \(contactPhone) Is Not Valid"
        }
    
        return(validationResult, validationMessage)
    }
    
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPhone(_ phone: String)-> Bool {
        let phoneRegex = "(\\([0-9]{3}\\) |[0-9]{3}-)[0-9]{3}-[0-9]{4}"
        let phonePredicate = NSPredicate(format: "SELF MATCHES[c] %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    

    func deleteStudent(indexes: Set<Service.ID>, referenceData: ReferenceData) -> Bool {
        var deleteResult = true
        print("deleting Student")
        
        for objectID in indexes {
            if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.students.studentsList[index].studentStatus != "Assigned" && referenceData.students.studentsList[index].studentStatus != "Deleted" {
                    referenceData.students.studentsList[index].markDeleted()
                    referenceData.students.saveStudentData()
                    referenceData.dataCounts.decreaseActiveStudentCount()
                } else {
                    let buttonMessage = "Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)"
                    print("Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)")
                    deleteResult = false
                }
            }
        }
        return(deleteResult)
    }
    
    func undeleteStudent(indexes: Set<Service.ID>, referenceData: ReferenceData) -> Bool {
        var deleteResult = true
        print("undeleting Student")
        
        for objectID in indexes {
            if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.students.studentsList[index].studentStatus == "Deleted" {
                    referenceData.students.studentsList[index].markUndeleted()
                    referenceData.students.saveStudentData()
                    referenceData.dataCounts.increaseActiveStudentCount()
                } else {
                    let buttonMessage = "Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)"
                    print("Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)")
                    deleteResult = false
                }
            }
        }
        return(deleteResult)
    }
    
    func assignStudent(studentNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) {
        
        for objectID in tutorIndex {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                
                let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
            
                referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
                referenceData.students.saveStudentData()
                
                let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: referenceData.students.studentsList[studentNum].studentName, clientName: referenceData.students.studentsList[studentNum].studentGuardian, clientEmail: referenceData.students.studentsList[studentNum].studentEmail, clientPhone: referenceData.students.studentsList[studentNum].studentPhone )
                referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
                referenceData.tutors.saveTutorData()                    // increased Student count
                }
            }
            
        }
    
    
    func unassignStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) {
        
        for objectID in studentIndex {
            if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                
                let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
            
                referenceData.students.studentsList[studentNum].unassignTutor()
                referenceData.students.saveStudentData()
                
                let (foundFlag, tutorNum) = referenceData.tutors.findTutorByKey(tutorKey: tutorKey)
                if foundFlag {
                    referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey)
                    referenceData.tutors.saveTutorData()                    // increased Student count
                }
            }
            
        }
    }
    
    func unassignTutorStudent(tutorStudentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) {
        
        for objectID in tutorStudentIndex {
            if let tutorStudentNum = referenceData.tutors.tutorsList[tutorNum].tutorStudents.firstIndex(where: {$0.id == objectID} ) {
                
                let studentKey = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentKey
                let (studentFoundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
                
                referenceData.students.studentsList[studentNum].unassignTutor()
                referenceData.students.saveStudentData()
                
                referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: studentKey)
                referenceData.tutors.saveTutorData()                    // increased Student count
                
            }
            
        }
    }
    
}
