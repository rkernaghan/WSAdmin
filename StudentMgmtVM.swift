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
    
    func updateStudent(referenceData: ReferenceData, studentKey: String, studentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, location: String) async {
        
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
                await referenceData.tutors.tutorsList[tutorNum].saveTutorStudentData()
                
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
// Add the new Student to Billed Student list for the month
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
    
    func removeBilledStudent(studentName: String) {
        var prevMonthName: String = ""
        var prevMonthInt: Int = 0
        var billingYear: String = ""
        var studentBillingFileName: String = ""
        var studentBillingCount: Int = 0
        var sheetCells = [[String]]()
        
        
        if let monthInt = Calendar.current.dateComponents([.month], from: Date()).month {
            var prevMonthInt = monthInt - 2                  // subtract 2 from current month name to get prev month with 0-based array index
            if prevMonthInt == -1 {
               prevMonthInt = 11
            }
            prevMonthName = monthArray[prevMonthInt]
        }
        
        if let yearInt = Calendar.current.dateComponents([.year], from: Date()).year {
            if prevMonthName == monthArray[11] {
                billingYear = String(yearInt - 1)
            } else {
                billingYear = String(yearInt)
            }
        }

        if runMode == "PROD" {
            studentBillingFileName = "Student Billing Summary " + billingYear
        } else {
            studentBillingFileName = "Student Billing Summary - TEST " + billingYear
        }
        
        getFileID(fileName: studentBillingFileName) {result in
            switch result {
            case .success(let fileID):

                let studentBillingFileID = fileID
 
                Task {
// Get the count of Billed Students in the Billed Students spreadsheet
                    var sheetData = try await readSheetCells(fileID: studentBillingFileID, range: "Sept!A2:A2")
                    if let sheetData = sheetData {
                        studentBillingCount = Int(sheetData.values[0][0]) ?? 0
                    }
// Read in the Billed Students from the Billed Student spreadsheet
                    sheetData = try await readSheetCells(fileID: studentBillingFileID, range: "Sept!A4:J" + String(PgmConstants.studentBillingStartRow) + String(studentBillingCount - 1) )
                    
                    if let sheetData = sheetData {
                        sheetCells = sheetData.values
                    }
// Build the Billed Students list for the month from the data read in
                    let studentBillingMonth = StudentBillingMonth()
                    studentBillingMonth.loadStudentBillingRows(studentBillingCount: studentBillingCount, sheetCells: sheetCells)
                    
// Add new Student to Billed Student list for the month
                    let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByName(billedStudentName: studentName)
                    if billedStudentFound == false {
                        studentBillingMonth.addNewBilledStudent(studentName: studentName)
                    }
// Save the updated Billed Student list for the month
                    await studentBillingMonth.saveStudentBillingData(studentBillingFileID: studentBillingFileID, billingMonth: "Sept")
                    
                    //               loadStudentBillingMonth(billingMonth: billingMonth, studentBillingFileID: studentBillingFileID)
                    print ("after load student Billing Month")
                    //               }
                    print("After Task for get File ID")
                }
            case . failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
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
                
                let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: referenceData.students.studentsList[studentNum].studentName, clientName: referenceData.students.studentsList[studentNum].studentGuardian, clientEmail: referenceData.students.studentsList[studentNum].studentEmail, clientPhone: referenceData.students.studentsList[studentNum].studentPhone )
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
    
}
