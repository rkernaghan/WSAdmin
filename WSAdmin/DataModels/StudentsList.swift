//
//  StudentsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class StudentsList {
    var studentsList = [Student]()
    
    func addStudent(newStudent: Student) {
        studentsList.append(newStudent)
    }
    
    func printAll() {
        for student in studentsList {
            print ("Student Name is \(student.studentName)")
        }
    }
    
    func saveStudentData() {
        var referenceFileID: String
        var updateValues: [[String]] = []
        
        var studentKey: String = " "
        var studentName: String = " "
        var studentGuardian: String = " "
        var studentEmail: String = " "
        var studentPhone: String = " "
        
        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
        }
        
        let sheetService = GTLRSheetsService()
        let spreadsheetID = referenceFileID
        let studentCount = studentsList.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
            
        let range = PgmConstants.studentRange + String(studentCount + PgmConstants.studentStartingRowNumber)
        print("Range", range)
  
        var studentNum = 0
        while studentNum < studentCount {
            studentKey = studentsList[studentNum].studentKey
            studentName = studentsList[studentNum].studentName
            studentGuardian = studentsList[studentNum].studentGuardian
            studentPhone = studentsList[studentNum].studentPhone
            studentEmail = studentsList[studentNum].studentEmail
            
            updateValues.insert([studentKey, studentName, studentGuardian, studentEmail, studentPhone], at: studentNum)
            studentNum += 1
        }
        
        let valueRange = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
        valueRange.majorDimension = "ROWS" // Indicates horizontal row insert
        valueRange.range = range
        valueRange.values = updateValues
        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: spreadsheetID, range: range)
        query.valueInputOption = "USER_ENTERED"
        sheetService.executeQuery(query) { ticket, object, error in
            if let error = error {
                print(error)
                print("Failed to save data:\(error.localizedDescription)")
                return
            }
            else {
                print("students saved")
            }
        }
    }
    
}
