//
//  Tutor.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

class Tutor: Identifiable {
    var tutorKey: String
    var tutorName: String
    var tutorEmail: String
    var tutorPhone: String
    var tutorStatus: String
    var tutorStartDate: String
    var tutorEndDate: String
    var tutorMaxStudents: Int
    var tutorStudentCount: Int
    var tutorServiceCount: Int
    var tutorTotalSessions: Int
    var tutorTotalCost: Float
    var tutorTotalRevenue: Float
    var tutorTotalProfit: Float
    var tutorStudents = [TutorStudent]()
    var tutorServices = [TutorService]()
    let id = UUID()
    
    init(tutorKey: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorStatus: String, tutorStartDate: String, tutorEndDate: String, tutorMaxStudents: Int, tutorStudentCount: Int, tutorServiceCount: Int, tutorTotalSessions: Int, tutorTotalCost: Float, tutorTotalRevenue: Float, tutorTotalProfit: Float) {
        self.tutorKey = tutorKey
        self.tutorName = tutorName
        self.tutorEmail = tutorEmail
        self.tutorPhone = tutorPhone
        self.tutorStatus = tutorStatus
        self.tutorStartDate = tutorStartDate
        self.tutorEndDate = tutorEndDate
        self.tutorMaxStudents = tutorMaxStudents
        self.tutorStudentCount = tutorStudentCount
        self.tutorServiceCount = tutorServiceCount
        self.tutorTotalSessions = tutorTotalSessions
        self.tutorTotalCost = tutorTotalCost
        self.tutorTotalRevenue = tutorTotalRevenue
        self.tutorTotalProfit = tutorTotalProfit
    }
    
    func addTutorStudent(newTutorStudent: TutorStudent) {
        tutorStudents.append(newTutorStudent)
    }
    
    func addTutorService(newTutorService: TutorService) {
        tutorServices.append(newTutorService)
    }
    
    func loadTutorDetails(tutorNum: Int, tutorDataFileID: String, referenceData: ReferenceData) {
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        
//        let tutors = referenceData.tutors
//        let tutorCount = referenceData.dataCounts.totalTutors
//        var tutorNum = 0
//        while tutorNum < tutorCount {
//            var tutorName = tutors.tutorsList[tutorNum].tutorName
            
 //           let range = tutorName + PgmConstants.tutorCountsRange
 //           print("Tutor details counts range is '\(range)")
 //           let query = GTLRSheetsQuery_SpreadsheetsValuesGet
 //               .query(withSpreadsheetId: tutorDataFileID, range:range)
            // Load data counts from ReferenceData spreadsheet
 //           sheetService.executeQuery(query) { [tutorNum] (ticket, result, error) in
 //               if let error = error {
 //                   print(error)
 //                   print("Failed to read data:\(error.localizedDescription)")
 //                   return
 //               }
 //               guard let result = result as? GTLRSheets_ValueRange else {
 //                   return
 //               }
                
 //               let rows = result.values!
 //               var stringRows = rows as! [[String]]
                
//                for row in stringRows {
 //                   stringRows.append(row)
                    //               print(row)
 //               }
                
 //               if rows.isEmpty {
 //                   print("No data found.")
 //                   return
 //               }
                
                
                let tutorStudentCount = tutorStudentCount
                let tutorServiceCount = tutorServiceCount
                
                print("Tutor \(tutorName) Students: \(tutorStudentCount) Services: \(tutorServiceCount)")
                
                self.loadTutorServices(tutorNum: tutorNum, tutorDataFileID: tutorDataFileID, serviceCount: tutorServiceCount, referenceData: referenceData, sheetService: sheetService)

                self.loadTutorStudents(tutorNum: tutorNum, tutorDataFileID: tutorDataFileID, studentCount: tutorStudentCount, referenceData: referenceData, sheetService: sheetService)
//            }
//            tutorNum += 1
        }
    
    
    func loadTutorStudents(tutorNum: Int, tutorDataFileID: String, studentCount: Int, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        print("Loading \(studentCount) Students")
        let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
            
        let range = tutorName + PgmConstants.tutorStudentsRange + String(studentCount + PgmConstants.tutorDataStudentsStartingRowNumber)
            print("Tutor details counts range is '\(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet
                .query(withSpreadsheetId: tutorDataFileID, range:range)
            // Load data counts from ReferenceData spreadsheet
            sheetService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print(error)
                    print("Failed to read data:\(error.localizedDescription)")
                    return
                }
                guard let result = result as? GTLRSheets_ValueRange else {
                    return
                }
                
                let rows = result.values!
                var stringRows = rows as! [[String]]
                
                for row in stringRows {
                    stringRows.append(row)
                    //               print(row)
                }
                
                if rows.isEmpty {
                    print("No data found.")
                    return
                }
                
                var rowNum = 0
                var studentNum = 0
                while studentNum < studentCount {
                    let studentKey = stringRows[rowNum][PgmConstants.tutorDataStudentNamePosition]
                    let studentName = stringRows[rowNum][PgmConstants.tutorDataStudentNamePosition]
                    let clientName = stringRows[rowNum][PgmConstants.tutorDataStudentClientNamePosition]
                    let clientEmail = stringRows[rowNum][PgmConstants.tutorDataStudentClientEmailPosition]
                    let clientPhone = stringRows[rowNum][PgmConstants.tutorDataStudentClientPhonePosition]
                    
                    let newTutorStudent = TutorStudent(studentKey: studentKey, studentName: studentName, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone)
                    
                    self.addTutorStudent( newTutorStudent: newTutorStudent)
                    rowNum += 1
                    studentNum += 1
                }
            }
        }
    
    
    func saveTutorStudents() {
        
    }
    
    func loadTutorServices(tutorNum: Int, tutorDataFileID: String, serviceCount: Int, referenceData: ReferenceData, sheetService: GTLRSheetsService ) {
       
        print("Loading \(serviceCount) Services")
        let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
            
        let range = tutorName + PgmConstants.tutorServicesRange + String(serviceCount + PgmConstants.tutorDataServicesStartingRowNumber)
            print("Tutor details counts range is '\(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet
                .query(withSpreadsheetId: tutorDataFileID, range:range)
            // Load data counts from ReferenceData spreadsheet
            sheetService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print(error)
                    print("Failed to read data:\(error.localizedDescription)")
                    return
                }
                guard let result = result as? GTLRSheets_ValueRange else {
                    return
                }
                
                let rows = result.values!
                var stringRows = rows as! [[String]]
                
                for row in stringRows {
                    stringRows.append(row)
                    //               print(row)
                }
                
                if rows.isEmpty {
                    print("No data found.")
                    return
                }
                
                var rowNum = 0
                var serviceNum = 0
                while serviceNum < serviceCount {
                    let serviceKey = stringRows[rowNum][PgmConstants.tutorDataServiceKeyPosition]
                    let timesheetName = stringRows[rowNum][PgmConstants.tutorDataServiceTimesheetNamePosition]
                    let invoiceName = stringRows[rowNum][PgmConstants.tutorDataServiceInvoiceNamePosition]
                    let billingType = stringRows[rowNum][PgmConstants.tutorDataServiceBillingTypePosition]
                    let cost1 = Float(stringRows[rowNum][PgmConstants.tutorDataServiceCost1Position]) ?? 0.0
                    let cost2 = Float(stringRows[rowNum][PgmConstants.tutorDataServiceCost2Position]) ?? 0.0
                    let cost3 = Float(stringRows[rowNum][PgmConstants.tutorDataServiceCost3Position]) ?? 0.0
                    let price1 = Float(stringRows[rowNum][PgmConstants.tutorDataServicePrice1Position]) ?? 0.0
                    let price2 = Float(stringRows[rowNum][PgmConstants.tutorDataServicePrice2Position]) ?? 0.0
                                       let price3 = Float(stringRows[rowNum][PgmConstants.tutorDataServicePrice3Position]) ?? 0.0
                    
                    let newTutorService = TutorService(serviceKey: serviceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
                    
                    self.addTutorService( newTutorService: newTutorService)
                    rowNum += 1
                    serviceNum += 1
                }
            }
    }
    
    func saveTutorServices() {
        
    }
}
