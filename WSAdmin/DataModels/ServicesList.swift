//
//  ServicesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

@Observable class ServicesList {
    var servicesList = [Service]()
    var isServiceDataLoaded: Bool
    
    init() {
        isServiceDataLoaded = false
    }
    
    func loadService(newService: Service, referenceData: ReferenceData) {
        self.servicesList.append(newService)

    }
    
    func printAll() {
        for service in servicesList {
            print ("Service Name is \(service.serviceTimesheetName)")
        }
    }
    
    func loadServiceData(referenceFileID: String, referenceData: ReferenceData) {
     
        let sheetService = GTLRSheetsService()
        let currentUser = GIDSignIn.sharedInstance.currentUser
        sheetService.authorizer = currentUser?.fetcherAuthorizer

        let range = PgmConstants.serviceRange + String(referenceData.dataCounts.totalServices + PgmConstants.serviceStartingRowNumber - 1)
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
            while serviceIndex < referenceData.dataCounts.totalServices {
                
                let newServiceKey = stringRows[rowNumber][PgmConstants.serviceKeyPosition]
                let newServiceTimesheetName = stringRows[rowNumber][PgmConstants.serviceTimesheetNamePosition]
                let newServiceInvoiceName = stringRows[rowNumber][PgmConstants.serviceInvoiceNamePosition]
                let newServiceType = String(describing: stringRows[rowNumber][PgmConstants.serviceTypePosition])
                let newServiceBillingType = String(describing: stringRows[rowNumber][PgmConstants.serviceBillingTypePosition])
                let newServiceStatus = stringRows[rowNumber][PgmConstants.serviceStatusPosition]
                let newServiceCost1 = Float(stringRows[rowNumber][PgmConstants.serviceCost1Position]) ?? 0.0
                let newServiceCost2 = Float(stringRows[rowNumber][PgmConstants.serviceCost2Position]) ?? 0.0
                let newServiceCost3 = Float(stringRows[rowNumber][PgmConstants.serviceCost3Position]) ?? 0.0
                let newServicePrice1 = Float(stringRows[rowNumber][PgmConstants.servicePrice1Position]) ?? 0.0
                let newServicePrice2 = Float(stringRows[rowNumber][PgmConstants.servicePrice2Position]) ?? 0.0
                let newServicePrice3 = Float(stringRows[rowNumber][PgmConstants.servicePrice3Position]) ?? 0.0
                
                let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: newServiceTimesheetName, serviceInvoiceName: newServiceInvoiceName, serviceType: newServiceType, serviceBillingType: newServiceBillingType, serviceStatus: newServiceStatus, serviceCost1: newServiceCost1, serviceCost2: newServiceCost2, serviceCost3: newServiceCost3, servicePrice1: newServicePrice1, servicePrice2: newServicePrice2, servicePrice3: newServicePrice3)
//                let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: newServiceTimesheetName, serviceInvoiceName: newServiceInvoiceName, serviceType: newServiceType, serviceBillingType: newServiceBillingType, serviceStatus: newServiceStatus, serviceCost1: 1.0, serviceCost2: 1.0, serviceCost3: 1.0, servicePrice1: 1.0, servicePrice2: 1.0, servicePrice3: 1.0)
                
                self.servicesList.append(newService)
                serviceIndex += 1
                rowNumber += 1
            }
 //           referenceData.services.printAll()
            self.isServiceDataLoaded = true
        }
    }
    
    func saveServiceData() {
        var referenceFileID: String
        var updateValues: [[String]] = []
        
        var serviceKey: String = " "
        var serviceTimesheetName: String = " "
        var serviceInvoiceName: String = " "
        var serviceType: String = " "
        var serviceBillingType: String = " "
        var serviceStatus: String = " "
        var serviceCost1: String = " "
        var serviceCost2: String = " "
        var serviceCost3: String = " "
        var servicePrice1: String = " "
        var servicePrice2: String = " "
        var servicePrice3: String = " "
        
        if runMode == "PROD" {
            referenceFileID = PgmConstants.prodReferenceDataFileID
        } else {
            referenceFileID = PgmConstants.testReferenceDataFileID
        }
        
        let sheetService = GTLRSheetsService()
        let spreadsheetID = referenceFileID
        let serviceCount = servicesList.count
        
        let currentUser = GIDSignIn.sharedInstance.currentUser
        
        sheetService.authorizer = currentUser?.fetcherAuthorizer
            
        let range = PgmConstants.serviceRange + String(serviceCount + PgmConstants.serviceStartingRowNumber + 1)            // One extra line for blanking row at end
        print("Service Data Save Range", range)
  
        var serviceNum = 0
        while serviceNum < serviceCount {
            serviceKey = servicesList[serviceNum].serviceKey
            serviceTimesheetName = servicesList[serviceNum].serviceTimesheetName
            serviceInvoiceName = servicesList[serviceNum].serviceInvoiceName
            serviceType =  servicesList[serviceNum].serviceType
            serviceBillingType = servicesList[serviceNum].serviceBillingType
            serviceStatus = servicesList[serviceNum].serviceStatus
            serviceCost1 = String(servicesList[serviceNum].serviceCost1.formatted(.number.precision(.fractionLength(2))))
            serviceCost2 = String(servicesList[serviceNum].serviceCost2.formatted(.number.precision(.fractionLength(2))))
            serviceCost3 = String(servicesList[serviceNum].serviceCost3.formatted(.number.precision(.fractionLength(2))))
            servicePrice1 = String(servicesList[serviceNum].servicePrice1.formatted(.number.precision(.fractionLength(2))))
            servicePrice2 = String(servicesList[serviceNum].servicePrice2.formatted(.number.precision(.fractionLength(2))))
            servicePrice3 = String(servicesList[serviceNum].servicePrice3.formatted(.number.precision(.fractionLength(2))))
            
            updateValues.insert([serviceKey, serviceTimesheetName, serviceInvoiceName, serviceType, serviceBillingType, serviceStatus, serviceCost1, serviceCost2, serviceCost3, servicePrice1, servicePrice2, servicePrice3], at: serviceNum)
            serviceNum += 1
        }
// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
        updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], at: serviceNum)
        
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
                print("Services saved")
            }
        }
    }
    
    
}
