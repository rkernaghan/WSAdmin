//
//  RefDataModel.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-02.
//

import Foundation

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class RefDataModel  {
    
    var isDataLoaded: Bool
    
    var referenceData = ReferenceData()
    var dataCounts = DataCounts()
    var fileIDs = FileData()
    
    init() {
        isDataLoaded = false
    }
//
// This function loads the main reference data from the ReferenceData sheet.
// 1) Call Google Drive to search for for the Tutor's timesheet file name in order to get the file's Google File ID
// 2) If only a single file is retreived, call loadStudentServices to retrieve the Tutor's assigned Student list, Services list and Notes options as well as the Tutor service history for the month
//
    func readRefData(fileName: String) {
        
        print("Getting fileID for '\(fileName)'")
        
        let sheetService = GTLRSheetsService()
        let driveService = GTLRDriveService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        driveService.authorizer = currentUser?.fetcherAuthorizer
        
        let dquery = GTLRDriveQuery_FilesList.query()
        dquery.pageSize = 100
        
        let root = "name = '\(fileName)' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed=false"
        dquery.q = root
        dquery.spaces = "drive"
        dquery.corpora = "user"
        dquery.fields = "files(id,name),nextPageToken"
// Retreive all files with Tutor timesheet name (should only be one)
        driveService.executeQuery(dquery, completionHandler: {(ticket, files, error) in
            if let filesList : GTLRDrive_FileList = files as? GTLRDrive_FileList {
                
                if let filesShow : [GTLRDrive_File] = filesList.files {
                    let fileCount = filesShow.count
                    switch fileCount {
                    case 0:
                        print("Tutor timesheet file not found - '\(fileName)")
                        GIDSignIn.sharedInstance.signOut()
                    case 1:
                        let name = filesShow[0].name ?? ""
                        self.fileIDs.referenceDataFile = filesShow[0].identifier ?? ""
                        print(name, self.fileIDs.referenceDataFile)
                        self.loadReferenceData(fileIDs: self.fileIDs, dataCounts: self.dataCounts, referenceData: self.referenceData)
                    default:
                        print("Error: more than one tutor timesheet for '\(fileName)")
                        GIDSignIn.sharedInstance.signOut()
                    }
                } else {
                    print("no files returned")
                }
            }
            else {
                    print("error no files returned from Drive search call")
                    return
                }
        })
    }
    
   
    func loadReferenceData(fileIDs: FileData, dataCounts: DataCounts, referenceData: ReferenceData)  {
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        
        let range = PgmConstants.dataCountRange
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: fileIDs.referenceDataFile, range:range)
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
            
            print("Total Student count is '\(rows[0][1])")
            print("Active Student count is '\(rows[1][1])")
            print("Highest STudent Key is '\(rows[2][1])")
            
            print("Number of rows in sheet: \(rows.count)")
            dataCounts.totalStudents = Int(stringRows[0][1])! ?? 0
            dataCounts.activeStudents = Int(stringRows[1][1])! ?? 0
            dataCounts.highestStudentKey = Int(stringRows[2][1])! ?? 0
            dataCounts.totalTutors = Int(stringRows[3][1])! ?? 0
            dataCounts.activeTutors = Int(stringRows[4][1])! ?? 0
            dataCounts.highestTutorKey = Int(stringRows[6][1])! ?? 0
            dataCounts.totalServices = Int(stringRows[7][1])! ?? 0
            dataCounts.activeServices = Int(stringRows[8][1])! ?? 0
            dataCounts.highestServiceKey = Int(stringRows[9][1])! ?? 0
            dataCounts.totalCities = Int(stringRows[10][1])! ?? 0
            dataCounts.highestCityKey = Int(stringRows[11][1])! ?? 0
            
            
            // Load the Tutors
            referenceData.tutorList.removeAll()          // empty the array before loading as this could be a refresh
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy"
            
            var tutorIndex = 0
            var rowNumber = 0
            while tutorIndex < dataCounts.totalTutors {
                
                var newTutorKey = stringRows[rowNumber][PgmConstants.tutorKeyPosition]
                var newTutorName = stringRows[rowNumber][PgmConstants.tutorNamePosition]
                var newTutorEmail = stringRows[rowNumber][PgmConstants.tutorEmailPosition]
                var newTutorPhone = stringRows[rowNumber][PgmConstants.tutorPhonePosition]
                var newTutorStatus = stringRows[rowNumber][PgmConstants.tutorStatusPosition]
                var newTutorStartDateString = stringRows[rowNumber][PgmConstants.tutorStartDatePosition]
                var newTutorStartDate = dateFormatter.date(from: newTutorStartDateString)
                var newTutorEndDateString = stringRows[rowNumber][PgmConstants.tutorEndDatePosition]
                var newTutorEndDate = dateFormatter.date(from: newTutorEndDateString)
                var newTutorMaxStudents = Int(stringRows[rowNumber][PgmConstants.tutorMaxStudentPosition])! ?? 0
                var newTutorStudentCount = Int(stringRows[rowNumber][PgmConstants.tutorStudentCountPosition])! ?? 0
                var newTutorServiceCount = Int(stringRows[rowNumber][PgmConstants.tutorServiceCountPosition])! ?? 0
                var newTutorTotalSessions = Int(stringRows[rowNumber][PgmConstants.tutorSessionCountPosition])! ?? 0
                var newTutorCost = Float(stringRows[rowNumber][PgmConstants.tutorTotalCostPosition])! ?? 0.0
                var newTutorRevenue = Float(stringRows[rowNumber][PgmConstants.tutorTotalRevenuePosition])! ?? 0.0
                var newTutorProfit = Float(stringRows[rowNumber][PgmConstants.tutorTotalProfitPosition])! ?? 0
                
                var newTutor = TutorData(tutorKey: newTutorKey, tutorName: newTutorName, tutorEmail: newTutorEmail, tutorPhone: newTutorPhone, tutorStatus: newTutorStatus, tutorStartDate: newTutorStartDate!, tutorEndDate: newTutorEndDate!, tutorStudentCount: newTutorStudentCount, tutorServiceCount: newTutorServiceCount, tutorTotalSessions: newTutorTotalSessions, tutorTotalCost: newTutorCost, tutorTotalPrice: newTutorRevenue, tutorTotalProfit: newTutorProfit)
                referenceData.tutorList.insert(newTutor, at: tutorIndex)
                tutorIndex += 1
                rowNumber += 1
            }
            
        }
    }
}
    
