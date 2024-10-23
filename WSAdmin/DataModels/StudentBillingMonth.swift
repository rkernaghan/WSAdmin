//
//  StudentBillingMonth.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//
import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

class StudentBillingMonth {
    var studentBillingRows = [StudentBillingRow]()
    
    func findBilledStudentByName(billedStudentName: String) -> (Bool, Int) {
        var found = false
        
        var billedStudentNum = 0
        while billedStudentNum < studentBillingRows.count && !found {
            if studentBillingRows[billedStudentNum].studentName == billedStudentName {
                found = true
            } else {
                billedStudentNum += 1
            }
        }
        return(found, billedStudentNum)
    }
    
    func addNewBilledStudent(studentName: String) {
        let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthSessions: 0, monthCost: 0.0, monthRevenue: 0.0, monthProfit: 0.0, totalSessions: 0, totalCost: 0.0, totalRevenue: 0.0, totalProfit: 0.0, tutorName: "")
        self.studentBillingRows.append(newStudentBillingRow)
    }

    func insertBilledStudentRow(studentBillingRow: StudentBillingRow) {
        self.studentBillingRows.append(studentBillingRow)
    }

    func deleteBilledStudent(billedStudentNum: Int) {
        self.studentBillingRows.remove(at: billedStudentNum)
    }

    func loadStudentBillingData(studentBillingCount: Int, sheetCells: [[String]]) {

        var studentBillingIndex = 0
        var rowNumber = 0
        while studentBillingIndex < studentBillingCount {
            let studentName = sheetCells[rowNumber][PgmConstants.studentBillingStudentCol]
            let monthSessions: Int = Int(sheetCells[rowNumber][PgmConstants.studentBillingMonthSessionCol]) ?? 0
            let monthCost: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthCostCol]) ?? 0.0
            let monthRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthRevenueCol]) ?? 0.0
            let monthProfit: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingMonthProfitCol]) ?? 0.0
            
            let totalSessions: Int = Int(sheetCells[rowNumber][PgmConstants.studentBillingMonthSessionCol]) ?? 0
            let totalCost: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalCostCol]) ?? 0.0
            let totalRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalRevenueCol]) ?? 0.0
            let totalProfit: Float = Float(sheetCells[rowNumber][PgmConstants.studentBillingTotalProfitCol]) ?? 0.0
            let rowSize = sheetCells[rowNumber].count
            var tutorName = ""
            if rowSize == PgmConstants.studentBillingTutorCol + 1 {
                tutorName = sheetCells[rowNumber][PgmConstants.studentBillingTutorCol]
            }
            
            let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthSessions: monthSessions, monthCost: monthCost, monthRevenue: monthRevenue, monthProfit: monthProfit, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit, tutorName: tutorName)
            
            self.insertBilledStudentRow(studentBillingRow: newStudentBillingRow)
            
            rowNumber += 1
            studentBillingIndex += 1
        }
//                  print("Loaded Student Billing Data")
//                  let billedStudentCount = self.studentBillingRows.count
//                  var billedStudentNum = 0
//                  while billedStudentNum < billedStudentCount {
//                      print("Billed Student " + self.studentBillingRows[0].studentName)
//                      billedStudentNum += 1
//                  }
    }
    
    func unloadStudentBillingData() -> [[String]] {
    
        var updateValues = [[String]]()
    
        let billedStudentCount = studentBillingRows.count
        var billedStudentNum = 0
        while billedStudentNum < billedStudentCount {
            let studentName: String = studentBillingRows[billedStudentNum].studentName
            let monthSessions: String = String(studentBillingRows[billedStudentNum].monthSessions)
            let monthCost: String = String(studentBillingRows[billedStudentNum].monthCost)
            let monthRevenue: String = String(studentBillingRows[billedStudentNum].monthRevenue)
            let monthProfit: String = String(studentBillingRows[billedStudentNum].monthProfit)
            let totalSessions: String = String(studentBillingRows[billedStudentNum].totalSessions)
            let totalCost: String = String(studentBillingRows[billedStudentNum].totalCost)
            let totalRevenue: String = String(studentBillingRows[billedStudentNum].totalRevenue)
            let totalProfit: String = String(studentBillingRows[billedStudentNum].totalProfit)
            let tutorName: String = studentBillingRows[billedStudentNum].tutorName
            
            updateValues.insert([studentName, monthSessions, monthCost, monthRevenue, monthProfit, totalSessions, totalCost, totalRevenue, totalProfit, tutorName], at: billedStudentNum)
            billedStudentNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedStudentNum)
        return(updateValues)
    }
    
    func loadStudentBillingMonthAsync(prevMonthName: String, studentBillingFileID: String) async {
        var studentBillingCount: Int = 0
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Get the count of Students in the Billed Student spreadsheet
        do {
            sheetData = try await readSheetCells(fileID: studentBillingFileID, range: prevMonthName + PgmConstants.studentBillingCountRange)
        } catch {
            
        }
        
        if let sheetData = sheetData {
            studentBillingCount = Int(sheetData.values[0][0]) ?? 0
        }
// Read in the Billed Students from the Billed Student spreadsheet
        do {
            sheetData = try await readSheetCells(fileID: studentBillingFileID, range: prevMonthName + PgmConstants.studentBillingRange + String(PgmConstants.studentBillingStartRow) + String(studentBillingCount - 1) )
        } catch {
            
        }
            
        if let sheetData = sheetData {
            sheetCells = sheetData.values
        }
// Build the Billed Students list for the month from the data read in

        loadStudentBillingData(studentBillingCount: studentBillingCount, sheetCells: sheetCells)
    }
    
    func loadStudentBillingMonth(billingMonth: String, studentBillingFileID: String) {
        var studentBillingCount: Int = 0
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        let range = PgmConstants.studentBillingCountRange
//         print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: studentBillingFileID, range:range)
// Load the count of Student Billing entries from the Student Billing spreadsheet
        sheetService.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                print(error)
                print("Failed to read Student Billing data:\(error.localizedDescription)")
                return
            }
            guard let result = result as? GTLRSheets_ValueRange else {
                return
            }
            
            let rows = result.values!
            var stringRows = rows as! [[String]]
            
            for row in stringRows {
                stringRows.append(row)
                studentBillingCount = Int(stringRows[0][0]) ?? 0
            }
            
            if rows.isEmpty {
                print("No data found.")
                return
            }
            // Load the Billed Students from the Billed Student spreadsheet
            let sheetService = GTLRSheetsService()
            let currentUser = GIDSignIn.sharedInstance.currentUser
            sheetService.authorizer = currentUser?.fetcherAuthorizer
            let range = billingMonth + PgmConstants.studentBillingRange + String(PgmConstants.studentBillingStartRow + studentBillingCount - 1)
            print("range is \(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: studentBillingFileID, range:range)
            sheetService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print(error)
                    print("Failed to read Student Billing data:\(error.localizedDescription)")
                    return
                }
                guard let result = result as? GTLRSheets_ValueRange else {
                    return
                }
                
                let rows = result.values!
                var stringRows = rows as! [[String]]
                
                for row in stringRows {
                    stringRows.append(row)
                }
                
                if rows.isEmpty {
                    print("No data found.")
                    return
                }
                
                var studentBillingIndex = 0
                var rowNumber = 0
                while studentBillingIndex < studentBillingCount {
                    
                    let studentName = stringRows[rowNumber][PgmConstants.studentBillingStudentCol]
                    let monthSessions: Int = Int(stringRows[rowNumber][PgmConstants.studentBillingMonthSessionCol]) ?? 0
                    let monthCost: Float = Float(stringRows[rowNumber][PgmConstants.studentBillingMonthCostCol]) ?? 0.0
                    let monthRevenue: Float = Float(stringRows[rowNumber][PgmConstants.studentBillingMonthRevenueCol]) ?? 0.0
                    let monthProfit: Float = Float(stringRows[rowNumber][PgmConstants.studentBillingMonthProfitCol]) ?? 0.0
                    
                    let totalSessions: Int = Int(stringRows[rowNumber][PgmConstants.studentBillingMonthSessionCol]) ?? 0
                    let totalCost: Float = Float(stringRows[rowNumber][PgmConstants.studentBillingTotalCostCol]) ?? 0.0
                    let totalRevenue: Float = Float(stringRows[rowNumber][PgmConstants.studentBillingTotalRevenueCol]) ?? 0.0
                    let totalProfit: Float = Float(stringRows[rowNumber][PgmConstants.studentBillingTotalProfitCol]) ?? 0.0
                    let rowSize = stringRows[rowNumber].count
                    var tutorName = ""
                    if rowSize == PgmConstants.studentBillingTutorCol + 1 {
                        tutorName = stringRows[rowNumber][PgmConstants.studentBillingTutorCol]
                    }
                    
                    let newStudentBillingRow = StudentBillingRow(studentName: studentName, monthSessions: monthSessions, monthCost: monthCost, monthRevenue: monthRevenue, monthProfit: monthProfit, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit, tutorName: tutorName)
                    
                    self.insertBilledStudentRow(studentBillingRow: newStudentBillingRow)
                    
                    rowNumber += 1
                    studentBillingIndex += 1
                }
                print("Loaded Student Billing Data")
                let billedStudentCount = self.studentBillingRows.count
                var billedStudentNum = 0
                while billedStudentNum < billedStudentCount {
                    print("Billed Student " + self.studentBillingRows[0].studentName)
                    billedStudentNum += 1
                }
            }
        }
    }
    
//    func saveStudentBillingData(billingMonth: String, billingYear: String) async {
//        var studentBillingFileID = " "
//
//        let studentBillingFileName = "Student Billing Summary - TEST " + billingYear
//        getFileID(fileName: studentBillingFileName) {result in
//            switch result {
//            case .success(let fileID):
//                studentBillingFileID = fileID
//                self.saveStudentBillingMonth(billingMonth: billingMonth, studentBillingFileID: studentBillingFileID)
//                print("After Task for get File ID")
//            case . failure(let error):
//                print("Error: \(error.localizedDescription)")
//            }
//        }
//    }
    
    func saveStudentBillingData(studentBillingFileID: String, billingMonth: String) async -> Bool {
        var result: Bool = true
// Write the Student Billing rows to the Billed Student spreadsheet
        let updateValues = unloadStudentBillingData()
        let range = billingMonth + PgmConstants.studentBillingRange + String(PgmConstants.studentBillingStartRow + updateValues.count - 1)
        do {
            result = try await writeSheetCells(fileID: studentBillingFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Billed Student rows failed")
           result = false
        }
// Write the count of Student Billing rows to the Billed Student spreadsheet
        let billedStudentCount = updateValues.count - 1              // subtract 1 for blank line at end
        do {
            result = try await writeSheetCells(fileID: studentBillingFileID, range: billingMonth + PgmConstants.studentBillingCountRange, values: [[ String(billedStudentCount) ]])
        } catch {
            print ("Error: Saving Billed Student count failed")
            result = false
        }
        
        return(result)
    }
    
    func saveStudentBillingMonth(billingMonth: String, studentBillingFileID: String) {
 
        var updateValues: [[String]] = []
        
        let sheetService = GTLRSheetsService()
        let billedStudentCount = studentBillingRows.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer

        let range = billingMonth + PgmConstants.studentBillingRange + String(PgmConstants.studentBillingStartRow + billedStudentCount)
        print("Billed Student Data Save Range", range)
  
        var billedStudentNum = 0
        while billedStudentNum < billedStudentCount {
            let studentName: String = studentBillingRows[billedStudentNum].studentName
            let monthSessions: String = String(studentBillingRows[billedStudentNum].monthSessions)
            let monthCost: String = String(studentBillingRows[billedStudentNum].monthCost)
            let monthRevenue: String = String(studentBillingRows[billedStudentNum].monthRevenue)
            let monthProfit: String = String(studentBillingRows[billedStudentNum].monthProfit)
            let totalSessions: String = String(studentBillingRows[billedStudentNum].totalSessions)
            let totalCost: String = String(studentBillingRows[billedStudentNum].totalCost)
            let totalRevenue: String = String(studentBillingRows[billedStudentNum].totalRevenue)
            let totalProfit: String = String(studentBillingRows[billedStudentNum].totalProfit)
            let tutorName: String = studentBillingRows[billedStudentNum].tutorName
            
            updateValues.insert([studentName, monthSessions, monthCost, monthRevenue, monthProfit, totalSessions, totalCost, totalRevenue, totalCost, totalProfit, tutorName], at: billedStudentNum)
            billedStudentNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedStudentNum)
        
        let valueRange = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
        valueRange.majorDimension = "ROWS" // Indicates horizontal row insert
        valueRange.range = range
        valueRange.values = updateValues
        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: studentBillingFileID, range: range)
        query.valueInputOption = "USER_ENTERED"
        sheetService.executeQuery(query) { ticket, object, error in
            if let error = error {
                print(error)
                print("Failed to save data:\(error.localizedDescription)")
                return
            }
            else {
                print("Billed Students Rows saved")
                
                let sheetService = GTLRSheetsService()
                let currentUser = GIDSignIn.sharedInstance.currentUser
                sheetService.authorizer = currentUser?.fetcherAuthorizer

                let range = billingMonth + PgmConstants.studentBillingCountRange
                valueRange.range = range
                valueRange.values = [[ String(billedStudentCount) ]]
                
                let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: studentBillingFileID, range: range)
                query.valueInputOption = "USER_ENTERED"
                sheetService.executeQuery(query) { ticket, object, error in
                    if let error = error {
                        print(error)
                        print("Failed to save data:\(error.localizedDescription)")
                        return
                    }
                    else {
                        print("Billed Student Count saved")
                    }
                }
            }
        }
    }
    
    
}