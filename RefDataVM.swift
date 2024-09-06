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

@Observable class RefDataVM  {
    
    var isStudentDataLoaded: Bool
    var isTutorDataLoaded: Bool
    var isServiceDataLoaded: Bool
    var isLocationDataLoaded: Bool

    init() {
        isStudentDataLoaded = false
        isTutorDataLoaded = false
        isServiceDataLoaded = false
        isLocationDataLoaded = false
    }
//
// This function loads the main reference data from the ReferenceData sheet.
// 1) Call Google Drive to search for for the Tutor's timesheet file name in order to get the file's Google File ID
// 2) If only a single file is retreived, call loadStudentServices to retrieve the Tutor's assigned Student list, Services list and Notes options as well as the Tutor service history for the month
//
    func readRefData(fileName: String, fileIDs: FileData, dataCounts: DataCounts, referenceData: ReferenceData) {
        
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
                        fileIDs.fileID = filesShow[0].identifier ?? ""
                        print(name, fileIDs.fileID)
                        self.loadReferenceData(fileIDs: fileIDs, dataCounts: dataCounts, referenceData: referenceData)
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
        var referenceFileID: String
        
        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
        }
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        
        let range = PgmConstants.dataCountRange
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: referenceFileID, range:range)
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
            dataCounts.totalStudents = Int(stringRows[PgmConstants.dataCountTotalStudentsRow][PgmConstants.dataCountTotalStudentsCol])! ?? 0
            dataCounts.activeStudents = Int(stringRows[PgmConstants.dataCountActiveStudentsRow][PgmConstants.dataCountActiveStudentsCol])! ?? 0
            dataCounts.highestStudentKey = Int(stringRows[PgmConstants.dataCountHighestStudentKeyRow][PgmConstants.dataCountHighestStudentKeyCol])! ?? 0
            dataCounts.totalTutors = Int(stringRows[PgmConstants.dataCountTotalTutorsRow][PgmConstants.dataCountTotalTutorsCol])! ?? 0
            dataCounts.activeTutors = Int(stringRows[PgmConstants.dataCountActiveTutorsRow][PgmConstants.dataCountActiveTutorsCol])! ?? 0
            dataCounts.highestTutorKey = Int(stringRows[PgmConstants.dataCountHighestTutorKeyRow][PgmConstants.dataCountHighestTutorKeyCol])! ?? 0
            dataCounts.totalServices = Int(stringRows[PgmConstants.dataCountTotalServicesRow][PgmConstants.dataCountTotalServicesCol])! ?? 0
            dataCounts.activeServices = Int(stringRows[PgmConstants.dataCountActiveServicesRow][PgmConstants.dataCountActiveServicesCol])! ?? 0
            dataCounts.highestServiceKey = Int(stringRows[PgmConstants.dataCountHighestServiceKeyRow][PgmConstants.dataCountHighestServiceKeyCol])! ?? 0
            dataCounts.totalLocations = Int(stringRows[PgmConstants.dataCountTotalLocationsRow][PgmConstants.dataCountTotalLocationsCol])! ?? 0
            dataCounts.highestLocationKey = Int(stringRows[PgmConstants.dataCountHighestLocationKeyRow][PgmConstants.dataCountHighestLocationKeyCol])! ?? 0
            
            self.loadTutorData(referenceFileID: referenceFileID, dataCounts:dataCounts, referenceData: referenceData, sheetService: sheetService )
            self.loadStudentData(referenceFileID: referenceFileID, dataCounts:dataCounts, referenceData: referenceData, sheetService: sheetService )
            self.loadServiceData(referenceFileID: referenceFileID, dataCounts:dataCounts, referenceData: referenceData, sheetService: sheetService )
            self.loadLocationData(referenceFileID: referenceFileID, dataCounts:dataCounts, referenceData: referenceData, sheetService: sheetService )
        }
    }
    
    func loadTutorData(referenceFileID: String, dataCounts: DataCounts, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        let range = PgmConstants.tutorRange + String(dataCounts.totalTutors + PgmConstants.tutorStartingRowNumber - 1)
//    print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: referenceFileID, range:range)
// Load Tutors from ReferenceData spreadsheet
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
        
// Load the Tutors
//            referenceData.tutorsList.removeAll()          // empty the array before loading as this could be a refresh
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
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
                var newTutorEndDate: Date? = dateFormatter.date(from: newTutorEndDateString)
                if let newTutorEndDate = newTutorEndDate {} else {
                    newTutorEndDate = nil
                }
                var newTutorMaxStudents = Int(stringRows[rowNumber][PgmConstants.tutorMaxStudentPosition])! ?? 0
                var newTutorStudentCount = Int(stringRows[rowNumber][PgmConstants.tutorStudentCountPosition])! ?? 0
                var newTutorServiceCount = Int(stringRows[rowNumber][PgmConstants.tutorServiceCountPosition])! ?? 0
                var newTutorTotalSessions = Int(stringRows[rowNumber][PgmConstants.tutorSessionCountPosition])! ?? 0
                var newTutorCost = Float(stringRows[rowNumber][PgmConstants.tutorTotalCostPosition])! ?? 0.0
                var newTutorRevenue = Float(stringRows[rowNumber][PgmConstants.tutorTotalRevenuePosition])! ?? 0.0
                var newTutorProfit = Float(stringRows[rowNumber][PgmConstants.tutorTotalProfitPosition])! ?? 0.0
                
                var newTutor = Tutor(tutorKey: newTutorKey, tutorName: newTutorName, tutorEmail: newTutorEmail, tutorPhone: newTutorPhone, tutorStatus: newTutorStatus, tutorStartDate: newTutorStartDate!, tutorEndDate: newTutorEndDate, tutorStudentCount: newTutorStudentCount, tutorServiceCount: newTutorServiceCount, tutorTotalSessions: newTutorTotalSessions, tutorTotalCost: newTutorCost, tutorTotalPrice: newTutorRevenue, tutorTotalProfit: newTutorProfit)
                referenceData.tutors.addTutor(newTutor: newTutor)
                tutorIndex += 1
                rowNumber += 1
            }
 //           referenceData.tutors.printAll()
            self.isTutorDataLoaded = true
        }
    }

    
    func loadStudentData(referenceFileID: String, dataCounts: DataCounts, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        let range = PgmConstants.studentRange + String(dataCounts.totalStudents + PgmConstants.studentStartingRowNumber - 1)
//        print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: referenceFileID, range:range)
// Load Students from ReferenceData spreadsheet
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
            
            // Load the Students
//           referenceData.studentList.removeAll()          // empty the array before loading as this could be a refresh
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var studentIndex = 0
            var rowNumber = 0
            while studentIndex < dataCounts.totalStudents {
                
                var newStudentKey = stringRows[rowNumber][PgmConstants.studentKeyPosition]
                var newStudentName = stringRows[rowNumber][PgmConstants.studentNamePosition]
                var newGuardianName = stringRows[rowNumber][PgmConstants.studentGuardianPosition]
                var newStudentPhone = stringRows[rowNumber][PgmConstants.studentPhonePosition]
                var newStudentEmail = stringRows[rowNumber][PgmConstants.studentEmailPosition]
                var newStudentType = stringRows[rowNumber][PgmConstants.studentTypePosition]
                var newStudentStartDateString = stringRows[rowNumber][PgmConstants.studentStartDatePosition]
                var newStudentStartDate = dateFormatter.date(from: newStudentStartDateString)
                var newStudentEndDateString = stringRows[rowNumber][PgmConstants.studentEndDatePosition]
                var newStudentEndDate = dateFormatter.date(from: newStudentEndDateString)
                var newStudentStatus = stringRows[rowNumber][PgmConstants.studentStatusPosition]
                var newStudentTutorKey = stringRows[rowNumber][PgmConstants.studentTutorKeyPosition]
                var newStudentTutorName = stringRows[rowNumber][PgmConstants.studentTutorNamePosition]
                var newStudentLocation = stringRows[rowNumber][PgmConstants.studentLocationPosition]
                var newStudentTotalSessions = Int(stringRows[rowNumber][PgmConstants.studentSessionsPosition])! ?? 0
                var newStudentCost = Float(stringRows[rowNumber][PgmConstants.studentTotalCostPosition])! ?? 0.0
                var newStudentRevenue = Float(stringRows[rowNumber][PgmConstants.studentTotalRevenuePosition])! ?? 0.0
                var newStudentProfit = Float(stringRows[rowNumber][PgmConstants.studentTotalProfitPosition])! ?? 0.0
                
                var newStudent = Student(studentKey: newStudentKey, studentName: newStudentName, studentGuardian: newGuardianName, studentPhone: newStudentPhone, studentEmail: newStudentEmail, studentType: newStudentType, studentStartDate: newStudentStartDate!, studentEndData: newStudentEndDate, studentStatus: newStudentStatus, studentTutorKey: newStudentTutorKey, studentTutorName: newStudentTutorName, studentLocation: newStudentLocation, studentSessions: newStudentTotalSessions, studentTotalCost: newStudentCost, studentTotalPrice: newStudentRevenue, studentTotalProfit: newStudentProfit)
                
                referenceData.students.addStudent(newStudent: newStudent)

                studentIndex += 1
                rowNumber += 1
            }

  //          referenceData.students.printAll()
            self.isStudentDataLoaded = true
        }
    }
    
    func loadServiceData(referenceFileID: String, dataCounts: DataCounts, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        let range = PgmConstants.serviceRange + String(dataCounts.totalServices + PgmConstants.serviceStartingRowNumber - 1)
//        print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: referenceFileID, range:range)
// Load Services from ReferenceData spreadsheet
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
            
// Load the Services
//            referenceData.serviceList.removeAll()          // empty the array before loading as this could be a refresh

            var serviceIndex = 0
            var rowNumber = 0
            while serviceIndex < dataCounts.totalServices {
                
                var newServiceKey = stringRows[rowNumber][PgmConstants.serviceKeyPosition]
                var newServiceTimesheetName = stringRows[rowNumber][PgmConstants.serviceTimesheetNamePosition]
                var newServiceInvoiceName = stringRows[rowNumber][PgmConstants.serviceInvoiceNamePosition]
                var newServiceType = stringRows[rowNumber][PgmConstants.serviceTypePosition]
                var newServiceBillingType = stringRows[rowNumber][PgmConstants.serviceBillingTypePosition]
                var newServiceStatus = stringRows[rowNumber][PgmConstants.serviceStatusPosition]
                var newServiceCost1 = Float(stringRows[rowNumber][PgmConstants.serviceCost1Position])! ?? 0.0
                var newServiceCost2 = Float(stringRows[rowNumber][PgmConstants.serviceCost2Position])! ?? 0.0
                var newServiceCost3 = Float(stringRows[rowNumber][PgmConstants.serviceCost3Position])! ?? 0.0
                var newServicePrice1 = Float(stringRows[rowNumber][PgmConstants.servicePrice1Position])! ?? 0.0
                var newServicePrice2 = Float(stringRows[rowNumber][PgmConstants.servicePrice2Position])! ?? 0.0
                var newServicePrice3 = Float(stringRows[rowNumber][PgmConstants.servicePrice3Position])! ?? 0.0
                
                let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: newServiceTimesheetName, serviceInvoiceName: newServiceInvoiceName, serviceType: newServiceType, serviceBillingType: newServiceBillingType, serviceStatus: newServiceStatus, serviceCost1: newServiceCost1, serviceCost2: newServiceCost2, serviceCost3: newServiceCost3, servicePrice1: newServicePrice1, servicePrice2: newServicePrice2, servicePrice3: newServicePrice3)
                
                referenceData.services.addService(newService: newService)
                serviceIndex += 1
                rowNumber += 1
            }
 //           referenceData.services.printAll()
            self.isServiceDataLoaded = true
        }
    }
    
    func loadLocationData(referenceFileID: String, dataCounts: DataCounts, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        let range = PgmConstants.locationRange + String(dataCounts.totalLocations + PgmConstants.locationStartingRowNumber - 1)
//        print("range is \(range)")
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: referenceFileID, range:range)
// Load Cities from ReferenceData spreadsheet
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
            
// Load the Locations
//           referenceData.citiesList.removeAll()          // empty the array before loading as this could be a refresh
            
            var locationIndex = 0
            var rowNumber = 0
            while locationIndex < dataCounts.totalLocations {
                
                var newLocationKey = stringRows[rowNumber][PgmConstants.locationKeyPosition]
                var newLocationName = stringRows[rowNumber][PgmConstants.locationNamePosition]
                var newLocationMonthRevenue = Float(stringRows[rowNumber][PgmConstants.locationMonthRevenuePosition])! ?? 0.0
                var newLocationTotalRevenue = Float(stringRows[rowNumber][PgmConstants.locationTotalRevenuePosition])! ?? 0.0

                let newLocation = Location(locationKey: newLocationKey, locationName: newLocationName, locationMonthRevenue: newLocationMonthRevenue, locationTotalRevenue: newLocationTotalRevenue)
                
                referenceData.locations.addLocation(newLocation: newLocation)
                locationIndex += 1
                rowNumber += 1
            }
  //          referenceData.cities.printAll()
            self.isLocationDataLoaded = true
        }
    }
}
