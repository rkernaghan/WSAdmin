//
//  TutorBillingMonth.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-18.
//
import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

class TutorBillingMonth {
    var tutorBillingRows = [TutorBillingRow]()
    
    func findBilledTutorByName(billedTutorName: String) -> (Bool, Int) {
        var found = false
        
        var billedTutorNum = 0
        while billedTutorNum < tutorBillingRows.count && !found {
            if tutorBillingRows[billedTutorNum].tutorName == billedTutorName {
                found = true
            } else {
                billedTutorNum += 1
            }
        }
        return(found, billedTutorNum)
    }
    
    func addNewBilledTutor(tutorName: String) {
        let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthSessions: 0, monthCost: 0.0, monthRevenue: 0.0, monthProfit: 0.0, totalSessions: 0, totalCost: 0.0, totalRevenue: 0.0, totalProfit: 0.0)
        self.tutorBillingRows.append(newTutorBillingRow)
    }

    func insertBilledTutorRow(tutorBillingRow: TutorBillingRow) {
        self.tutorBillingRows.append(tutorBillingRow)
    }
 
    func deleteBilledTutor(billedTutorNum: Int) {
        self.tutorBillingRows.remove(at: billedTutorNum)
    }
    
    func loadTutorBillingData(billingMonth: String, billingYear: String) {
        var tutorBillingFileID = " "
        
        let tutorBillingFileName = "Tutor Billing Summary - TEST " + billingYear
        getFileID(fileName: tutorBillingFileName) {result in
            switch result {
            case .success(let fileID):
                print("Tutor Billing File ID: \(fileID)")
                tutorBillingFileID = fileID
                //               Task {
  //              print ("before load tutor Billing Month")
                //                   await self.loadTutorBillingMonth(billingMonth: billingMonth, tutorBillingFileID: tutorBillingFileID)
                self.loadTutorBillingMonth(billingMonth: billingMonth, tutorBillingFileID: tutorBillingFileID)
  //              print ("after load tutor Billing Month")
                //               }
  //              print("After Task for get File ID")
            case . failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func loadTutorBillingMonthAsync(prevMonthName: String, tutorBillingFileID: String) async {
        var tutorBillingCount: Int = 0
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Get the count of Tutors in the Billed Tutor spreadsheet
        do {
            sheetData = try await readSheetCells(fileID: tutorBillingFileID, range: prevMonthName + PgmConstants.tutorBillingCountRange)
        } catch {
            
        }
        
        if let sheetData = sheetData {
            tutorBillingCount = Int(sheetData.values[0][0]) ?? 0
        }
// Read in the Billed Tutors from the Billed Tutor spreadsheet
        if tutorBillingCount > 0 {
            do {
                sheetData = try await readSheetCells(fileID: tutorBillingFileID, range: prevMonthName + PgmConstants.tutorBillingRange + String(PgmConstants.tutorBillingStartRow + tutorBillingCount - 1) )
            } catch {
                
            }
            
            if let sheetData = sheetData {
                sheetCells = sheetData.values
            }
// Build the Billed Tutors list for the month from the data read in
            loadTutorBillingRows(tutorBillingCount: tutorBillingCount, sheetCells: sheetCells)
        }
    }
    
    func loadTutorBillingMonth(billingMonth: String, tutorBillingFileID: String) {
        var tutorBillingCount: Int = 0
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        let range = PgmConstants.tutorBillingCountRange
//         print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: tutorBillingFileID, range:range)
// Load the count of Tutor Billing entries from the Tutor Billing spreadsheet
        sheetService.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                print(error)
                print("Failed to read Tutor Billing data:\(error.localizedDescription)")
                return
            }
            guard let result = result as? GTLRSheets_ValueRange else {
                return
            }
            
            let rows = result.values!
            var stringRows = rows as! [[String]]
            
            for row in stringRows {
                stringRows.append(row)
                tutorBillingCount = Int(stringRows[0][0]) ?? 0
            }
            
            if rows.isEmpty {
                print("No data found.")
                return
            }
            // Load the Billed Tutors from the Billed Tutor spreadsheet
            let sheetService = GTLRSheetsService()
            let currentUser = GIDSignIn.sharedInstance.currentUser
            sheetService.authorizer = currentUser?.fetcherAuthorizer
            let range = billingMonth + PgmConstants.tutorBillingRange + String(PgmConstants.tutorBillingStartRow + tutorBillingCount - 1)
            print("range is \(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: tutorBillingFileID, range:range)
            sheetService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print(error)
                    print("Failed to read Tutor Billing data:\(error.localizedDescription)")
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
                
                var tutorBillingIndex = 0
                var rowNumber = 0
                while tutorBillingIndex < tutorBillingCount {
                    
                    let tutorName = stringRows[rowNumber][PgmConstants.tutorBillingTutorCol]
                    let monthSessions: Int = Int(stringRows[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
                    let monthCost: Float = Float(stringRows[rowNumber][PgmConstants.tutorBillingMonthCostCol]) ?? 0.0
                    let monthRevenue: Float = Float(stringRows[rowNumber][PgmConstants.tutorBillingMonthRevenueCol]) ?? 0.0
                    let monthProfit: Float = Float(stringRows[rowNumber][PgmConstants.tutorBillingMonthProfitCol]) ?? 0.0
                    
                    let totalSessions: Int = Int(stringRows[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
                    let totalCost: Float = Float(stringRows[rowNumber][PgmConstants.tutorBillingTotalCostCol]) ?? 0.0
                    let totalRevenue: Float = Float(stringRows[rowNumber][PgmConstants.tutorBillingTotalRevenueCol]) ?? 0.0
                    let totalProfit: Float = Float(stringRows[rowNumber][PgmConstants.tutorBillingTotalProfitCol]) ?? 0.0
                    let rowSize = stringRows[rowNumber].count
                    
                    let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthSessions: monthSessions, monthCost: monthCost, monthRevenue: monthRevenue, monthProfit: monthProfit, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit)
                    
                    self.insertBilledTutorRow(tutorBillingRow: newTutorBillingRow)
                    
                    rowNumber += 1
                    tutorBillingIndex += 1
                }
                print("Loaded Tutor Billing Data")
            }
        }
    }
    
    
    func saveTutorBillingData(tutorBillingFileID: String, billingMonth: String) async -> Bool {
        var result: Bool = true
// Write the Tutor Billing rows to the Billed Tutor spreadsheet
        let updateValues = unloadTutorBillingRows()
        let count = updateValues.count
        let range = billingMonth + PgmConstants.tutorBillingRange + String(PgmConstants.tutorBillingStartRow + updateValues.count - 1)
        do {
            result = try await writeSheetCells(fileID: tutorBillingFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Billed tutor rows failed")
           result = false
        }
// Write the count of tutor Billing rows to the Billed tutor spreadsheet
        let billedTutorCount = updateValues.count - 1              // subtract 1 for blank line at end
        do {
            result = try await writeSheetCells(fileID: tutorBillingFileID, range: billingMonth + PgmConstants.tutorBillingCountRange, values: [[ String(billedTutorCount) ]])
        } catch {
            print ("Error: Saving Billed Tutor count failed")
            result = false
        }
        
        return(result)
    }
   
    func loadTutorBillingRows(tutorBillingCount: Int, sheetCells: [[String]]) {

        var tutorBillingIndex = 0
        var rowNumber = 0
        while tutorBillingIndex < tutorBillingCount {
            let tutorName = sheetCells[rowNumber][PgmConstants.tutorBillingTutorCol]
            let monthSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
            let monthCost: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthCostCol]) ?? 0.0
            let monthRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthRevenueCol]) ?? 0.0
            let monthProfit: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingMonthProfitCol]) ?? 0.0
            
            let totalSessions: Int = Int(sheetCells[rowNumber][PgmConstants.tutorBillingMonthSessionCol]) ?? 0
            let totalCost: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalCostCol]) ?? 0.0
            let totalRevenue: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalRevenueCol]) ?? 0.0
            let totalProfit: Float = Float(sheetCells[rowNumber][PgmConstants.tutorBillingTotalProfitCol]) ?? 0.0
             
            let newTutorBillingRow = TutorBillingRow(tutorName: tutorName, monthSessions: monthSessions, monthCost: monthCost, monthRevenue: monthRevenue, monthProfit: monthProfit, totalSessions: totalSessions, totalCost: totalCost, totalRevenue: totalRevenue, totalProfit: totalProfit)
            
            self.insertBilledTutorRow(tutorBillingRow: newTutorBillingRow)
            
            rowNumber += 1
            tutorBillingIndex += 1
        }
//                  print("Loaded Tutor Billing Data")
//                  let billedTutorCount = self.tutorBillingRows.count
//                  var billedTutorNum = 0
//                  while billedTutorNum < billedTutorCount {
//                      print("Billed Tutor " + self.tutorBillingRows[0].tutorName)
//                      billedTutorNum += 1
//                  }
    }
    
    func unloadTutorBillingRows() -> [[String]] {
    
        var updateValues = [[String]]()
    
        let billedTutorCount = tutorBillingRows.count
        var billedTutorNum = 0
        while billedTutorNum < billedTutorCount {
            let tutorName: String = tutorBillingRows[billedTutorNum].tutorName
            let monthSessions: String = String(tutorBillingRows[billedTutorNum].monthSessions)
            let monthCost: String = String(tutorBillingRows[billedTutorNum].monthCost)
            let monthRevenue: String = String(tutorBillingRows[billedTutorNum].monthRevenue)
            let monthProfit: String = String(tutorBillingRows[billedTutorNum].monthProfit)
            let totalSessions: String = String(tutorBillingRows[billedTutorNum].totalSessions)
            let totalCost: String = String(tutorBillingRows[billedTutorNum].totalCost)
            let totalRevenue: String = String(tutorBillingRows[billedTutorNum].totalRevenue)
            let totalProfit: String = String(tutorBillingRows[billedTutorNum].totalProfit)
            
            updateValues.insert([tutorName, monthSessions, monthCost, monthRevenue, monthProfit, totalSessions, totalCost, totalRevenue, totalProfit], at: billedTutorNum)
            billedTutorNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " "], at: billedTutorNum)
        return(updateValues)
    }
    
    func checkAlreadyBilled(tutorList: [String]) -> (Bool, [String]) {
        var resultFlag: Bool = false
        var alreadyBilledTutors = [String]()
        var tutorName: String = ""
        
        let tutorListCount = tutorList.count
        var tutorListNum = 0
        let billedTutorCount = self.tutorBillingRows.count
        if billedTutorCount != 0 {
            
            while tutorListNum < tutorListCount {
                tutorName = tutorList[tutorListNum]
                let (foundFlag, billedTutorNum) = findBilledTutorByName(billedTutorName: tutorName)
                if foundFlag {
                    alreadyBilledTutors.append(tutorName)
                    resultFlag = true
                }
                tutorListNum += 1
            }
        }
        
        return(resultFlag, alreadyBilledTutors)
    }
    
}
