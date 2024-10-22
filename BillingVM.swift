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

        
    func generateInvoice(tutorSet: Set<Tutor.ID>, timesheetYear: String, timesheetMonth: String, referenceData: ReferenceData) -> Invoice {
        var invoice = Invoice()
        
        let studentBillingMonth = StudentBillingMonth()
//        studentBillingMonth.loadStudentBillingData(billingMonth: "Sept", billingYear: "2024")
        
        for objectID in tutorSet {
            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
        print("Next Tutorname: \(tutorName)")
                let timesheet = getTimesheet(tutorName: tutorName, timesheetYear: "2024", timesheetMonth: "Sept")
            }
        }
        return(invoice)
    }
        
    func getTimesheet(tutorName: String, timesheetYear: String, timesheetMonth: String) -> Timesheet {
        var timesheet = Timesheet()
        var timesheetID: String = " "
        
        let fileName = "Timesheet " + timesheetYear + " " + tutorName
        getFileID(fileName: fileName) {result in
            switch result {
            case .success(let fileID):
                print("Timesheet File ID for \(tutorName): \(fileID)")
                timesheetID = fileID
                Task {
                    print ("before load timesheet call \(tutorName)")
                    await self.loadTimesheetData(tutorName: tutorName, month: timesheetMonth, timesheetID: timesheetID)
                    print ("after load timesheet call \(tutorName)")
                }
                print("After Task for \(tutorName)")
            case . failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
        
        return(timesheet)
    }
    
    func loadTimesheetData(tutorName: String, month: String, timesheetID: String) async {
           do {
               let spreadsheetId = timesheetID
               let range = "\(month)!" + PgmConstants.timesheetDataRange + "102"

               
// Fetch data from Google Sheets
               print("Before fetch timesheet call \(tutorName)")
               let sheetData = try await fetchTimesheetData(tutorName: tutorName, spreadsheetId: spreadsheetId, range: range)
               print("after fetch timesheet call \(tutorName)")
               if let sheetData = sheetData {
                   let entryCount = Int(sheetData.values[2][1]) ?? 0
                   var rowNum = 4
                   while rowNum < entryCount + 4 {
                       let student = sheetData.values[rowNum][PgmConstants.timesheetStudentCol]
                       let date = sheetData.values[rowNum][PgmConstants.timesheetDateCol]
                       let duration = Int(sheetData.values[rowNum][PgmConstants.timesheetDurationCol]) ?? 0
                       let service = sheetData.values[rowNum][PgmConstants.timesheetServiceCol]
                       let notes = sheetData.values[rowNum][PgmConstants.timesheetDurationCol]
                       let cost = Float(sheetData.values[rowNum][PgmConstants.timesheetCostCol]) ?? 0.0
                       let clientName = sheetData.values[rowNum][PgmConstants.timesheetClientNameCol]
                       let clientEmail = sheetData.values[rowNum][PgmConstants.timesheetClientEmailCol]
                       let clientPhone = sheetData.values[rowNum][PgmConstants.timesheetClientPhoneCol]
                       let newTimesheetRow = TimesheetRow(studentName: student, serviceDate: date, duration: duration, serviceName: service, notes: notes, cost: cost, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone)
                       print(tutorName, student, date, service)
                       rowNum += 1
                   }
               }
           } catch {
               let errorMessage = error.localizedDescription
               print(errorMessage)
           }
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
