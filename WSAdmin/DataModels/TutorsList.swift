//
//  TutorsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class TutorsList {
    var tutorsList = [Tutor]()
    var isTutorDataLoaded: Bool
    
    init() {
        isTutorDataLoaded = false
    }
    
    func loadTutor(newTutor: Tutor) {
        self.tutorsList.append(newTutor)
    }
    
    func printAll() {
        for tutor in tutorsList {
            print ("Tutor Name is \(tutor.tutorName)")
        }
    }
    
    func findTutorByKey(tutorKey: String) -> (Bool, Int) {
        var found = false
        
        var tutorNum = 0
        while tutorNum < tutorsList.count && !found {
            if tutorsList[tutorNum].tutorKey == tutorKey {
                found = true
            } else {
                tutorNum += 1
            }
        }
        return(found, tutorNum)
    }
    
    func findTutorByName(tutorName: String) -> (Bool, Int) {
        var found = false
        
        var tutorNum = 0
        while tutorNum < tutorsList.count && !found {
            if tutorsList[tutorNum].tutorName == tutorName {
                found = true
            } else {
                tutorNum += 1
            }
        }
        return(found, tutorNum)
    }
    
 
    func fetchTutorData(tutorCount: Int) async {
 
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Read in the Tutor data from the Reference Data spreadsheet
        if tutorCount > 0 {
            do {
                sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.tutorRange + String(PgmConstants.tutorStartingRowNumber + tutorCount - 1) )
            } catch {
                
            }
            
            if let sheetData = sheetData {
                sheetCells = sheetData.values
            }
// Build the Tutor list from the cells read in
            await loadTutorRows(tutorCount: tutorCount, sheetCells: sheetCells)
        }
    }
    
    func saveTutorData() async -> Bool {
        var result: Bool = true
// Write the Tutor rows to the Reference Data spreadsheet
        let updateValues = unloadTutorRows()
        let count = updateValues.count
        let range = PgmConstants.tutorRange + String(PgmConstants.tutorStartingRowNumber + updateValues.count - 1)
        do {
            result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Tutor Data rows failed")
           result = false
        }
        
        return(result)
    }
    
    func loadTutorRows(tutorCount: Int, sheetCells: [[String]] ) async {
        var tutorIndex = 0
        var rowNumber = 0
        while tutorIndex < tutorCount {
            
            let newTutorKey = sheetCells[rowNumber][PgmConstants.tutorKeyPosition]
            let newTutorName = sheetCells[rowNumber][PgmConstants.tutorNamePosition]
            let newTutorEmail = sheetCells[rowNumber][PgmConstants.tutorEmailPosition]
            let newTutorPhone = sheetCells[rowNumber][PgmConstants.tutorPhonePosition]
            let newTutorStatus = sheetCells[rowNumber][PgmConstants.tutorStatusPosition]
            let newTutorStartDateString = sheetCells[rowNumber][PgmConstants.tutorStartDatePosition]
//                let newTutorStartDate = dateFormatter.date(from: newTutorStartDateString)
            let newTutorEndDateString = sheetCells[rowNumber][PgmConstants.tutorEndDatePosition]
//                var newTutorEndDate: Date? = dateFormatter.date(from: newTutorEndDateString)
//                if var newTutorEndDate = newTutorEndDate {} else {
//                    newTutorEndDate = nil
//                }
            let newTutorMaxStudents = Int(sheetCells[rowNumber][PgmConstants.tutorMaxStudentPosition]) ?? 0
            let newTutorStudentCount = Int(sheetCells[rowNumber][PgmConstants.tutorStudentCountPosition]) ?? 0
            let newTutorServiceCount = Int(sheetCells[rowNumber][PgmConstants.tutorServiceCountPosition]) ?? 0
            let newTutorTotalSessions = Int(sheetCells[rowNumber][PgmConstants.tutorSessionCountPosition]) ?? 0
            let newTutorCost = Float(sheetCells[rowNumber][PgmConstants.tutorTotalCostPosition]) ?? 0.0
            let newTutorRevenue = Float(sheetCells[rowNumber][PgmConstants.tutorTotalRevenuePosition]) ?? 0.0
            let newTutorProfit = Float(sheetCells[rowNumber][PgmConstants.tutorTotalProfitPosition]) ?? 0.0
            
            let newTutor = Tutor(tutorKey: newTutorKey, tutorName: newTutorName, tutorEmail: newTutorEmail, tutorPhone: newTutorPhone, tutorStatus: newTutorStatus, tutorStartDate: newTutorStartDateString, tutorEndDate: newTutorEndDateString, tutorMaxStudents: newTutorMaxStudents, tutorStudentCount: newTutorStudentCount, tutorServiceCount: newTutorServiceCount, tutorTotalSessions: newTutorTotalSessions, tutorTotalCost: newTutorCost, tutorTotalRevenue: newTutorRevenue, tutorTotalProfit: newTutorProfit)
            self.tutorsList.append(newTutor)
            print("Loaded tutor \(newTutorName)")
            if newTutorStatus != "Deleted" {
                await self.tutorsList[tutorIndex].loadTutorDetails(tutorNum: tutorIndex, tutorName: newTutorName, tutorDataFileID: tutorDetailsFileID)
            }
            
            tutorIndex += 1
            rowNumber += 1
        }
        print("Loaded Base Tutor Data for \(tutorIndex) Tutors")
        self.isTutorDataLoaded = true
  
        //          referenceData.students.printAll()
    }
    
    func unloadTutorRows() -> [[String]] {
        
        var updateValues = [[String]]()
        
        var tutorNum = 0
        let tutorCount = self.tutorsList.count
        while tutorNum < tutorCount {
            let tutorKey = tutorsList[tutorNum].tutorKey
            let tutorName = tutorsList[tutorNum].tutorName
            let tutorPhone = tutorsList[tutorNum].tutorPhone
            let tutorEmail = tutorsList[tutorNum].tutorEmail
            let tutorStatus = tutorsList[tutorNum].tutorStatus
            let tutorStartDate = tutorsList[tutorNum].tutorStartDate
            let tutorEndDate = tutorsList[tutorNum].tutorEndDate
            let tutorMaxStudents = String(tutorsList[tutorNum].tutorMaxStudents)
            let tutorTotalStudents = String(tutorsList[tutorNum].tutorStudentCount)
            let tutorTotalServices = String(tutorsList[tutorNum].tutorServiceCount)
            let tutorTotalSessions = String(tutorsList[tutorNum].tutorTotalSessions)
            let tutorTotalCost = String(tutorsList[tutorNum].tutorTotalCost.formatted(.number.precision(.fractionLength(2))))
            let tutorTotalRevenue = String(tutorsList[tutorNum].tutorTotalRevenue.formatted(.number.precision(.fractionLength(2))))
            let tutorTotalProfit = String(tutorsList[tutorNum].tutorTotalProfit.formatted(.number.precision(.fractionLength(2))))
            
            updateValues.insert([tutorKey, tutorName, tutorEmail, tutorPhone, tutorStatus, tutorStartDate, tutorEndDate, tutorMaxStudents, tutorTotalStudents, tutorTotalServices, tutorTotalSessions, tutorTotalCost, tutorTotalRevenue, tutorTotalProfit], at: tutorNum)
            tutorNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " "," ", " ", " ", " "," ", " ", " ", " "," ", " "], at: tutorNum)

        return( updateValues)
    }

}


