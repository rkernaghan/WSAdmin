//
//  BillingVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import Foundation
import SwiftUI
import GoogleSignIn

@Observable class BillingVM  {

//    private var sheetData: SheetData?
//    private var errorMessage: String?

        
	func generateInvoice(tutorSet: Set<Tutor.ID>, billingYear: String, billingMonth: String, referenceData: ReferenceData) async -> (Invoice, TutorBillingMonth, [String]) {
		var invoice = Invoice()
		var tutorList = [String]()
		var tutorBillingFileID: String = ""
		var resultFlag: Bool = true
		
		let tutorBillingMonth = TutorBillingMonth()
		
//       let (monthName, billingYear) = getCurrentMonthYear()
		let (prevMonthName, prevYearName) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingYear)
		
		let tutorBillingFileName = tutorBillingFileNamePrefix + billingYear
		let billArray = BillArray()
		print ("//")
		print("//")
		
//    print("Before get Student Billing File ID Async")
		
		for objectID in tutorSet {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				print("Read Timesheet for Tutor: \(tutorName)")
				tutorList.append(tutorName)
				
				let timesheet = await getTimesheet(tutorName: tutorName, timesheetYear: billingYear, timesheetMonth: billingMonth)
				
				billArray.processTimesheet(timesheet: timesheet)
			}
		}
//            print("Tutor List: \(tutorList)")
//                      billArray.printBillArray()
		
		do {
			(resultFlag, tutorBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
			await tutorBillingMonth.loadTutorBillingMonthAsync(monthName: billingMonth, tutorBillingFileID: tutorBillingFileID)
		} catch {
			
		}
		
		let (alreadyBilledFlag, alreadyBilledTutors) = tutorBillingMonth.checkAlreadyBilled(tutorList: tutorList)
		
		if alreadyBilledFlag {
			print("Already Billed Tutors: \(alreadyBilledTutors)")
		}
		
		invoice = billArray.generateInvoice(alreadyBilledTutors: alreadyBilledTutors, referenceData: referenceData)
		
		//            invoice.printInvoice()
		return(invoice, tutorBillingMonth, alreadyBilledTutors)
		
	}
	
	func getTimesheet(tutorName: String, timesheetYear: String, timesheetMonth: String) async -> Timesheet {
		var timesheet = Timesheet()
		var timesheetFileID: String = " "
		var result: Bool = true
		
//        print("Start get timesheet" + tutorName)
		let fileName = "Timesheet " + timesheetYear + " " + tutorName
		do {
			(result, timesheetFileID) = try await getFileIDAsync(fileName: fileName)
		} catch {
			print("Error: could not get timesheet fileID for \(fileName)")
		}
//        print("Before Task LoadTimesheet data " + tutorName)
//        Task {
//            print("In Task for Get Timesheet " + tutorName)
		let range = await timesheet.loadTimesheetData(tutorName: tutorName, month: timesheetMonth, timesheetID: timesheetFileID)
//            print("after load timesheet data before print value statement")
//            print("Timesheet Returned" + timesheet.timesheetRows[0].studentName + " " + timesheet.timesheetRows[0].tutorName)
//        }
		
		return(timesheet)
	}
	
	
	
	func fetchTimesheetData(tutorName: String, spreadsheetId: String, range: String) async throws -> SheetData? {
		var yourOAuthToken: String
		var sheetData: SheetData?
		
		let currentUser = GIDSignIn.sharedInstance.currentUser
		if let user = currentUser {
			yourOAuthToken = user.accessToken.tokenString
			
			// URL for Google Sheets API
			let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)"
			guard let url = URL(string: urlString) else {
				throw URLError(.badURL)
			}
			
			// Set up the request with OAuth 2.0 token
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.addValue("Bearer \(yourOAuthToken)", forHTTPHeaderField: "Authorization")
			
			// Use async URLSession to fetch the data
			
			let (data, response) = try await URLSession.shared.data(for: request)
			
			if let httpResponse = response as? HTTPURLResponse {
				print("error \(httpResponse.statusCode)")
			}
			// Check if the response is successful
			guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
				throw URLError(.badServerResponse)
			}
			
			// Decode the JSON data into the SheetData structure
			sheetData = try JSONDecoder().decode(SheetData.self, from: data)
			
		}
		//        if let sheetData = sheetData {
		return sheetData
		//        }
	}
	
	func updateBillingStats(invoice: Invoice, alreadyBilledTutors: [String], tutorBillingMonth: TutorBillingMonth, billingMonth: String, billingYear: String, referenceData: ReferenceData) {
		
		var billingMonthStudentFileID: String = ""
		var billingMonthTutorFileID: String = ""
		
		var studentBillingMonth = StudentBillingMonth()
		var resultFlag: Bool = false
		
		let (prevMonth, prevMonthYear) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingYear)
		
		let billingMonthStudentFileName = studentBillingFileNamePrefix + billingYear
		let billingMonthTutorFileName = tutorBillingFileNamePrefix + billingYear
		let prevMonthStudentFileName = studentBillingFileNamePrefix + prevMonthYear
		let prevMonthTutorFileName = tutorBillingFileNamePrefix + prevMonthYear
		
		
		Task {
			do {
				(resultFlag, billingMonthStudentFileID) = try await getFileIDAsync(fileName: billingMonthStudentFileName)
				if resultFlag {
					await studentBillingMonth.loadStudentBillingMonthAsync(monthName: billingMonth, studentBillingFileID: billingMonthStudentFileID)
				}
			} catch {
				print("Could not get File ID for Student Billing File \(billingMonthStudentFileName)")
			}
			
			await tutorBillingMonth.copyTutorBillingMonth(billingMonth: billingMonth, billingMonthYear: billingYear, referenceData: referenceData)
			await studentBillingMonth.copyStudentBillingMonth(billingMonth: billingMonth, billingMonthYear: billingYear, referenceData: referenceData)
			
			var invoiceLineNum: Int = 0
			let invoiceLineCount: Int = invoice.invoiceLines.count
			while invoiceLineNum < invoiceLineCount {
				let tutorName = invoice.invoiceLines[invoiceLineNum].tutorName
				let studentName = invoice.invoiceLines[invoiceLineNum].studentName
				let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
				let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByName(billedStudentName: studentName)
				let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
				let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
				let studentLocation = referenceData.students.studentsList[studentNum].studentLocation
				let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: studentLocation)
				
				let cost = invoice.invoiceLines[invoiceLineNum].cost
				let revenue = invoice.invoiceLines[invoiceLineNum].amount
				let profit = revenue - cost
				
				if alreadyBilledTutors.contains(tutorName) {
					resetBillingStats(sessionCost: cost, sessionRevenue: revenue, billedTutorNum: billedTutorNum, billedStudentNum: billedStudentNum, tutorNum: tutorNum, studentNum: studentNum, tutorBillingMonth: tutorBillingMonth, studentBillingMonth: studentBillingMonth, referenceData: referenceData )
				}
				
				tutorBillingMonth.tutorBillingRows[billedTutorNum].monthSessions += 1
				tutorBillingMonth.tutorBillingRows[billedTutorNum].totalSessions += 1
				tutorBillingMonth.tutorBillingRows[billedTutorNum].monthCost += cost
				tutorBillingMonth.tutorBillingRows[billedTutorNum].totalCost += cost
				tutorBillingMonth.tutorBillingRows[billedTutorNum].monthRevenue += revenue
				tutorBillingMonth.tutorBillingRows[billedTutorNum].totalRevenue += revenue
				tutorBillingMonth.tutorBillingRows[billedTutorNum].monthProfit += profit
				tutorBillingMonth.tutorBillingRows[billedTutorNum].totalProfit += profit
				
				studentBillingMonth.studentBillingRows[billedStudentNum].monthSessions += 1
				studentBillingMonth.studentBillingRows[billedStudentNum].totalSessions += 1
				studentBillingMonth.studentBillingRows[billedStudentNum].monthCost += cost
				studentBillingMonth.studentBillingRows[billedStudentNum].totalCost += cost
				studentBillingMonth.studentBillingRows[billedStudentNum].monthRevenue += revenue
				studentBillingMonth.studentBillingRows[billedStudentNum].totalRevenue += revenue
				studentBillingMonth.studentBillingRows[billedStudentNum].monthProfit += profit
				studentBillingMonth.studentBillingRows[billedStudentNum].totalProfit += profit
				
				referenceData.tutors.tutorsList[tutorNum].tutorTotalSessions += 1
				referenceData.tutors.tutorsList[tutorNum].tutorTotalCost += cost
				referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue += revenue
				referenceData.tutors.tutorsList[tutorNum].tutorTotalProfit += profit
				
				referenceData.students.studentsList[studentNum].studentSessions += 1
				referenceData.students.studentsList[studentNum].studentTotalCost += cost
				referenceData.students.studentsList[studentNum].studentTotalRevenue += revenue
				referenceData.students.studentsList[studentNum].studentTotalProfit += profit
				
				referenceData.locations.locationsList[locationNum].locationMonthRevenue += revenue
				referenceData.locations.locationsList[locationNum].locationTotalRevenue += revenue
				
				invoiceLineNum += 1
			}
			
			let result1 = await studentBillingMonth.saveStudentBillingData(studentBillingFileID: billingMonthStudentFileID, billingMonth: billingMonth)
			
			do {
				(resultFlag, billingMonthTutorFileID) = try await getFileIDAsync(fileName: billingMonthTutorFileName)
				if resultFlag {
					let result2 = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: billingMonthTutorFileID, billingMonth: billingMonth)
				} else {
					print("Could not get File ID for Tutor Billing File \(billingMonthTutorFileName)")
				}
			} catch {
				print("Error Saving Tutor Billing Data")
			}
			
			await referenceData.tutors.saveTutorData()
			await referenceData.students.saveStudentData()
			await referenceData.locations.saveLocationData()
		}
	}
	
	func generateCSVFile(invoice: Invoice, billingMonth: String, billingYear: String, tutorBillingMonth: TutorBillingMonth, alreadyBilledTutors: [String], referenceData: ReferenceData) -> (Bool, String) {
		var generationFlag: Bool = true
		var generationMessage: String = ""
		
		var resultFlag: Bool = false
		
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let userCSVURL = documentsURL.appendingPathComponent("CSVFiles")
		
		self.updateBillingStats(invoice: invoice, alreadyBilledTutors: alreadyBilledTutors, tutorBillingMonth: tutorBillingMonth, billingMonth: billingMonth, billingYear: billingYear, referenceData: referenceData)
		
		do {
			try FileManager.default.createDirectory(at: userCSVURL, withIntermediateDirectories: true, attributes: nil)
		} catch {
			print("Error creating directory: \(error)")
		}
		
		do {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
			let fileDate = dateFormatter.string(from: Date())
			
			let fileName = "CSV Export File \(fileDate).csv"
			let fileManager = FileManager.default
			
			// Get the path to the Documents directory
			guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
				print("Could not find the Documents directory.")
				return(false, "Count not find the Documents Directory")
			}
			
			// Set the file path
			let fileURL = documentsDirectory.appendingPathComponent(fileName)
			
			// Create the file if it doesn't exist
			if !fileManager.fileExists(atPath: fileURL.path) {
				fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
			}
			// Open the file for writing
			let fileHandle = try FileHandle(forWritingTo: fileURL)
			
			var invoiceLineNum = 0
			let invoiceLineCount = invoice.invoiceLines.count
			while invoiceLineNum < invoiceLineCount {
				let csvLine = processInvoiceLine(invoiceLine: invoice.invoiceLines[invoiceLineNum])
				if let data = "\(csvLine)\n".data(using: .utf8) { // Convert each line to Data and add a newline
					fileHandle.write(data)
				}
				invoiceLineNum += 1
			}
			// Close the file when done
			fileHandle.closeFile()
			print("Lines written to file successfully.")
		} catch {
			print("error write to file: \(error)")
			
		}
		return(generationFlag, generationMessage)
	}
	
	func processInvoiceLine(invoiceLine: InvoiceLine) -> String {
		let invoiceNum = invoiceLine.invoiceNum
		let invoiceClient = invoiceLine.clientName
		let invoiceEmail = invoiceLine.clientEmail
		let invoiceDate = invoiceLine.invoiceDate
		let invoiceDueDate = invoiceLine.dueDate
		let invoiceTerm = invoiceLine.terms
		let invoiceLocation = invoiceLine.locationName
		let invoiceTutor = invoiceLine.tutorName
		let invoiceItem = invoiceLine.itemName
		let invoiceDescription = invoiceLine.description
		let invoiceQuantity = invoiceLine.quantity
		let invoiceRate = invoiceLine.rate
		let invoiceAmount = String(invoiceLine.amount)
		let invoiceTaxCode = invoiceLine.taxCode
		let invoiceServiceDate = invoiceLine.serviceDate
		let csvLine = invoiceNum + PgmConstants.CSVSeperator + invoiceClient + PgmConstants.CSVSeperator + invoiceEmail + PgmConstants.CSVSeperator + invoiceDate + PgmConstants.CSVSeperator + invoiceDueDate + PgmConstants.CSVSeperator + invoiceTerm + PgmConstants.CSVSeperator +  invoiceLocation + PgmConstants.CSVSeperator + invoiceTutor + PgmConstants.CSVSeperator + invoiceItem + PgmConstants.CSVSeperator + invoiceDescription + PgmConstants.CSVSeperator + invoiceQuantity + PgmConstants.CSVSeperator + invoiceRate + PgmConstants.CSVSeperator + invoiceAmount + PgmConstants.CSVSeperator + invoiceTaxCode + PgmConstants.CSVSeperator + invoiceServiceDate
		return(csvLine)
	}
	
	func resetBillingStats(sessionCost: Float, sessionRevenue: Float, billedTutorNum: Int, billedStudentNum: Int, tutorNum: Int, studentNum: Int, tutorBillingMonth: TutorBillingMonth, studentBillingMonth:StudentBillingMonth, referenceData: ReferenceData) {
		tutorBillingMonth.tutorBillingRows[billedTutorNum].resetBilledTutorMonth(cost: sessionCost, revenue: sessionRevenue, profit: sessionRevenue - sessionCost)
		studentBillingMonth.studentBillingRows[billedStudentNum].resetBilledStudentMonth(cost: sessionCost, revenue: sessionRevenue, profit: sessionRevenue - sessionCost)
		
		referenceData.tutors.tutorsList[tutorNum].resetBillingStats(sessionCost: sessionCost, sessionRevenue: sessionRevenue)
		referenceData.students.studentsList[studentNum].resetBillingStats(sessionCost: sessionCost, sessionRevenue: sessionRevenue)
		
		let studentLocation = referenceData.students.studentsList[studentNum].studentLocation
		let (locationFound,locationNum) = referenceData.locations.findLocationByName(locationName: studentLocation)
		referenceData.locations.locationsList[locationNum].resetBillingStats(sessionRevenue: sessionRevenue)
		
	}
    
}
