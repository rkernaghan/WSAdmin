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
import GTMSessionFetcher


@Observable class TutorMgmtVM  {
    
    
    func addNewTutor(referenceData: ReferenceData, tutorName: String, contactEmail: String, contactPhone: String, maxStudents: Int) {

        let newTutorKey = PgmConstants.tutorKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestTutorKey)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: Date())
 //       let maxStudentsInt = Int(maxStudents) ?? 0
        
        let newTutor = Tutor(tutorKey: newTutorKey, tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorStatus: "Active", tutorStartDate: startDate, tutorEndDate: " ", tutorMaxStudents: maxStudents, tutorStudentCount: 0, tutorServiceCount: 0, tutorTotalSessions: 0, tutorTotalCost: 0.0, tutorTotalRevenue: 0.0, tutorTotalProfit: 0.0)
        referenceData.tutors.loadTutor(newTutor: newTutor)
        referenceData.tutors.saveTutorData()
        referenceData.dataCounts.increaseTotalTutorCount()
        
        createNewDetailsSheet(tutorName: tutorName, tutorKey: newTutorKey)
        
 //       createNewTimesheet(tutorName: tutorName)
        copyNewTimesheet(tutorName: tutorName)
//        copyDriveFile(timesheetTemplateFileID: "1MhZOJsyOjijWV_9NYl0cwnMnneD2UHk7Q059Q4vy-TU", newTimesheetFileName: "new timesheet")
        
//        addPermissionToDriveFile(fileId: "1MhZOJsyOjijWV_9NYl0cwnMnneD2UHk7Q059Q4vy-TU", accessToken: "Token", role: "writer", type: "user")
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
    
    func deleteTutor(indexes: Set<Tutor.ID>, referenceData: ReferenceData) -> (Bool, String) {
        var deleteResult = true
        var deleteMessage = " "
        print("Deleting Tutor")
        
        for objectID in indexes {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount == 0 {
                    referenceData.tutors.tutorsList[tutorNum].markDeleted()
                    referenceData.tutors.saveTutorData()
                    referenceData.dataCounts.decreaseActiveStudentCount()
                } else {
                    deleteMessage = "Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
                    print("Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
                    deleteResult = false
                }
            }
        }
        return(deleteResult, deleteMessage)
    }

    func unDeleteTutor(indexes: Set<Tutor.ID>, referenceData: ReferenceData) -> (Bool, String) {
        var unDeleteResult = true
        var unDeleteMessage = " "
        print("UnDeleting Tutor")
        
        for objectID in indexes {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                if referenceData.tutors.tutorsList[tutorNum].tutorStatus == "Deleted" {
                    referenceData.tutors.tutorsList[tutorNum].markUnDeleted()
                    referenceData.tutors.saveTutorData()
                    referenceData.dataCounts.increaseActiveTutorCount()
                } else {
                    unDeleteMessage = "Error: \(referenceData.tutors.tutorsList[tutorNum].tutorName) Can not be undeleted as status is \(referenceData.tutors.tutorsList[tutorNum].tutorStatus)"
                    print("Error: \(referenceData.tutors.tutorsList[tutorNum].tutorName) Can not be undeleted as status is \(referenceData.tutors.tutorsList[tutorNum].tutorStatus)")
                    unDeleteResult = false
                }
            }
        }
        return(unDeleteResult, unDeleteMessage)
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

    func assignTutorService(serviceNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) {
        
        print("Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor")
 
        for objectID in tutorIndex {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                print(referenceData.tutors.tutorsList[tutorNum].tutorName)
                
 //               referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
 //               referenceData.students.saveStudentData()
                
                let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName, billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1,  cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
                referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
                referenceData.tutors.saveTutorData()                    // increased Student count
                referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
                referenceData.services.saveServiceData()
            }
        }
    }
    
    func unassignTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData) -> (Bool, String) {
        var unassignResult: Bool = true
        var unassignMsg: String = " "
        
        let serviceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
        let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: serviceKey )
        if serviceFound {
            referenceData.services.servicesList[serviceNum].decreaseServiceUseCount()
            referenceData.services.saveServiceData()
            referenceData.tutors.tutorsList[tutorNum].removeTutorService(serviceKey: serviceKey)
        } else {
            unassignResult = false
            unassignMsg = "Tutor Service \(referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName) not Found for tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
        }
        return(unassignResult, unassignMsg)
    }
    
    func updateTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData, timesheetName: String, invoiceName: String, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) {

        referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
        
    }
    
 //   func createNewTimesheet(tutorName: String, completionHandler: @escaping (String) -> Void) {
   func createNewTimesheet(tutorName: String) {
        print("Creating New Timesheet for \(tutorName)")

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
  //              completionHandler("Error:\n\(error.localizedDescription)")
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
   
    func copyNewTimesheet(tutorName: String) {
        var timesheetTemplateFileID: String = " "
        var newFileID: String = ""
        
         print("Copying New Timesheet for \(tutorName)")
        if runMode == "PROD" {
            timesheetTemplateFileID = PgmConstants.prodTimesheetTemplateFileID
        } else {
            timesheetTemplateFileID = PgmConstants.testTimesheetTemplateFileID
        }
         let driveService = GTLRDriveService()
         let currentUser = GIDSignIn.sharedInstance.currentUser
//        if let user = GIDSignIn.sharedInstance().currentUser {
            driveService.authorizer = currentUser?.fetcherAuthorizer
//        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("YYYY")
        let currentYear = formatter.string(from: Date.now)
        let newTimesheetName  = "Timesheet " + currentYear + " " + tutorName
        let copyFile = GTLRDrive_File()
        copyFile.name = newTimesheetName
         
        let query = GTLRDriveQuery_FilesCopy.query(withObject: copyFile, fileId: timesheetTemplateFileID )
         driveService.executeQuery(query) { (ticket, file, error) in
             // let sheet = result as? GTLRSheets_Spreadsheet
             if let error = error {
                 print("Error in copying new timesheet for \(tutorName) \(error)")
                 return
             }
             else {
                 if let file = file as? GTLRDrive_File {
                     newFileID = file.identifier ?? ""
                 }
                 print("New Timesheet for tutor \(tutorName) is \(newFileID)")
                 self.addPermissionToDriveFile(fileId: newFileID, tutorEmail: "mkerkinos@gmail.com", role: "writer", type: "user")
             }
         }
     }
    func createNewDetailsSheet(tutorName: String, tutorKey: String) {
        
        var spreadsheetID: String
        var updateValues: [[String]] = []
        
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
                print("Error with creating Tutor Details sheet for tutor \(tutorName):\(error.localizedDescription)")
            } else {
                print("Tutor Details Sheet added for tutor \(tutorName)")
            }
           
            var range = tutorName + PgmConstants.tutorHeader1Range
            updateValues = PgmConstants.tutorHeader1Array
            let valueRange1 = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
            valueRange1.majorDimension = "ROWS" // Indicates horizontal row insert
            valueRange1.range = range
            valueRange1.values = updateValues
            let query1 = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange1, spreadsheetId: spreadsheetID, range: range)
            query1.valueInputOption = "USER_ENTERED"
            sheetService.executeQuery(query1) { ticket, object, error in
                if let error = error {
                    print(error)
                    print("Failed to save Tutor Details Header 1 data for Tutor \(tutorName):\(error.localizedDescription)")
                    return
                }
                else {
                    print("Tutor Details Header 1 saved for tutor \(tutorName)")
                }
            }
            
            range = tutorName + PgmConstants.tutorHeader2Range
            updateValues = PgmConstants.tutorHeader2Array
            let valueRange2 = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
            valueRange2.majorDimension = "ROWS" // Indicates horizontal row insert
            valueRange2.range = range
            valueRange2.values = updateValues
            let query2 = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange2, spreadsheetId: spreadsheetID, range: range)
            query2.valueInputOption = "USER_ENTERED"
            sheetService.executeQuery(query2) { ticket, object, error in
                if let error = error {
                    print(error)
                    print("Failed to save Tutor Details Header 2 data for Tutor \(tutorName):\(error.localizedDescription)")
                    return
                }
                else {
                    print("Tutor Details Header 2 saved tutor \(tutorName)")
                }
            }
            
            range = tutorName + PgmConstants.tutorHeader3Range
            updateValues = [[tutorKey, tutorName]]
            let valueRange3 = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
            valueRange3.majorDimension = "COLUMNS" // Indicates horizontal row insert
            valueRange3.range = range
            valueRange3.values = updateValues
            let query3 = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange3, spreadsheetId: spreadsheetID, range: range)
            query3.valueInputOption = "USER_ENTERED"
            sheetService.executeQuery(query3) { ticket, object, error in
                if let error = error {
                    print(error)
                    print("Failed to save Tutor Details Header 3 data for tutor \(tutorName):\(error.localizedDescription)")
                    return
                }
                else {
                    print("Tutor Details Header 3 saved for Tutor \(tutorName)")
                }
            }
        }
    }
    
    func addPermissionToDriveFile(fileId: String, tutorEmail: String, role: String, type: String) {
        let service = GTLRDriveService()
  //      service.authorizer = GTMAppAuthFetcherAuthorization(authState: OAuth2.authState)
        let currentUser = GIDSignIn.sharedInstance.currentUser
        service.authorizer = currentUser?.fetcherAuthorizer

        let permission = GTLRDrive_Permission()
        permission.role = role  // e.g., "reader", "writer"
        permission.type = type  // e.g., "user", "group", "domain", "anyone"
        permission.emailAddress = tutorEmail

        let query = GTLRDriveQuery_PermissionsCreate.query(withObject: permission, fileId: fileId)
        
        service.executeQuery(query) { ticket, permission, error in
            if let error = error {
                print("Error adding permission: \(error.localizedDescription)")
            } else {
                print("Permission added successfully for \(tutorEmail)")
            }
        }
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
    }
    
    func buildServiceCostArray(serviceNum: Int, referenceData: ReferenceData) -> TutorServiceCostList {
       let tutorServiceCostList = TutorServiceCostList()
        
        let serviceKey = referenceData.services.servicesList[serviceNum].serviceKey
        var tutorNum = 0
        while tutorNum < referenceData.tutors.tutorsList.count {
            let (serviceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: serviceKey)
            if serviceFound {
                let tutorKey = referenceData.tutors.tutorsList[tutorNum].tutorKey
                let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
                let cost1 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost1
                let cost2 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost2
                let cost3 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost3
                let price1 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price1
                let price2 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price2
                let price3 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price3
                
                let newTutorServiceCost = TutorServiceCost(tutorKey: tutorKey, tutorName: tutorName, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
                tutorServiceCostList.addTutorServiceCost(newTutorServiceCost: newTutorServiceCost, referenceData: referenceData)
            }
            tutorNum += 1
        }
        return(tutorServiceCostList)
    }
    
}
