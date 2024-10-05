//
//  TutorMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST


@Observable class TutorMgmtVM  {
    
    
    func addNewTutor(referenceData: ReferenceData, tutorName: String, contactEmail: String, contactPhone: String, maxStudents: Int) {

        let newTutorKey = PgmConstants.tutorKeyPrefix + "0034"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: Date())
 //       let maxStudentsInt = Int(maxStudents) ?? 0
        
        let newTutor = Tutor(tutorKey: newTutorKey, tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorStatus: "Unassigned", tutorStartDate: startDate, tutorEndDate: " ", tutorMaxStudents: maxStudents, tutorStudentCount: 0, tutorServiceCount: 0, tutorTotalSessions: 0, tutorTotalCost: 0.0, tutorTotalRevenue: 0.0, tutorTotalProfit: 0.0)
        referenceData.tutors.loadTutor(newTutor: newTutor)
        referenceData.tutors.saveTutorData()
        referenceData.dataCounts.increaseTotalTutorCount()
        
        createNewSheet(tutorName: tutorName)
    }
    
    func listTutorStudents(indexes: Int, referenceData: ReferenceData) {
//        for objectID in indexes {
//            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
 //               print("Student Name \(referenceData.tutors.tutorsList[idx].tutorStudents[0].studentName)")
                
//               let result = TutorStudentsView(tutorNum: indexes, referenceData: referenceData)
//        print(result)
//            }
//        }
    }
    
    func updateTutor(tutorNum: Int, referenceData: ReferenceData, tutorName: String, contactEmail: String, contactPhone: String, maxStudents: Int) {
        
 //       let maxStudentsInt: Int = Int(maxStudents) ?? 0
        referenceData.tutors.tutorsList[tutorNum].updateTutor(contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
        referenceData.tutors.saveTutorData()

    }
    
    func validateNewTutor(tutorName: String, tutorEmail: String, tutorPhone: String, tutorMaxStudents: Int, referenceData: ReferenceData)->(Bool, String) {
        var validationResult = true
        var validationMessage = " "
        
        let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
        if tutorFoundFlag {
            validationResult = false
            validationMessage += "Error: Tutor Name \(tutorName) Already Exists"
        }
        
        let validEmailFlag = isValidEmail(tutorEmail)
        if !validEmailFlag {
            validationResult = false
            validationMessage += " Error: Tutor Email \(tutorEmail) is Not Valid"
        }
        
        let validPhoneFlag = isValidPhone(tutorPhone)
        if !validPhoneFlag {
            validationResult = false
            validationMessage += "Error: Phone Number \(tutorPhone) Is Not Valid"
        }
        
        return(validationResult, validationMessage)
    }

    func validateUpdatedTutor(tutorName: String, tutorEmail: String, tutorPhone: String, tutorMaxStudents: Int, referenceData: ReferenceData) -> (Bool, String) {
        var validationResult = true
        var validationMessage = " "
        
        let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
        if !tutorFoundFlag {
            validationResult = false
            validationMessage += "Error: Tutor \(tutorName) does not exist"
        }
        
        let validEmailFlag = isValidEmail(tutorEmail)
        if !validEmailFlag {
            validationResult = false
            validationMessage += " Error: Email \(tutorEmail) is Not Valid"
        }
        
        let validPhoneFlag = isValidPhone(tutorPhone)
        if !validPhoneFlag {
            validationResult = false
            validationMessage += "Error: Phone Number \(tutorPhone) Is Not Valid"
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
    
    func deleteTutor(indexes: Set<Tutor.ID>, referenceData: ReferenceData) -> Bool {
        var deleteResult = true
        print("Deleting Tutor")
        
        for objectID in indexes {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount == 0 {
                    referenceData.tutors.tutorsList[tutorNum].markDeleted()
                    referenceData.tutors.saveTutorData()
                    referenceData.dataCounts.decreaseActiveStudentCount()
                } else {
                    let buttonMessage = "Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
                    print("Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
                    deleteResult = false
                }
            }
        }
        return(deleteResult)
    }

    func unDeleteTutor(indexes: Set<Tutor.ID>, referenceData: ReferenceData) -> Bool {
        var unDeleteResult = true
        print("UnDeleting Tutor")
        
        for objectID in indexes {
            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.tutors.tutorsList[idx].tutorStatus == "Deleted" {
                    referenceData.tutors.tutorsList[idx].markUnDeleted()
                    referenceData.tutors.saveTutorData()
                    referenceData.dataCounts.increaseActiveTutorCount()
                } else {
                    let buttonMessage = "Error: \(referenceData.tutors.tutorsList[idx].tutorStudentCount) Can not be undeleted"
                    print("Error: \(referenceData.tutors.tutorsList[idx].tutorStudentCount) Can not be undeleted")
                    unDeleteResult = false
                }
            }
        }
        return(unDeleteResult)
    }
    
    func assignStudent(studentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) {
        print("Assigning Student to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
 
        for objectID in studentIndex {
            if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                print(referenceData.students.studentsList[studentNum].studentName)
                let studentNum1 = studentNum
                print(studentNum, studentNum1)
                
                referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
                referenceData.students.saveStudentData()
                
                let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: referenceData.students.studentsList[studentNum].studentName, clientName: referenceData.students.studentsList[studentNum].studentGuardian, clientEmail: referenceData.students.studentsList[studentNum].studentEmail, clientPhone: referenceData.students.studentsList[studentNum].studentPhone)
                referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
                referenceData.tutors.saveTutorData()                    // increased Student count
            }
        }
    }

    func assignService(serviceNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) {
        
        print("Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor")
 
        for objectID in tutorIndex {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                print(referenceData.tutors.tutorsList[tutorNum].tutorName)
                
 //               referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
 //               referenceData.students.saveStudentData()
                
                let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName, billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1,  cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
                referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
                referenceData.tutors.saveTutorData()                    // increased Student count
            }
        }
    }
    
    func updateTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData, timesheetName: String, invoiceName: String, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) {
//        let cost1Float = Float(cost1) ?? 0
//        let cost2Float = Float(cost2) ?? 0
//        let cost3Float = Float(cost3) ?? 0
//        let price1Float = Float(price1) ?? 0
//        let price2Float = Float(price2) ?? 0
//        let price3Float = Float(price3) ?? 0
        
        referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
        
    }
    
    func createNewTimesheet(tutorName: String, completionHandler: @escaping (String) -> Void) {
        print("Creating New Sheet ...\n")
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        let newSheet = GTLRSheets_Spreadsheet.init()
        let properties = GTLRSheets_SpreadsheetProperties.init()
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("YYYY")
        let currentYear = formatter.string(from: Date.now)
        properties.title = "Timesheet " + currentYear + " " + tutorName
        newSheet.properties = properties
        
        let query = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject:newSheet)
        query.fields = "spreadsheetId"
        
        sheetService.executeQuery(query) { (ticket, result, error) in
            // let sheet = result as? GTLRSheets_Spreadsheet
            if let error = error {
                completionHandler("Error:\n\(error.localizedDescription)")
                print("Error in creating the Sheet: \(error)")
                return
            }
            else {
                let response = result as! GTLRSheets_Spreadsheet
                let identifier = response.spreadsheetId
                print("Spreadsheet id: \(String(describing: identifier))")
                
                print("Success!")
            }
        }
    }
    
    func createNewSheet(tutorName: String) {
        
        var spreadsheetID: String
        
        let batchUpdate = GTLRSheets_BatchUpdateSpreadsheetRequest.init()
        let request = GTLRSheets_Request.init()
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        let properties = GTLRSheets_SheetProperties.init()
        properties.title = tutorName
        
        let sheetRequest = GTLRSheets_AddSheetRequest.init()
        sheetRequest.properties = properties
        
        request.addSheet = sheetRequest
        
        batchUpdate.requests = [request]
        
        if runMode == "PROD" {
            spreadsheetID = PgmConstants.prodTutorDataFileID
        } else {
            spreadsheetID = PgmConstants.testTutorDataFileID
        }
        
        let createQuery = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batchUpdate, spreadsheetId: spreadsheetID)
        
        sheetService.executeQuery(createQuery) { (ticket, result, err) in
            if let error = err {
                print(error)
                print("Error with creating sheet:\(error.localizedDescription)")
            } else {
                print("Success!")
                //newSheet.sheetId =
                print("Sheet added!")
            }
        }
    }
    
    func copyDriveFile(sourceFileID: String, newFileName: String) {
        print("Copying sheet")
        let driveService = GTLRDriveService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        driveService.authorizer = currentUser?.fetcherAuthorizer
        
        let dquery = GTLRDriveQuery_FilesList.query()
        dquery.pageSize = 100
        
 //       let root = "name = '\(fileName)' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed=false"
 //       dquery.q = root
        dquery.spaces = "drive"
        dquery.corpora = "user"
        dquery.fields = "files(id,name),nextPageToken"
// Retreive all files with Tutor timesheet name (should only be one)
        driveService.executeQuery(dquery, completionHandler: {(ticket, files, error) in
            if let error = error {
                print(error)
                print("Error with creating sheet:\(error)")
                return
            } else {
                print("Success!")
                //newSheet.sheetId =
                print("Sheet added!")
                let newFileID = " "
                return()
            }
        })
    }
    
    func printTutor(indexes: Set<Service.ID>, referenceData: ReferenceData) {
        print("Printing Tutor")
        
        for objectID in indexes {
            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                print("Tutor Name: \(referenceData.tutors.tutorsList[idx].tutorName)")
                print("Tutor Student Count: \(referenceData.tutors.tutorsList[idx].tutorStudentCount)")
                var studentNum = 0
                while studentNum < referenceData.tutors.tutorsList[idx].tutorStudentCount {
                    print("Tutor Student: \(referenceData.tutors.tutorsList[idx].tutorStudents[studentNum].studentName)")
                    studentNum += 1
                }
                print("Tutor Service Count: \(referenceData.tutors.tutorsList[idx].tutorServiceCount)")
                var serviceNum = 0
                while serviceNum < referenceData.tutors.tutorsList[idx].tutorServiceCount {
                    print("Tutor Service: \(referenceData.tutors.tutorsList[idx].tutorServices[serviceNum].timesheetServiceName)")
                    serviceNum += 1
                }
            }
        }
        referenceData.tutors.saveTutorData()
    }
    
}
