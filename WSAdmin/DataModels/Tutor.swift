//
//  Tutor.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class Tutor: Identifiable {
    var tutorKey: String
    var tutorName: String
    var tutorEmail: String
    var tutorPhone: String
    var tutorStatus: String
    var tutorStartDate: String
    var tutorEndDate: String
    var tutorMaxStudents: Int
    var tutorStudentCount: Int
    var tutorServiceCount: Int
    var tutorTotalSessions: Int
    var tutorTotalCost: Float
    var tutorTotalRevenue: Float
    var tutorTotalProfit: Float
    var tutorStudents = [TutorStudent]()
    var tutorServices = [TutorService]()
    let id = UUID()
    
    init(tutorKey: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorStatus: String, tutorStartDate: String, tutorEndDate: String, tutorMaxStudents: Int, tutorStudentCount: Int, tutorServiceCount: Int, tutorTotalSessions: Int, tutorTotalCost: Float, tutorTotalRevenue: Float, tutorTotalProfit: Float) {
        self.tutorKey = tutorKey
        self.tutorName = tutorName
        self.tutorEmail = tutorEmail
        self.tutorPhone = tutorPhone
        self.tutorStatus = tutorStatus
        self.tutorStartDate = tutorStartDate
        self.tutorEndDate = tutorEndDate
        self.tutorMaxStudents = tutorMaxStudents
        self.tutorStudentCount = tutorStudentCount
        self.tutorServiceCount = tutorServiceCount
        self.tutorTotalSessions = tutorTotalSessions
        self.tutorTotalCost = tutorTotalCost
        self.tutorTotalRevenue = tutorTotalRevenue
        self.tutorTotalProfit = tutorTotalProfit
    }
    
    func findTutorStudentByKey(studentKey: String) -> (Bool, Int) {
        var studentFound = false
        var tutorStudentNum = 0
        
        while tutorStudentNum < tutorStudents.count && !studentFound {
            if tutorStudents[tutorStudentNum].studentKey == studentKey {
                studentFound = true
            } else {
                tutorStudentNum += 1
            }
        }
        return(studentFound, tutorStudentNum)
    }
    
    func findTutorServiceByKey(serviceKey: String) -> (Bool, Int) {
        var serviceFound = false
        var tutorServiceNum = 0
        
        while tutorServiceNum < tutorServices.count && !serviceFound {
            if tutorServices[tutorServiceNum].serviceKey == serviceKey {
                serviceFound = true
            } else {
                tutorServiceNum += 1
            }
        }
        return(serviceFound, tutorServiceNum)
    }
    
    func findTutorServiceByName(serviceName: String) -> (Bool, Int) {
        var serviceFound = false
        var tutorServiceNum = 0
        
        while tutorServiceNum < tutorServices.count && !serviceFound {
            if tutorServices[tutorServiceNum].timesheetServiceName == serviceName {
                serviceFound = true
            } else {
                tutorServiceNum += 1
            }
        }
        return(serviceFound, tutorServiceNum)
    }
    
    func loadTutorStudent(newTutorStudent: TutorStudent) {
        tutorStudents.append(newTutorStudent)
    }
    
    func addNewTutorStudent(newTutorStudent: TutorStudent) async {
        tutorStudents.append(newTutorStudent)
        await saveTutorStudentData()
        tutorStudentCount += 1
        await saveTutorDataCounts()
        self.tutorStatus = "Assigned"
    }
    
    func updateTutor(contactEmail: String, contactPhone: String, maxStudents: Int) {
        self.tutorEmail = contactEmail
        self.tutorPhone = contactPhone
        self.tutorMaxStudents = maxStudents
    }
    
    func removeTutorStudent(studentKey: String) async {
        let (studentFound, tutorStudentNum) = findTutorStudentByKey(studentKey: studentKey)
        
        if studentFound {
            tutorStudents.remove(at: tutorStudentNum)
            await saveTutorStudentData()
            tutorStudentCount -= 1
            await saveTutorDataCounts()
            
            if tutorStudentCount == 0 {
                self.tutorStatus = "Unassigned"
            }
        }
    }
    
    func loadTutorService(newTutorService: TutorService) {
        tutorServices.append(newTutorService)
    }
    
    func addNewTutorService(newTutorService: TutorService) async {
        tutorServices.append(newTutorService)
        await saveTutorServiceData()
        tutorServiceCount += 1
        await saveTutorDataCounts()
    }
    
    func updateTutorService(tutorServiceNum: Int, timesheetName: String, invoiceName: String, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) async {
        tutorServices[tutorServiceNum].timesheetServiceName = timesheetName
        tutorServices[tutorServiceNum].invoiceServiceName = invoiceName
        tutorServices[tutorServiceNum].billingType = billingType
        tutorServices[tutorServiceNum].cost1 = cost1
        tutorServices[tutorServiceNum].cost2 = cost2
        tutorServices[tutorServiceNum].cost3 = cost3
        tutorServices[tutorServiceNum].totalCost = cost1 + cost2 + cost3
        tutorServices[tutorServiceNum].price1 = price1
        tutorServices[tutorServiceNum].price2 = price2
        tutorServices[tutorServiceNum].price3 = price3
        tutorServices[tutorServiceNum].totalPrice = price1 + price2 + price3
        await saveTutorServiceData()
    }

    func removeTutorService(serviceKey: String) async {
        let (serviceFound, tutorServiceNum) = findTutorServiceByKey(serviceKey: serviceKey)
        
        if serviceFound {
            tutorServices.remove(at: tutorServiceNum)
            await saveTutorServiceData()
            tutorServiceCount -= 1
            await saveTutorDataCounts()
        }
    }
    
    func markDeleted() {
        tutorStatus = "Deleted"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        tutorEndDate = dateFormatter.string(from: Date())
    }
    
    func markUnDeleted() {
        tutorStatus = "Unassigned"
        tutorEndDate = " "
    }
    
    func unassignTutor() {
 
    }
        
    func resetBillingStats(sessionCost: Float, sessionRevenue: Float) {
        self.tutorTotalSessions -= 1
        self.tutorTotalCost -= sessionCost
        self.tutorTotalRevenue -= sessionRevenue
        self.tutorTotalProfit -= sessionRevenue - sessionCost
    }
    
    func loadTutorDetails(tutorNum: Int, tutorName: String, tutorDataFileID: String) async {
                
        print("Tutor \(tutorName) Students: \(self.tutorStudentCount) Services: \(self.tutorServiceCount)")
        
        if self.tutorServiceCount > 0 {
            await self.fetchTutorServiceData( tutorName: tutorName, tutorServiceCount: tutorServiceCount)
        }

        if self.tutorStudentCount > 0 {
            await self.fetchTutorStudentData( tutorName: tutorName, tutorStudentCount: tutorStudentCount)
        }
    }
    
    func loadTutorDetailsOld(tutorNum: Int, tutorDataFileID: String, referenceData: ReferenceData) {
        
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer
        
        let tutorStudentCount = tutorStudentCount
        let tutorServiceCount = tutorServiceCount
        
        print("Tutor \(tutorName) Students: \(tutorStudentCount) Services: \(tutorServiceCount)")
        
        if tutorServiceCount > 0 {
            self.loadTutorServicesOLD(tutorNum: tutorNum, tutorDataFileID: tutorDataFileID, serviceCount: tutorServiceCount, referenceData: referenceData, sheetService: sheetService)
        }

        if tutorStudentCount > 0 {
            self.loadTutorStudentsOLD(tutorNum: tutorNum, tutorDataFileID: tutorDataFileID, studentCount: tutorStudentCount, referenceData: referenceData, sheetService: sheetService)
        }
    }
    
    func saveTutorDataCounts() async {
        var result: Bool = true
        var updateValues = [[String]]()
        
        let range = tutorName + PgmConstants.tutorDataCountsRange
        print("Tutor Data Counts Save Range", range)
  
        tutorStudentCount = tutorStudents.count
        tutorServiceCount = tutorServices.count
                      
        updateValues = [[String(tutorStudentCount)], [String(tutorServiceCount)]]

        do {
            result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Tutor Data Counts failed")
           result = false
        }
    }
    
    func saveTutorDataCountsOLD() {
        var tutorStudentCount: Int
        var tutorServiceCount: Int
        var updateValues: [[String]] = []
        
        let sheetService = GTLRSheetsService()
        let tutorStudentTotal = tutorStudents.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer

        let range = tutorName + PgmConstants.tutorDataCountsRange
        print("Tutor Data Counts Save Range", range)
  
        tutorStudentCount = tutorStudents.count
        tutorServiceCount = tutorServices.count
                      
        updateValues = [[String(tutorStudentCount)], [String(tutorServiceCount)]]

        let valueRange = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
        valueRange.majorDimension = "ROWS" // Indicates horizontal row insert
        valueRange.range = range
        valueRange.values = updateValues
        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: tutorDetailsFileID, range: range)
        query.valueInputOption = "USER_ENTERED"
        sheetService.executeQuery(query) { ticket, object, error in
            if let error = error {
                print(error)
                print("Failed to save data:\(error.localizedDescription)")
                return
            }
            else {
                print("Tutor Data Counts saved")
            }
        }
    }
    
    
    func loadTutorStudentsOLD(tutorNum: Int, tutorDataFileID: String, studentCount: Int, referenceData: ReferenceData, sheetService: GTLRSheetsService) {
        
        print("Loading \(studentCount) Students for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
        let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
            
        let range = tutorName + PgmConstants.tutorStudentsRange + String(studentCount + PgmConstants.tutorDataStudentsStartingRowNumber)
//            print("Tutor Students Load range is '\(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet
                .query(withSpreadsheetId: tutorDataFileID, range:range)
            // Load data counts from ReferenceData spreadsheet
            sheetService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print("Error loading Tutor Students Data for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
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
                
                var rowNum = 0
                var studentNum = 0
                while studentNum < studentCount {
                    let studentKey = stringRows[rowNum][PgmConstants.tutorDataStudentKeyPosition]
                    let studentName = stringRows[rowNum][PgmConstants.tutorDataStudentNamePosition]
                    let clientName = stringRows[rowNum][PgmConstants.tutorDataStudentClientNamePosition]
                    let clientEmail = stringRows[rowNum][PgmConstants.tutorDataStudentClientEmailPosition]
                    let clientPhone = stringRows[rowNum][PgmConstants.tutorDataStudentClientPhonePosition]
                    
                    let newTutorStudent = TutorStudent(studentKey: studentKey, studentName: studentName, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone)
                    
                    self.loadTutorStudent( newTutorStudent: newTutorStudent)
                    rowNum += 1
                    studentNum += 1
                }
                print("Loaded \(studentCount) Students for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
            }
        }
    
    
    func saveTutorStudentsOLD() {
   
        var updateValues: [[String]] = []
        
        var studentKey: String = " "
        var studentName: String = " "
        var clientName: String = " "
        var clientEmail: String = " "
        var clientPhone: String = " "
        
        
        let sheetService = GTLRSheetsService()
        let tutorStudentTotal = tutorStudents.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer

        let range = tutorName + PgmConstants.tutorStudentsRange + String(tutorStudentTotal + PgmConstants.tutorDataStudentsStartingRowNumber + 1)              //One extra row for blanking line at end
        print("Tutor Data Save Range", range)
  
        var tutorStudentNum = 0
        while tutorStudentNum < tutorStudentTotal {
            studentKey = tutorStudents[tutorStudentNum].studentKey
            studentName = tutorStudents[tutorStudentNum].studentName
            clientName = tutorStudents[tutorStudentNum].clientName
            clientEmail = tutorStudents[tutorStudentNum].clientEmail
            clientPhone = tutorStudents[tutorStudentNum].clientPhone
              
            updateValues.insert([studentKey, studentName, clientName, clientEmail, clientPhone], at: tutorStudentNum)
            tutorStudentNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " "], at: tutorStudentNum)
        
        let valueRange = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
        valueRange.majorDimension = "ROWS" // Indicates horizontal row insert
        valueRange.range = range
        valueRange.values = updateValues
        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: tutorDetailsFileID, range: range)
        query.valueInputOption = "USER_ENTERED"
        sheetService.executeQuery(query) { ticket, object, error in
            if let error = error {
                print(error)
                print("Failed to save data:\(error.localizedDescription)")
                return
            }
            else {
                print("Tutor Students saved")
            }
        }
    }
    
    
    func loadTutorServicesOLD(tutorNum: Int, tutorDataFileID: String, serviceCount: Int, referenceData: ReferenceData, sheetService: GTLRSheetsService ) {
       
        print("Loading \(serviceCount) Services for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
        let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
            
        let range = tutorName + PgmConstants.tutorServicesRange + String(serviceCount + PgmConstants.tutorDataServicesStartingRowNumber)
 //           print("Tutor Services Load range is '\(range)")
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet
                .query(withSpreadsheetId: tutorDataFileID, range:range)
            // Load data counts from ReferenceData spreadsheet
            sheetService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print("Error loading Tutor Services Data for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
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
                
                var rowNum = 0
                var serviceNum = 0
                while serviceNum < serviceCount {
                    let serviceKey = stringRows[rowNum][PgmConstants.tutorDataServiceKeyPosition]
                    let timesheetName = stringRows[rowNum][PgmConstants.tutorDataServiceTimesheetNamePosition]
                    let invoiceName = stringRows[rowNum][PgmConstants.tutorDataServiceInvoiceNamePosition]
                    let billingType: BillingTypeOption = BillingTypeOption(rawValue: stringRows[rowNum][PgmConstants.tutorDataServiceBillingTypePosition]) ?? .Fixed
                    let cost1 = Float(stringRows[rowNum][PgmConstants.tutorDataServiceCost1Position]) ?? 0.0
                    let cost2 = Float(stringRows[rowNum][PgmConstants.tutorDataServiceCost2Position]) ?? 0.0
                    let cost3 = Float(stringRows[rowNum][PgmConstants.tutorDataServiceCost3Position]) ?? 0.0
                    let price1 = Float(stringRows[rowNum][PgmConstants.tutorDataServicePrice1Position]) ?? 0.0
                    let price2 = Float(stringRows[rowNum][PgmConstants.tutorDataServicePrice2Position]) ?? 0.0
                                       let price3 = Float(stringRows[rowNum][PgmConstants.tutorDataServicePrice3Position]) ?? 0.0
                    
                    let newTutorService = TutorService(serviceKey: serviceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
                    
                    self.loadTutorService( newTutorService: newTutorService)
                    rowNum += 1
                    serviceNum += 1
                }
                print("Loaded \(serviceCount) Services for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
            }
    }
    
    func saveTutorServicesOLD() {

        var updateValues: [[String]] = []
        
        var serviceKey: String = " "
        var timesheetName: String = " "
        var invoiceName: String = " "
        var billingType: String = " "
        var cost1: String = " "
        var cost2: String = " "
        var cost3: String = " "
        var price1: String = " "
        var price2: String = " "
        var price3: String = " "
        
        let sheetService = GTLRSheetsService()

        let tutorServiceTotal = tutorServices.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer

        let range = tutorName + PgmConstants.tutorServicesRange + String(tutorServiceTotal + PgmConstants.tutorDataServicesStartingRowNumber + 1)              //One extra row for blanking line at end
        print("Tutor Services Save Range", range)
  
        var tutorServiceNum = 0
        while tutorServiceNum < tutorServiceTotal {
            serviceKey = tutorServices[tutorServiceNum].serviceKey
            timesheetName = tutorServices[tutorServiceNum].timesheetServiceName
            invoiceName = tutorServices[tutorServiceNum].invoiceServiceName
            billingType = String(describing: tutorServices[tutorServiceNum].billingType)
            cost1 = String(tutorServices[tutorServiceNum].cost1.formatted(.number.precision(.fractionLength(2))))
            cost2 = String(tutorServices[tutorServiceNum].cost2.formatted(.number.precision(.fractionLength(2))))
            cost3 = String(tutorServices[tutorServiceNum].cost3.formatted(.number.precision(.fractionLength(2))))
            price1 = String(tutorServices[tutorServiceNum].price1.formatted(.number.precision(.fractionLength(2))))
            price2 = String(tutorServices[tutorServiceNum].price2.formatted(.number.precision(.fractionLength(2))))
            price3 = String(tutorServices[tutorServiceNum].price3.formatted(.number.precision(.fractionLength(2))))

            updateValues.insert([serviceKey, timesheetName, invoiceName, billingType, cost1, cost2, cost3, price1, price2, price3], at: tutorServiceNum)
            tutorServiceNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: tutorServiceNum)
        
        let valueRange = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
        valueRange.majorDimension = "ROWS" // Indicates horizontal row insert
        valueRange.range = range
        valueRange.values = updateValues
        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: tutorDetailsFileID, range: range)
        query.valueInputOption = "USER_ENTERED"
        sheetService.executeQuery(query) { ticket, object, error in
            if let error = error {
                print(error)
                print("Failed to save data:\(error.localizedDescription)")
                return
            }
            else {
                print("Tutor Services saved")
            }
        }
    }

    func fetchTutorStudentData(tutorName: String, tutorStudentCount: Int) async {
 
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Read in the Tutor Students data from the Tutor Details spreadsheet
        if tutorStudentCount > 0 {
            do {
                let range = tutorName + PgmConstants.tutorStudentsRange + String(PgmConstants.tutorDataStudentsStartingRowNumber + tutorStudentCount - 1)
                sheetData = try await readSheetCells(fileID: tutorDetailsFileID, range: range )
            } catch {
                
            }
            
            if let sheetData = sheetData {
                sheetCells = sheetData.values
            }
// Build the Tutor Students list from the cells read in
            loadTutorStudentRows(tutorStudentCount: tutorStudentCount, sheetCells: sheetCells)
        }
    }
    
    func saveTutorStudentData() async -> Bool {
        var result: Bool = true
// Write the Tutor Student rows to the Tutor Details spreadsheet
        let updateValues = unloadTutorServiceRows()
        let count = updateValues.count
        let range = PgmConstants.tutorServicesRange + String(PgmConstants.tutorDataServicesStartingRowNumber + updateValues.count - 1)
        do {
            result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Tutor Services data rows failed")
           result = false
        }
        
        return(result)
    }
    
    func loadTutorStudentRows(tutorStudentCount: Int, sheetCells: [[String]] ) {
        var rowNum = 0
        var studentNum = 0
        while studentNum < tutorStudentCount {
            let studentKey = sheetCells[rowNum][PgmConstants.tutorDataStudentKeyPosition]
            let studentName = sheetCells[rowNum][PgmConstants.tutorDataStudentNamePosition]
            let clientName = sheetCells[rowNum][PgmConstants.tutorDataStudentClientNamePosition]
            let clientEmail = sheetCells[rowNum][PgmConstants.tutorDataStudentClientEmailPosition]
            let clientPhone = sheetCells[rowNum][PgmConstants.tutorDataStudentClientPhonePosition]
            
            let newTutorStudent = TutorStudent(studentKey: studentKey, studentName: studentName, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone)
            
            self.loadTutorStudent( newTutorStudent: newTutorStudent)
            rowNum += 1
            studentNum += 1
        }
 //       print("Loaded \(studentCount) Students for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
    }
    
    func unloadTutorStudentRows() -> [[String]] {
        
        var updateValues = [[String]]()
        
        var tutorStudentNum = 0
        let tutorStudentCount = tutorStudents.count
        while tutorStudentNum < tutorStudentCount {
            let studentKey = tutorStudents[tutorStudentNum].studentKey
            let studentName = tutorStudents[tutorStudentNum].studentName
            let clientName = tutorStudents[tutorStudentNum].clientName
            let clientEmail = tutorStudents[tutorStudentNum].clientEmail
            let clientPhone = tutorStudents[tutorStudentNum].clientPhone
              
            updateValues.insert([studentKey, studentName, clientName, clientEmail, clientPhone], at: tutorStudentNum)
            tutorStudentNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " "], at: tutorStudentNum)
        
        return(updateValues)
    }
    
    func fetchTutorServiceData(tutorName: String, tutorServiceCount: Int) async {
 
        var sheetCells = [[String]]()
        var sheetData: SheetData?
        
// Read in the Tutor Services data from the Tutor Details spreadsheet
        if tutorServiceCount > 0 {
            do {
                let range = tutorName + PgmConstants.tutorServicesRange + String(PgmConstants.tutorDataServicesStartingRowNumber + tutorServiceCount - 1)
                sheetData = try await readSheetCells(fileID: tutorDetailsFileID, range: range) 
            } catch {
                
            }
            
            if let sheetData = sheetData {
                sheetCells = sheetData.values
            }
// Build the Tutor Services list from the cells read in
            loadTutorServiceRows(tutorServiceCount: tutorServiceCount, sheetCells: sheetCells)
        }
    }
    
    func saveTutorServiceData() async -> Bool {
        var result: Bool = true
// Write the Tutor Services rows to the Tutor Details spreadsheet
        let updateValues = unloadTutorServiceRows()
        let count = updateValues.count
        let range = PgmConstants.tutorServicesRange + String(PgmConstants.tutorDataServicesStartingRowNumber + updateValues.count - 1)
        do {
            result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
        } catch {
            print ("Error: Saving Tutor Services data rows failed")
           result = false
        }
        
        return(result)
    }
    
    
    func loadTutorServiceRows(tutorServiceCount: Int, sheetCells: [[String]] ) {
        var rowNum = 0
        var serviceNum = 0
        
        while serviceNum < tutorServiceCount {
            let serviceKey = sheetCells[rowNum][PgmConstants.tutorDataServiceKeyPosition]
            let timesheetName = sheetCells[rowNum][PgmConstants.tutorDataServiceTimesheetNamePosition]
            let invoiceName = sheetCells[rowNum][PgmConstants.tutorDataServiceInvoiceNamePosition]
            let billingType: BillingTypeOption = BillingTypeOption(rawValue: sheetCells[rowNum][PgmConstants.tutorDataServiceBillingTypePosition]) ?? .Fixed
            let cost1 = Float(sheetCells[rowNum][PgmConstants.tutorDataServiceCost1Position]) ?? 0.0
            let cost2 = Float(sheetCells[rowNum][PgmConstants.tutorDataServiceCost2Position]) ?? 0.0
            let cost3 = Float(sheetCells[rowNum][PgmConstants.tutorDataServiceCost3Position]) ?? 0.0
            let price1 = Float(sheetCells[rowNum][PgmConstants.tutorDataServicePrice1Position]) ?? 0.0
            let price2 = Float(sheetCells[rowNum][PgmConstants.tutorDataServicePrice2Position]) ?? 0.0
            let price3 = Float(sheetCells[rowNum][PgmConstants.tutorDataServicePrice3Position]) ?? 0.0
            
            let newTutorService = TutorService(serviceKey: serviceKey, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
            
            self.loadTutorService( newTutorService: newTutorService)
            rowNum += 1
            serviceNum += 1
        }
 //       print("Loaded \(serviceCount) Services for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
    }
    
    func unloadTutorServiceRows() -> [[String]] {
        
        var updateValues = [[String]]()
        
        var tutorServiceNum = 0
        let tutorServiceCount = tutorServices.count
        while tutorServiceNum < tutorServiceCount {
            let serviceKey = tutorServices[tutorServiceNum].serviceKey
            let timesheetName = tutorServices[tutorServiceNum].timesheetServiceName
            let invoiceName = tutorServices[tutorServiceNum].invoiceServiceName
            let billingType = String(describing: tutorServices[tutorServiceNum].billingType)
            let cost1 = String(tutorServices[tutorServiceNum].cost1.formatted(.number.precision(.fractionLength(2))))
            let cost2 = String(tutorServices[tutorServiceNum].cost2.formatted(.number.precision(.fractionLength(2))))
            let cost3 = String(tutorServices[tutorServiceNum].cost3.formatted(.number.precision(.fractionLength(2))))
            let price1 = String(tutorServices[tutorServiceNum].price1.formatted(.number.precision(.fractionLength(2))))
            let price2 = String(tutorServices[tutorServiceNum].price2.formatted(.number.precision(.fractionLength(2))))
            let price3 = String(tutorServices[tutorServiceNum].price3.formatted(.number.precision(.fractionLength(2))))

            updateValues.insert([serviceKey, timesheetName, invoiceName, billingType, cost1, cost2, cost3, price1, price2, price3], at: tutorServiceNum)
            tutorServiceNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: tutorServiceNum)
        return(updateValues)
    }
    
}
