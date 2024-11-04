//
//  StudentsList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class StudentsList {
    var studentsList = [Student]()
    var isStudentDataLoaded: Bool
    
    init() {
        isStudentDataLoaded = false
    }
    
    func findStudentByKey(studentKey: String) -> (Bool, Int) {
        var found = false
        
        var studentNum = 0
        while studentNum < studentsList.count && !found {
            if studentsList[studentNum].studentKey == studentKey {
                found = true
            } else {
                studentNum += 1
            }
        }
        return(found, studentNum)
    }
    
    func findStudentByName(studentName: String) -> (Bool, Int) {
        var found = false
        
        var studentNum = 0
        while studentNum < studentsList.count && !found {
            if studentsList[studentNum].studentName == studentName {
                found = true
            } else {
                studentNum += 1
            }
        }
        return(found, studentNum)
    }
    
    func loadStudent(newStudent: Student, referenceData: ReferenceData) {
        self.studentsList.append(newStudent)
    }
 
    func addNewStudent(studentName: String, guardianName: String, contactEmail: String, contactPhone: String, studentType: StudentTypeOption, location: String, referenceData: ReferenceData) {
        
        let newStudentKey = PgmConstants.studentKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestStudentKey)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: Date())
        
        let newStudent = Student(studentKey: newStudentKey, studentName: studentName, studentGuardian: guardianName, studentPhone: contactPhone, studentEmail: contactEmail, studentType: studentType, studentStartDate: startDate, studentEndDate: " ", studentStatus: "Unassigned", studentTutorKey: " ", studentTutorName: " ", studentLocation: location, studentSessions: 0, studentTotalCost: 0.0, studentTotalRevenue: 0.0, studentTotalProfit: 0.0)
        self.studentsList.append(newStudent)
    }
    
    func printAll() {
        for student in studentsList {
            print ("Student Name is \(student.studentName)")
        }
    }
    
    
    func fetchStudentData(studentCount: Int) async {
 
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Read in the Student data from the Reference Data spreadsheet
        if studentCount > 0 {
            do {
                sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.studentRange + String(PgmConstants.studentStartingRowNumber + studentCount - 1) )
            } catch {
                
            }
            
            if let sheetData = sheetData {
                sheetCells = sheetData.values
            }
// Build the Students list from the cells read in
            loadStudentRows(studentCount: studentCount, sheetCells: sheetCells)
        }
    }
    
    func saveStudentData() async -> Bool {
        var result: Bool = true
// Write the Student rows to the Reference Data spreadsheet
        let updateValues = unloadStudentRows()
        let count = updateValues.count
        let range = PgmConstants.studentRange + String(PgmConstants.studentStartingRowNumber + updateValues.count - 1)
        do {
            result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Student Data rows failed")
           result = false
        }
        
        return(result)
    }
    
    func loadStudentRows(studentCount: Int, sheetCells: [[String]] ) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var studentIndex = 0
        var rowNumber = 0
        while studentIndex < studentCount {
            
            let newStudentKey = sheetCells[rowNumber][PgmConstants.studentKeyPosition]
            let newStudentName = sheetCells[rowNumber][PgmConstants.studentNamePosition]
            let newGuardianName = sheetCells[rowNumber][PgmConstants.studentGuardianPosition]
            let newStudentPhone = sheetCells[rowNumber][PgmConstants.studentPhonePosition]
            let newStudentEmail = sheetCells[rowNumber][PgmConstants.studentEmailPosition]
            let newStudentType:StudentTypeOption =  StudentTypeOption(rawValue: sheetCells[rowNumber][PgmConstants.studentTypePosition]) ?? .Minor
            let newStudentStartDateString = sheetCells[rowNumber][PgmConstants.studentStartDatePosition]
            //              let newStudentStartDate = dateFormatter.string(from: newStudentStartDateString)
            //              let newStudentStartDate = dateFormatter.string(from: Date())
            let newStudentEndDateString = sheetCells[rowNumber][PgmConstants.studentEndDatePosition]
            //              let newStudentEndDate = dateFormatter.date(from: newStudentEndDateString)
            let newStudentStatus = sheetCells[rowNumber][PgmConstants.studentStatusPosition]
            let newStudentTutorKey = sheetCells[rowNumber][PgmConstants.studentTutorKeyPosition]
            let newStudentTutorName = sheetCells[rowNumber][PgmConstants.studentTutorNamePosition]
            let newStudentLocation = sheetCells[rowNumber][PgmConstants.studentLocationPosition]
            let newStudentTotalSessions = Int(sheetCells[rowNumber][PgmConstants.studentSessionsPosition]) ?? 0
            let newStudentCost = Float(sheetCells[rowNumber][PgmConstants.studentTotalCostPosition]) ?? 0.0
            let newStudentRevenue = Float(sheetCells[rowNumber][PgmConstants.studentTotalRevenuePosition]) ?? 0.0
            let newStudentProfit = Float(sheetCells[rowNumber][PgmConstants.studentTotalProfitPosition]) ?? 0.0
            
            let newStudent = Student(studentKey: newStudentKey, studentName: newStudentName, studentGuardian: newGuardianName, studentPhone: newStudentPhone, studentEmail: newStudentEmail, studentType: newStudentType, studentStartDate: newStudentStartDateString, studentEndDate: newStudentEndDateString, studentStatus: newStudentStatus, studentTutorKey: newStudentTutorKey, studentTutorName: newStudentTutorName, studentLocation: newStudentLocation, studentSessions: newStudentTotalSessions, studentTotalCost: newStudentCost, studentTotalRevenue: newStudentRevenue, studentTotalProfit: newStudentProfit)
            
            self.studentsList.append(newStudent)
            
            studentIndex += 1
            rowNumber += 1
        }
        self.isStudentDataLoaded = true
        //          referenceData.students.printAll()
    }
    
    func unloadStudentRows() -> [[String]] {
        
        var updateValues = [[String]]()
        var studentNum = 0
        let studentCount = self.studentsList.count
        while studentNum < studentCount {
            let studentKey = studentsList[studentNum].studentKey
            let studentName = studentsList[studentNum].studentName
            let studentGuardian = studentsList[studentNum].studentGuardian
            let studentPhone = studentsList[studentNum].studentPhone
            let studentEmail = studentsList[studentNum].studentEmail
            let studentType = String(describing: studentsList[studentNum].studentType)
            let studentStartDate = studentsList[studentNum].studentStartDate
            let studentEndDate = studentsList[studentNum].studentEndDate
            let studentStatus = studentsList[studentNum].studentStatus
            let studentTutorKey = studentsList[studentNum].studentTutorKey
            let studentTutorName = studentsList[studentNum].studentTutorName
            let studentLocation = studentsList[studentNum].studentLocation
            let studentSessions = String(studentsList[studentNum].studentSessions)
            let studentTotalCost = String(studentsList[studentNum].studentTotalCost.formatted(.number.precision(.fractionLength(2))))
            let studentTotalRevenue = String(studentsList[studentNum].studentTotalRevenue.formatted(.number.precision(.fractionLength(2))))
            let studentTotalProfit = String(studentsList[studentNum].studentTotalProfit.formatted(.number.precision(.fractionLength(2))))

            updateValues.insert([studentKey, studentName, studentGuardian, studentPhone, studentEmail, studentType, studentStartDate, studentEndDate, studentStatus, studentTutorKey, studentTutorName, studentLocation, studentSessions, studentTotalCost, studentTotalRevenue, studentTotalProfit], at: studentNum)
            studentNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " "," ", " ", " ", " "," ", " ", " ", " "," ", " ", " ", " "], at: studentNum)
        return( updateValues)
    }
   
}
