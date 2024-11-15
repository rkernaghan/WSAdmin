//
//  ServicesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation


@Observable class ServicesList {
	var servicesList = [Service]()
	var isServiceDataLoaded: Bool
	
	init() {
		isServiceDataLoaded = false
	}
	
	func findServiceByKey(serviceKey: String) -> (Bool, Int) {
		var found = false
		
		var serviceNum = 0
		while serviceNum < servicesList.count && !found {
			if servicesList[serviceNum].serviceKey == serviceKey {
				found = true
			} else {
				serviceNum += 1
			}
		}
		return(found, serviceNum)
	}
	
	func findServiceByName(timesheetName: String) -> (Bool, Int) {
		var found = false
		
		var serviceNum = 0
		while serviceNum < servicesList.count && !found {
			if servicesList[serviceNum].serviceTimesheetName == timesheetName {
				found = true
			} else {
				serviceNum += 1
			}
		}
		return(found, serviceNum)
	}
	
	func loadService(newService: Service, referenceData: ReferenceData) {
		self.servicesList.append(newService)
		
	}
	
	func printAll() {
		for service in servicesList {
			print ("Service Name is \(service.serviceTimesheetName)")
		}
	}
	
  
    
	func fetchServiceData(serviceCount: Int) async -> Bool {
		var completionFlag = true
		
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		
		// Read in the Services Data from the Reference Data spreadsheet
		if serviceCount > 0 {
			do {
				sheetData = try await readSheetCells(fileID: referenceDataFileID, range: PgmConstants.serviceRange + String(PgmConstants.serviceStartingRowNumber + serviceCount - 1) )
				// Build the Services list from the cells read in
				if let sheetData = sheetData {
					sheetCells = sheetData.values
					loadServiceRows(serviceCount: serviceCount, sheetCells: sheetCells)
				} else {
					completionFlag = false
				}
			} catch {
				completionFlag = false
				print("Error: could not read Services Data from Reference Data spreadsheet")
			}
			
		}
		return(completionFlag)
	}
    
	func saveServiceData() async -> Bool {
		var completionFlag: Bool = true
		
		// Write the Service Data rows to the Reference Data spreadsheet
		let updateValues = unloadServiceRows()
		let count = updateValues.count
		let range = PgmConstants.serviceRange + String(PgmConstants.serviceStartingRowNumber + updateValues.count - 1)
		do {
			let result = try await writeSheetCells(fileID: referenceDataFileID, range: range, values: updateValues)
			if !result {
				completionFlag = false
				print("Error: Saving Services data rows failed")
			}
		} catch {
			print ("Error: Saving Services Data rows failed")
			completionFlag = false
		}
		
		return(completionFlag)
	}
	
	func loadServiceRows(serviceCount: Int, sheetCells: [[String]] ) {
		var serviceIndex = 0
		var rowNumber = 0
		while serviceIndex < serviceCount {
			
			let newServiceKey = sheetCells[rowNumber][PgmConstants.serviceKeyPosition]
			let newServiceTimesheetName = sheetCells[rowNumber][PgmConstants.serviceTimesheetNamePosition]
			let newServiceInvoiceName = sheetCells[rowNumber][PgmConstants.serviceInvoiceNamePosition]
			let newServiceType: ServiceTypeOption =  ServiceTypeOption(rawValue: sheetCells[rowNumber][PgmConstants.serviceTypePosition]) ?? .Special
			let newServiceBillingType: BillingTypeOption = BillingTypeOption(rawValue: sheetCells[rowNumber][PgmConstants.serviceBillingTypePosition]) ?? .Fixed
			let newServiceStatus = sheetCells[rowNumber][PgmConstants.serviceStatusPosition]
			let newServiceCount = Int(sheetCells[rowNumber][PgmConstants.serviceCountPosition]) ?? 0
			let newServiceCost1 = Float(sheetCells[rowNumber][PgmConstants.serviceCost1Position]) ?? 0.0
			let newServiceCost2 = Float(sheetCells[rowNumber][PgmConstants.serviceCost2Position]) ?? 0.0
			let newServiceCost3 = Float(sheetCells[rowNumber][PgmConstants.serviceCost3Position]) ?? 0.0
			let newServicePrice1 = Float(sheetCells[rowNumber][PgmConstants.servicePrice1Position]) ?? 0.0
			let newServicePrice2 = Float(sheetCells[rowNumber][PgmConstants.servicePrice2Position]) ?? 0.0
			let newServicePrice3 = Float(sheetCells[rowNumber][PgmConstants.servicePrice3Position]) ?? 0.0
			
			let newService = Service(serviceKey: newServiceKey, serviceTimesheetName: newServiceTimesheetName, serviceInvoiceName: newServiceInvoiceName, serviceType: newServiceType, serviceBillingType: newServiceBillingType, serviceStatus: newServiceStatus, serviceCount: newServiceCount, serviceCost1: newServiceCost1, serviceCost2: newServiceCost2, serviceCost3: newServiceCost3, servicePrice1: newServicePrice1, servicePrice2: newServicePrice2, servicePrice3: newServicePrice3)
			
			self.servicesList.append(newService)
			serviceIndex += 1
			rowNumber += 1
		}
		//           referenceData.services.printAll()
		self.isServiceDataLoaded = true
	}
	
	func unloadServiceRows() -> [[String]] {
		
		var updateValues = [[String]]()
		
		var serviceNum = 0
		
		let serviceCount = self.servicesList.count
		while serviceNum < serviceCount {
			let serviceKey = servicesList[serviceNum].serviceKey
			let serviceTimesheetName = servicesList[serviceNum].serviceTimesheetName
			let serviceInvoiceName = servicesList[serviceNum].serviceInvoiceName
			let serviceType =  String(describing: servicesList[serviceNum].serviceType)
			let serviceBillingType = String(describing: servicesList[serviceNum].serviceBillingType)
			let serviceStatus = servicesList[serviceNum].serviceStatus
			let serviceCount = String(servicesList[serviceNum].serviceCount)
			let serviceCost1 = String(servicesList[serviceNum].serviceCost1.formatted(.number.precision(.fractionLength(2))))
			let serviceCost2 = String(servicesList[serviceNum].serviceCost2.formatted(.number.precision(.fractionLength(2))))
			let serviceCost3 = String(servicesList[serviceNum].serviceCost3.formatted(.number.precision(.fractionLength(2))))
			let servicePrice1 = String(servicesList[serviceNum].servicePrice1.formatted(.number.precision(.fractionLength(2))))
			let servicePrice2 = String(servicesList[serviceNum].servicePrice2.formatted(.number.precision(.fractionLength(2))))
			let servicePrice3 = String(servicesList[serviceNum].servicePrice3.formatted(.number.precision(.fractionLength(2))))
			
			updateValues.insert([serviceKey, serviceTimesheetName, serviceInvoiceName, serviceType, serviceBillingType, serviceStatus, serviceCount, serviceCost1, serviceCost2, serviceCost3, servicePrice1, servicePrice2, servicePrice3], at: serviceNum)
			serviceNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "," "], at: serviceNum)
		
		return(updateValues)
	}
	
}

