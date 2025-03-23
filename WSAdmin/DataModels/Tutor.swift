//
//  Tutor.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class Tutor: Identifiable {
	var tutorKey: String
	var tutorName: String
	var tutorEmail: String
	var tutorPhone: String
	var tutorStatus: String
	var tutorAvailability: String
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
	var timesheetFileID: String
	let id = UUID()
	
	init(tutorKey: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorStatus: String, tutorStartDate: String, tutorEndDate: String, tutorMaxStudents: Int, tutorStudentCount: Int, tutorServiceCount: Int, tutorTotalSessions: Int, tutorTotalCost: Float, tutorTotalRevenue: Float, tutorTotalProfit: Float, timesheetFileID:String) {
		self.tutorKey = tutorKey
		self.tutorName = tutorName
		self.tutorEmail = tutorEmail
		self.tutorPhone = tutorPhone
		self.tutorStatus = tutorStatus
		self.tutorAvailability = " "
		self.tutorStartDate = tutorStartDate
		self.tutorEndDate = tutorEndDate
		self.tutorMaxStudents = tutorMaxStudents
		self.tutorStudentCount = tutorStudentCount
		self.tutorServiceCount = tutorServiceCount
		self.tutorTotalSessions = tutorTotalSessions
		self.tutorTotalCost = tutorTotalCost
		self.tutorTotalRevenue = tutorTotalRevenue
		self.tutorTotalProfit = tutorTotalProfit
		self.timesheetFileID = timesheetFileID
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
	
	func addNewTutorStudent(newTutorStudent: TutorStudent) async -> Bool {
		var completionFlag: Bool = true
		
		tutorStudents.append(newTutorStudent)
		completionFlag = await saveTutorStudentData(tutorName: self.tutorName)
		if completionFlag {
			tutorStudentCount += 1
			completionFlag = await saveTutorDataCounts()
			self.tutorStatus = "Assigned"
		}
		return(completionFlag)
	}
	
	func updateTutor(tutorName: String, contactEmail: String, contactPhone: String, maxStudents: Int) {
		self.tutorName = tutorName
		self.tutorEmail = contactEmail
		self.tutorPhone = contactPhone
		self.tutorMaxStudents = maxStudents
	}
	
	func removeTutorStudent(studentKey: String) async -> Bool {
		var completionFlag: Bool = true
		
		let (studentFound, tutorStudentNum) = findTutorStudentByKey(studentKey: studentKey)
		
		if studentFound {
			tutorStudents.remove(at: tutorStudentNum)
			completionFlag = await saveTutorStudentData(tutorName: self.tutorName)
			if completionFlag {
				tutorStudentCount -= 1
				completionFlag = await saveTutorDataCounts()
				
				if tutorStudentCount == 0 {
					self.tutorStatus = "Unassigned"
				}
			}
		}
		return(completionFlag)
	}
	
	func loadTutorService(newTutorService: TutorService) {
		tutorServices.append(newTutorService)
	}
	
	func addNewTutorService(newTutorService: TutorService) async -> Bool {
		var completionFlag: Bool = true
		
		tutorServices.append(newTutorService)
		completionFlag = await saveTutorServiceData(tutorName: self.tutorName)
		if completionFlag {
			tutorServiceCount += 1
			completionFlag = await saveTutorDataCounts()
		}
		return(completionFlag)
	}
	
	func updateTutorService(tutorServiceNum: Int, timesheetName: String, invoiceName: String, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) async -> Bool {
		var completionFlag: Bool = true
		
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
		completionFlag = await saveTutorServiceData(tutorName: self.tutorName)
		
		return(completionFlag)
	}
	
	func removeTutorService(serviceKey: String) async -> Bool {
		var completionFlag: Bool = true
		
		let (serviceFound, tutorServiceNum) = findTutorServiceByKey(serviceKey: serviceKey)
		
		if serviceFound {
			tutorServices.remove(at: tutorServiceNum)
			completionFlag = await saveTutorServiceData(tutorName: self.tutorName)
			if completionFlag {
				tutorServiceCount -= 1
				completionFlag = await saveTutorDataCounts()
			}
		}
		return(completionFlag)
	}
	
	func markDeleted() {
		tutorStatus = "Deleted"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
		tutorEndDate = dateFormatter.string(from: Date())
	}
	
	func markUnDeleted() {
		tutorStatus = "Unassigned"
		tutorEndDate = " "
	}
	
	func unassignTutor() {
		
	}
	
	func suspendTutor() {
		self.tutorStatus = "Suspended"
	}
	
	func unsuspendTutor() {
		self.tutorStatus = "Unassigned"
	}
	
	func resetBillingStats(sessions: Int, monthCost: Float, monthRevenue: Float) {
		self.tutorTotalSessions -= sessions
		self.tutorTotalCost -= monthCost
		self.tutorTotalRevenue -= monthRevenue
		self.tutorTotalProfit -= monthRevenue - monthCost
	}
	
	func loadTutorDetails(tutorNum: Int, tutorName: String, tutorDataFileID: String) async -> Bool {
		var completionFlag: Bool = true
		
		if self.tutorServiceCount > 0 {
			completionFlag = await self.fetchTutorServiceData( tutorName: tutorName, tutorServiceCount: tutorServiceCount)
		}
		
		if self.tutorStudentCount > 0 && completionFlag {
			completionFlag = await self.fetchTutorStudentData( tutorName: tutorName, tutorStudentCount: tutorStudentCount)
		}
		return(completionFlag)
	}
	
	
	func saveTutorDataCounts() async -> Bool {
		var completionFlag: Bool = true
		var updateValues = [[String]]()
		
		let range = tutorName + PgmConstants.tutorDataCountsRange
		tutorStudentCount = tutorStudents.count
		tutorServiceCount = tutorServices.count

		updateValues = [[String(tutorStudentCount)], [String(tutorServiceCount)]]
		
		do {
			completionFlag = try await writeSheetCells(fileID: tutorDetailsFileID, range: range, values: updateValues)
		} catch {
			print ("Error: Saving Tutor Data Counts failed")
			completionFlag = false
		}
		return(completionFlag)
	}
	
	
	
	func fetchTutorStudentData(tutorName: String, tutorStudentCount: Int) async -> Bool {
		var completionFlag: Bool = true
		
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		
		// Read in the Tutor Students data from the Tutor Details spreadsheet
		if tutorStudentCount > 0 {
			do {
				let range = tutorName + PgmConstants.tutorStudentsRange + String(PgmConstants.tutorDataStudentsStartingRowNumber + tutorStudentCount - 1)
				sheetData = try await readSheetCells(fileID: tutorDetailsFileID, range: range )
				// Build the Tutor Students list from the cells read in
				if let sheetData = sheetData {
					sheetCells = sheetData.values
					loadTutorStudentRows(tutorStudentCount: tutorStudentCount, sheetCells: sheetCells)
				} else {
					completionFlag = false
				}
			} catch {
				print("ERROR: could not read Tutor Student sheet cells for \(tutorName)")
				completionFlag = false
			}
		}
		return(completionFlag)
	}
	
	func fetchTutorDataCounts(tutorName: String) async -> (Int, Int, String){
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		var range: String
		var timesheetFileID: String = ""
		var studentCount: Int
		var serviceCount: Int
		
		// Read in the Tutor Data counts from the Tutor Details spreadsheet
		
		do {
			range = tutorName + PgmConstants.tutorDataCountsRange
			sheetData = try await readSheetCells(fileID: tutorDetailsFileID, range: range )
			
			if let sheetData = sheetData {
				sheetCells = sheetData.values
				studentCount = Int( sheetCells[0][0] ) ?? 0
				serviceCount = Int( sheetCells[1][0] ) ?? 0
			} else {
				studentCount = 0
				serviceCount = 0
			}
			
		} catch {
			print("Error: could not read Tutor Data Counts for Tutor \(tutorName), will try again")
			do {
				sheetData = try await readSheetCells(fileID: tutorDetailsFileID, range: range )
				
				if let sheetData = sheetData {
					sheetCells = sheetData.values
					timesheetFileID = sheetCells[0][0]
					studentCount = Int( sheetCells[1][0] ) ?? 0
					serviceCount = Int( sheetCells[2][0] ) ?? 0
				} else {
					studentCount = 0
					serviceCount = 0
				}
				
			} catch {
				print("Error: could not Tutor Data Counts for Tutor \(tutorName) on second attempt")
				studentCount = 0
				serviceCount = 0
			}
		}
		
		return(studentCount, serviceCount, timesheetFileID)
	}
	
	func saveTutorStudentData(tutorName: String) async -> Bool {
		var completionFlag: Bool = true
		
		// Write the Tutor Student rows to the Tutor Details spreadsheet
		let updateValues = unloadTutorStudentRows()
		let count = updateValues.count
		let range = tutorName + PgmConstants.tutorStudentsRange + String(PgmConstants.tutorDataStudentsStartingRowNumber + updateValues.count - 1)
		do {
			completionFlag = try await writeSheetCells(fileID: tutorDetailsFileID, range: range, values: updateValues)
		} catch {
			print ("Error: Saving Tutor Services data rows failed")
			completionFlag = false
		}
		
		return(completionFlag)
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
			let assignedDate = sheetCells[rowNum][PgmConstants.tutorDataStudentAssignedDatePosition]
			
			let newTutorStudent = TutorStudent(studentKey: studentKey, studentName: studentName, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone, assignedDate: assignedDate)
			
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
			let assignedDate = tutorStudents[tutorStudentNum].assignedDate
			
			updateValues.insert([studentKey, studentName, clientName, clientEmail, clientPhone, assignedDate], at: tutorStudentNum)
			tutorStudentNum += 1
		}
		// Add a blank row to end in case this was a delete to eliminate last row from Reference Data spreadsheet
		updateValues.insert([" ", " ", " ", " ", " ", " "], at: tutorStudentNum)
		
		return(updateValues)
	}
	
	func fetchTutorServiceData(tutorName: String, tutorServiceCount: Int) async -> Bool {
		var completionFlag: Bool = true
		
		var sheetCells = [[String]]()
		var sheetData: SheetData?
		
		// Read in the Tutor Services data from the Tutor Details spreadsheet
		if tutorServiceCount > 0 {
			do {
				let range = tutorName + PgmConstants.tutorServicesRange + String(PgmConstants.tutorDataServicesStartingRowNumber + tutorServiceCount - 1)
				sheetData = try await readSheetCells(fileID: tutorDetailsFileID, range: range)
				// Build the Tutor Services list from the cells read in
				if let sheetData = sheetData {
					sheetCells = sheetData.values
					loadTutorServiceRows(tutorServiceCount: tutorServiceCount, sheetCells: sheetCells)
				} else {
					completionFlag = false
				}
			} catch {
				print("ERROR: could not read Tutor Services sheet cells for \(tutorName)")
				completionFlag = false
			}
		}
		return(completionFlag)
	}
	
	func saveTutorServiceData(tutorName: String) async -> Bool {
		var completionFlag: Bool = true
		
		// Write the Tutor Services rows to the Tutor Details spreadsheet
		let updateValues = unloadTutorServiceRows()
		let count = updateValues.count
		let range = tutorName + PgmConstants.tutorServicesRange + String(PgmConstants.tutorDataServicesStartingRowNumber + updateValues.count - 1)
		do {
			completionFlag = try await writeSheetCells(fileID: tutorDetailsFileID, range: range, values: updateValues)
		} catch {
			print ("Error: Saving Tutor Services data rows failed")
			completionFlag = false
		}
		
		return(completionFlag)
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
