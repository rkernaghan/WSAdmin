//
//  BillingVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GTMSessionFetcher
import GoogleAPIClientForREST

@Observable class BillingVM  {

//    private var sheetData: SheetData?
//    private var errorMessage: String?

        
    func generateInvoice(tutorSet: Set<Tutor.ID>, timesheetYear: String, timesheetMonth: String, referenceData: ReferenceData) async -> Invoice {
        var invoice = Invoice()
        var tutorList = [String]()
        var studentBillingFileID: String = ""
        var tutorBillingFileID: String = ""
        var resultFlag: Bool = true
        
        let studentBillingMonth = StudentBillingMonth()
        let tutorBillingMonth = TutorBillingMonth()
        
        let (monthName, billingYear) = getCurrentMonthYear()
        let studentBillingFileName = studentBillingFileNamePrefix + billingYear
        let tutorBillingFileName = tutorBillingFileNamePrefix + billingYear
        let billArray = BillArray()
        print ("//")
        print("//")
 //       Task {
            //    print("Before get Student Billing File ID Async")
        do {
            (resultFlag, studentBillingFileID) = try await getFileIDAsync(fileName: studentBillingFileName)
        } catch {
            
        }
            //    print("After get Student Billing File ID Async")
            //    print("Before Load Student Billing Month Async \(studentBillingFileID)")
            await studentBillingMonth.loadStudentBillingMonthAsync(prevMonthName: monthName, studentBillingFileID: studentBillingFileID)
            //    print("After Load Student Billing Month Async \(studentBillingFileID)")
            //    print("Before get Tutor File ID Async")
        do {
            (resultFlag, tutorBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
        } catch {
            
        }
            //    print("After Get Tutor File ID Async")
            //    print("Before Load Tutor Billing Month Async \(tutorBillingFileID)")
            await tutorBillingMonth.loadTutorBillingMonthAsync(prevMonthName: monthName, tutorBillingFileID: tutorBillingFileID)
            //    print("After Load Tutor Billing Month Async \(tutorBillingFileID)")
            //    print("Go time")
            //    print("Go time")
            for objectID in tutorSet {
                if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                    let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
                    print("Next Tutorname: \(tutorName)")
                    tutorList.append(tutorName)
                    //    print("Before get timesheet \(tutorName)")
                    let timesheet = await getTimesheet(tutorName: tutorName, timesheetYear: timesheetYear, timesheetMonth: timesheetMonth)
                    //    print("After get timesheet \(tutorName)")
                    billArray.processTimesheet(timesheet: timesheet)
                    //    print("After process timesheet")
                    
                }
            }
            print("Tutor List: \(tutorList)")
            //            billArray.printBillArray()
            
            let (alreadyBilledFlag, alreadyBilledTutors) = tutorBillingMonth.checkAlreadyBilled(tutorList: tutorList)
            
            if alreadyBilledFlag {
                print("Already Billed Tutors: \(alreadyBilledTutors)")
            }
            
            invoice = billArray.generateInvoice()
            
            
            //       let result1 = studentBillingMonth.saveStudentBillingData(studentBillingFileID: studentBillingFileID, billingMonth: monthName)
            //       let result2 = tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName)
            invoice.printInvoice()
            return(invoice)
   //     }
    }
        
    func getTimesheet(tutorName: String, timesheetYear: String, timesheetMonth: String) async -> Timesheet {
        var timesheet = Timesheet()
        var timesheetFileID: String = " "
        var result: Bool = true
        
        print("Start get timesheet" + tutorName)
        let fileName = "Timesheet " + timesheetYear + " " + tutorName
        do {
            (result, timesheetFileID) = try await getFileIDAsync(fileName: fileName)
        } catch {
            print("Error: could not get timesheet fileID for \(fileName)")
        }
        print("Before Task LoadTimesheet data " + tutorName)
//        Task {
            print("In Task for Get Timesheet " + tutorName)
            let range = await timesheet.loadTimesheetData(tutorName: tutorName, month: timesheetMonth, timesheetID: timesheetFileID)
            print("after load timesheet data before print value statement")
            print("Timesheet Returned" + timesheet.timesheetRows[0].studentName + " " + timesheet.timesheetRows[0].tutorName)
//        }
        
        return(timesheet)
    }
    
 

    func fetchTimesheetData(tutorName: String, spreadsheetId: String, range: String) async throws -> SheetData? {
        var yourOAuthToken: String
        var sheetData: SheetData?
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        if let user = currentUser {
            yourOAuthToken = user.accessToken.tokenString
            
// URL for Google Sheets API
            let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)"
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
// Set up the request with OAuth 2.0 token
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(yourOAuthToken)", forHTTPHeaderField: "Authorization")
            
// Use async URLSession to fetch the data
 
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("error \(httpResponse.statusCode)")
            }
// Check if the response is successful
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
// Decode the JSON data into the SheetData structure
            sheetData = try JSONDecoder().decode(SheetData.self, from: data)
 
        }
//        if let sheetData = sheetData {
            return sheetData
//        }
    }
}
