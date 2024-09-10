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
    
    func addService(newService: Service) {
        servicesList.append(newService)
    }
    
    func printAll() {
        for service in servicesList {
            print ("Service Name is \(service.serviceTimesheetName)")
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
            
        let range = PgmConstants.serviceRange + String(serviceCount + PgmConstants.serviceStartingRowNumber)
        print("Range", range)
  
        var serviceNum = 0
        while serviceNum < serviceCount {
            serviceKey = servicesList[serviceNum].serviceKey
            serviceTimesheetName = servicesList[serviceNum].serviceTimesheetName
            serviceInvoiceName = servicesList[serviceNum].serviceInvoiceName
            serviceBillingType = servicesList[serviceNum].serviceBillingType
            serviceType = servicesList[serviceNum].serviceType
            
            updateValues.insert([serviceKey, serviceTimesheetName, serviceInvoiceName, serviceType, serviceBillingType], at: serviceNum)
            serviceNum += 1
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
                print("services saved")
            }
        }
    }
    
    
}
