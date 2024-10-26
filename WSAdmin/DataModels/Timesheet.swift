//
//  Timesheet.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-15.
//

import Foundation

class Timesheet: Identifiable {
    var timesheetRows = [TimesheetRow]()
    var isTimesheetLoaded: Bool
    
    init() {
        isTimesheetLoaded = false
    }
    
    func addTimesheetRow(timesheetRow: TimesheetRow) {
        self.timesheetRows.append(timesheetRow)
 //     print("Adding \(timesheetRow.studentName) to timesheet")
    }
    
    func loadTimesheetData(tutorName: String, month: String, timesheetID: String) async -> String {
        var sheetData: SheetData?
 //     print("before task for LoadTimesheet Data " + tutorName)
        let range = month + PgmConstants.timesheetDataRange
 //       Task {
          
 //   print("before read sheet cells " + tutorName)
            do {
                sheetData = try await readSheetCells(fileID: timesheetID, range: range)
            } catch {
                
            }
 //           print("After readsheet cells " + tutorName)
            if let sheetData = sheetData {
                loadTimesheetRows(tutorName: tutorName, sheetCells: sheetData.values)
 //               print("Timesheet Returned in load" + self.timesheetRows[0].studentName + " " + self.timesheetRows[0].tutorName)
 //           }
 //       print("After Task for LoadTimesheet Data " + tutorName)
            
        }
        return(range)
    }
    
    func loadTimesheetRows(tutorName: String, sheetCells: [[String]] ) {
        
        if sheetCells.count > 0 {
            let entryCount = Int(sheetCells[PgmConstants.timesheetSessionCountRow][PgmConstants.timesheetSessionCountCol]) ?? 0
            var entryCounter = 0
            var rowNum = PgmConstants.timesheetFirstSessionRow
            var rowCounter = entryCount + 12                                                // 12 blank rows allowed
            while entryCounter < entryCount && rowNum < rowCounter {
                let date = sheetCells[rowNum][PgmConstants.timesheetDateCol]
                if date != "" && date != " " {
                    let student = sheetCells[rowNum][PgmConstants.timesheetStudentCol]
                    let date = sheetCells[rowNum][PgmConstants.timesheetDateCol]
                    let duration = Int(sheetCells[rowNum][PgmConstants.timesheetDurationCol]) ?? 0
                    let service = sheetCells[rowNum][PgmConstants.timesheetServiceCol]
                    let notes = sheetCells[rowNum][PgmConstants.timesheetDurationCol]
                    let cost = Float(sheetCells[rowNum][PgmConstants.timesheetCostCol]) ?? 0.0
                    let clientName = sheetCells[rowNum][PgmConstants.timesheetClientNameCol]
                    let clientEmail = sheetCells[rowNum][PgmConstants.timesheetClientEmailCol]
                    let clientPhone = sheetCells[rowNum][PgmConstants.timesheetClientPhoneCol]
                    let newTimesheetRow = TimesheetRow(studentName: student, serviceDate: date, duration: duration, serviceName: service, notes: notes, cost: cost, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone, tutorName: tutorName)
                    self.addTimesheetRow(timesheetRow: newTimesheetRow)
 //   print(tutorName, student, date, service)
                    entryCounter += 1
                }
                rowNum += 1
            }
        }
    }
    
}
