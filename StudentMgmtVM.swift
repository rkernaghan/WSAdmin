//
//  StudentMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class StudentMgmtVM  {
    
    func addNewStudent(referenceData: ReferenceData, studentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, location: String) async {
        var studentBillingCount: Int = 0
        var sheetCells = [[String]]()
        
        referenceData.students.addNewStudent(studentName: studentName, guardianName: guardianName, contactEmail: contactEmail, contactPhone: contactPhone, studentType: studentType, location: location, referenceData: referenceData)
        
        await referenceData.students.saveStudentData()
        await referenceData.dataCounts.increaseTotalStudentCount()
        await referenceData.dataCounts.saveDataCounts()
        
        let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: location)
        referenceData.locations.locationsList[locationNum].increaseStudentCount()
        await referenceData.locations.saveLocationData()
        
        let (prevMonthName, billingYear) = getPrevMonthYear()
        let studentBillingFileName = studentBillingFileNamePrefix + billingYear
   
        let studentBillingMonth = StudentBillingMonth()
        Task {
// Get the File ID of the Billed Student spreadsheet for the year
            let (result, studentBillingFileID) = try await getFileIDAsync(fileName: studentBillingFileName)
 // Read in the Billed Students for the previous month
            await studentBillingMonth.loadStudentBillingMonthAsync(monthName: prevMonthName, studentBillingFileID: studentBillingFileID)
// Add the new Student to Billed Student list for the month
            let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByName(billedStudentName: studentName)
            if billedStudentFound == false {
                studentBillingMonth.addNewBilledStudent(studentName: studentName)
            }
// Save the updated Billed Student list for the month
            await studentBillingMonth.saveStudentBillingData(studentBillingFileID: studentBillingFileID, billingMonth: "Sept")
        }
    }
    
    func updateStudent(referenceData: ReferenceData, studentKey: String, studentName: String, originalStudentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, location: String) async {
        
        let (foundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
        let originalLocation = referenceData.students.studentsList[studentNum].studentLocation
        
        referenceData.students.studentsList[studentNum].studentName = studentName
        referenceData.students.studentsList[studentNum].studentGuardian = guardianName
        referenceData.students.studentsList[studentNum].studentEmail = contactEmail
        referenceData.students.studentsList[studentNum].studentPhone = contactPhone
        referenceData.students.studentsList[studentNum].studentLocation = location
        referenceData.students.studentsList[studentNum].studentType = studentType
        
        await referenceData.students.saveStudentData()
 
        let (originalLocationFound, originalLocationNum) = referenceData.locations.findLocationByName(locationName: originalLocation)
        referenceData.locations.locationsList[originalLocationNum].decreaseStudentCount()
        let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: location)
        referenceData.locations.locationsList[locationNum].increaseStudentCount()
        await referenceData.locations.saveLocationData()
        
        var tutorNum = 0
        while tutorNum < referenceData.tutors.tutorsList.count {
            let (tutorStudentFound, tutorStudentNum) = referenceData.tutors.tutorsList[tutorNum].findTutorStudentByKey(studentKey: studentKey)
            if tutorStudentFound {
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentName = studentName
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientName = guardianName
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientEmail = contactEmail
                referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientPhone = contactPhone
		    await referenceData.tutors.tutorsList[tutorNum].saveTutorStudentData(tutorName: referenceData.tutors.tutorsList[tutorNum].tutorName)
                
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

    func validateUpdatedStudent(referenceData: ReferenceData, studentName: String, originalStudentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, locationName: String) -> (Bool, String) {
        var validationResult: Bool = true
        var validationMessage: String = " "
        
        let (studentFoundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
        if studentFoundFlag && originalStudentName != studentName {
            validationResult = false
            validationMessage = "Error: New Student name \(studentName) already exists"
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
    

    func deleteStudent(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {

        var deleteResult: Bool = true
        var deleteMessage: String = " "
        var result: Bool = true
        var studentBillingFileID: String = ""

        print("deleting Student")
        
        for objectID in indexes {
            if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.students.studentsList[index].studentStatus != "Assigned" && referenceData.students.studentsList[index].studentStatus != "Deleted" {
                    let studentNum = index
                    referenceData.students.studentsList[studentNum].markDeleted()
                    await referenceData.students.saveStudentData()
                    await referenceData.dataCounts.decreaseActiveStudentCount()
// Decrease the counts of Students at the Location
                    let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
                    referenceData.locations.locationsList[locationNum].decreaseStudentCount()
                    await referenceData.locations.saveLocationData()
// Remove Student from Billed Student list for previous month
                    let (prevMonthName, billingYear) = getPrevMonthYear()
                    let studentBillingFileName = studentBillingFileNamePrefix + billingYear
                    
                    let studentBillingMonth = StudentBillingMonth()
 //                   Task {
// Get the File ID of the Billed Student spreadsheet for the year
                    do {
                        (result, studentBillingFileID) = try await getFileIDAsync(fileName: studentBillingFileName)
                    } catch {
                        
                    }
// Read in the Billed Students for the previous month
                        await studentBillingMonth.loadStudentBillingMonthAsync(monthName: prevMonthName, studentBillingFileID: studentBillingFileID)
// Remove the Student from the Billed Student list for the month
                        let studentName = referenceData.students.studentsList[studentNum].studentName
                        let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByName(billedStudentName: studentName)
                        if billedStudentFound != false {
                            studentBillingMonth.deleteBilledStudent(billedStudentNum: billedStudentNum)
                        }
// Save the updated Billed Student list for the month
                        await studentBillingMonth.saveStudentBillingData(studentBillingFileID: studentBillingFileID, billingMonth: "Sept")
//                    }
                    
                } else {
                    deleteMessage = "Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)"
                    print("Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)")
                    deleteResult = false
                }
            }
        }
        return(deleteResult, deleteMessage)
    }
    
    
    
    
    func undeleteStudent(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
        var unDeleteResult: Bool = true
        var unDeleteMessage: String = " "
        
        print("undeleting Student")
        
        for objectID in indexes {
            if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.students.studentsList[index].studentStatus == "Deleted" {
                    let studentNum = index
                    referenceData.students.studentsList[studentNum].markUndeleted()
                    await referenceData.students.saveStudentData()
                    await referenceData.dataCounts.increaseActiveStudentCount()
                    let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
                    referenceData.locations.locationsList[locationNum].increaseStudentCount()
                    await referenceData.locations.saveLocationData()
                    
                } else {
                    unDeleteMessage = "Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)"
                    print("Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)")
                    unDeleteResult = false
                }
            }
        }
        return(unDeleteResult, unDeleteMessage)
    }
    
    func assignStudent(studentNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async {
        
        for objectID in tutorIndex {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                
                let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
            
                referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
                await referenceData.students.saveStudentData()
		    let dateFormatter = DateFormatter()
		    dateFormatter.dateFormat = "yyyy-MM-dd"
		    let assignedDate = dateFormatter.string(from: Date())
		    let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: referenceData.students.studentsList[studentNum].studentName, clientName: referenceData.students.studentsList[studentNum].studentGuardian, clientEmail: referenceData.students.studentsList[studentNum].studentEmail, clientPhone: referenceData.students.studentsList[studentNum].studentPhone, assignedDate: assignedDate)
                await referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
                await referenceData.tutors.saveTutorData()                    // increased Student count
                }
            }
            
        }
    
    
    func unassignStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async {
        
        for objectID in studentIndex {
            if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                
                let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
            
                referenceData.students.studentsList[studentNum].unassignTutor()
                await referenceData.students.saveStudentData()
                
                let (foundFlag, tutorNum) = referenceData.tutors.findTutorByKey(tutorKey: tutorKey)
                if foundFlag {
                    await referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey)
                    await referenceData.tutors.saveTutorData()                    // increased Student count
                }
            }
        }
    }
    
    func unassignTutorStudent(tutorStudentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) async {
        
        for objectID in tutorStudentIndex {
            if let tutorStudentNum = referenceData.tutors.tutorsList[tutorNum].tutorStudents.firstIndex(where: {$0.id == objectID} ) {
                
                let studentKey = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentKey
                let (studentFoundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
                
                referenceData.students.studentsList[studentNum].unassignTutor()
                await referenceData.students.saveStudentData()
                
                await referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: studentKey)
                await referenceData.tutors.saveTutorData()                    // increased Student count
                
            }
            
        }
    }
	
	func suspendStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var suspendResult: Bool = true
		var suspendMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.students.studentsList[studentNum].studentStatus == "Unassigned" {
					referenceData.students.studentsList[studentNum].suspendStudent()
					await referenceData.students.saveStudentData()
				} else {
					suspendResult = false
					suspendMessage += "Student \(referenceData.students.studentsList[studentNum].studentName) Assigned or Deleted \n"
				}
			}
		}
		return(suspendResult, suspendMessage)
	}
	
	func unsuspendStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unsuspendResult: Bool = true
		var unsuspendMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.students.studentsList[studentNum].studentStatus == "Suspended" {
					referenceData.students.studentsList[studentNum].unsuspendStudent()
					await referenceData.students.saveStudentData()
				} else {
					unsuspendResult = false
					unsuspendMessage += "Student \(referenceData.students.studentsList[studentNum].studentName) not Suspended \n"
					
				}
			}
		}
		return(unsuspendResult, unsuspendMessage)
	}
}
