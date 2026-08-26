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
	
        // This function will generate an invoice for the selected tutors to be billed so it can be displayed to the user (to determine whether to generate the CSV file and update billing stats).
	
	@MainActor func buildInvoice(tutorSet: Set<Tutor.ID>, billingYear: String, billingMonth: String, referenceData: ReferenceData, billingMessages: WindowMessages, showBillingDiagnostics: Bool, showEachSession: Bool, startingInvoiceNumber: Int) async -> (Invoice, TutorBillingMonth, [String]) {
		var invoice = Invoice()
		var tutorList = [String]()
		var tutorBillingFileID: String = ""
		var resultFlag: Bool = true
		var alreadyBilledFlag: Bool = false
		var alreadyBilledTutors = [String]()
		referenceData.dataCounts.highestInvoiceNumber = startingInvoiceNumber - 1
		var logMessage: String
		
		let tutorBillingMonth = TutorBillingMonth(monthName: billingMonth)
		
		let tutorBillingFileName = tutorBillingFileNamePrefix + billingYear
		let billArray = BillArray(monthName: billingMonth)
		logMessage = "INFO: Starting Generate Invoice for \(billingYear) \(billingMonth)"
		print(logMessage)
		await AppLogger.shared.log(logMessage, newLine: "Y")
		
		// Go through each selected Tutor, read the Tutor's Timesheet and add the data to the billArray.
		for objectID in tutorSet {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				print("Read Timesheet for Tutor: \(tutorName)")
				billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "          Information: Processing Timesheet for Tutor: \(tutorName)"))
				tutorList.append(tutorName)
				
				let timesheet = await getTimesheet(tutorName: tutorName, timesheetYear: billingYear, timesheetMonth: billingMonth, billingMessages: billingMessages, referenceData: referenceData, showBillingDiagnostics: showBillingDiagnostics, showEachSession: showEachSession)
				
				billArray.processTimesheet(timesheet: timesheet, billingMessages: billingMessages, referenceData: referenceData)
			}
		}
		
		// Load Billed Tutor month sheet for current month. If this month has already been billed, get list of already billed Tutors for the month. Then
		// generate the Invoice.
		//
		do {
			(resultFlag, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			if !resultFlag {
				logMessage = "ERROR: BillingVM.generateInvoice - Could not get File ID for Tutor Billing file: \(tutorBillingFileName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			} else {
				let loadBilledTutorFlag = await tutorBillingMonth.getTutorBillingMonth(monthName: billingMonth, tutorBillingFileID: tutorBillingFileID, loadValidatedData: false)
				if loadBilledTutorFlag {				// If no Tutors billed this month, the flag will be false, which is not an error
					(alreadyBilledFlag, alreadyBilledTutors) = tutorBillingMonth.checkAlreadyBilled(tutorList: tutorList)
					
					if alreadyBilledFlag {
						print("Already Billed Tutors: \(alreadyBilledTutors)")
						billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "          Information: Tutors already billed for month: \(alreadyBilledTutors)"))
					}
				}
				invoice = billArray.generateInvoice(referenceData: referenceData, billingMessages: billingMessages)
			}
		} catch {
			logMessage = "ERROR: in BillingVM.generateInvoice - Could not load Billed Tutor Month"
			billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Return the invoice data, the Tutor Billing data for the month so it can be updated if user bills the invoice (creates CSV) and the list of any Tutors already billed
		billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "          Information: Invoice generation completed"))
		return(invoice, tutorBillingMonth, alreadyBilledTutors)
		
	}
	
	// Read in a yearly Timesheet for a Tutor
	func getTimesheet(tutorName: String, timesheetYear: String, timesheetMonth: String, billingMessages: WindowMessages, referenceData: ReferenceData, showBillingDiagnostics: Bool, showEachSession: Bool) async -> Timesheet {
		let timesheet = Timesheet()
		var timesheetFileID: String = " "
		var result: Bool = true
		var logMessage: String = " "
		
		
		let fileName = "Timesheet " + timesheetYear + " " + tutorName
		if showBillingDiagnostics {
			billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "                 Timesheet Name is: \(fileName)"))
		}
		
		do {
			// Get the Google Sheets FileID for the Tutor's Timesheet for the year
			(result, timesheetFileID) = try await getFileID(fileName: fileName)
			
			if result {
				if showBillingDiagnostics {
					billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "                 Timesheet FileID is: \(timesheetFileID)"))
				}
				// Read in the Tutor's Timesheet for the year
				let timesheetResult = await timesheet.loadTimesheetData(tutorName: tutorName, month: timesheetMonth, timesheetID: timesheetFileID, billingMessages: billingMessages, referenceData: referenceData, showBillingDiagnostics: showBillingDiagnostics, showEachSession: showEachSession)
				if !timesheetResult {
					logMessage = "ERROR: in BillingVM.getTimesheet - Could not load Timesheet for Tutor: \(tutorName) with File ID: \(timesheetFileID)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
					billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
			} else {
				billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: in BillingVM.getTimesheet - Could not get timesheet fileID for fileName: \(fileName); User may not have access to Timesheet"))
			}
				
				
		} catch {
			print("ERROR: could not get timesheet fileID for file: \(fileName)")
			billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: in BillingVM.getTimesheet- Ccould not get timesheet fileID for file: \(fileName)"))
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		}

		return(timesheet)
	}
	

	// Update the billing stats for Tutors, Students and Locations in the Reference Data, Student Billing and Tutor Billing spreadsheets.  If the Tutor was already billed, reset the billing stats
	// for that Tutor before updating the billing stats
	@MainActor func updateBillingStats(invoice: Invoice, alreadyBilledTutors: [String], tutorBillingMonth: TutorBillingMonth, billingMonth: String, billingYear: String, referenceData: ReferenceData) async -> (Bool, String) {
		
		var logMessage: String
		logMessage = "INFO: Starting updating billing stats for Month: \(billingMonth); AlreadyBilled:\(alreadyBilledTutors), AlreadyBilled Count: \(alreadyBilledTutors.count)"
		print(logMessage)
		
		var billingMonthStudentFileID: String = ""
		var billingMonthTutorFileID: String = ""
		
		let studentBillingMonth = StudentBillingMonth(monthName: billingMonth)
		var resultFlag: Bool = false
		
		let (prevMonth, prevMonthYear) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingYear)
		
		let billingMonthStudentFileName = studentBillingFileNamePrefix + billingYear
		let billingMonthTutorFileName = tutorBillingFileNamePrefix + billingYear
		
		let billingQuarter = getQuarterNum(monthName: billingMonth)
	
		do {
			// Read in the current month Student Billing month, copy the previous month's Student and Tutor billing months to current month's files
			(resultFlag, billingMonthStudentFileID) = try await getFileID(fileName: billingMonthStudentFileName)
			if resultFlag {
				resultFlag = await studentBillingMonth.getStudentBillingMonth(monthName: billingMonth, studentBillingFileID: billingMonthStudentFileID, loadValidatedData: false)
				guard  resultFlag else {
					logMessage = "ERROR: Could not read in the Student Billing Month for Month: \(billingMonth) with File Name: \(billingMonthStudentFileName)"
					await AppLogger.shared.log(logMessage, level: .error)
					return(false, logMessage)
				}
				
				var (resultFlag, resultMessage) = await tutorBillingMonth.copyTutorBillingMonth(billingMonth: billingMonth, billingMonthYear: billingYear, referenceData: referenceData)
				guard resultFlag else {
					return(false, resultMessage)
				}
				
			print("updateBillingStats already Billed Tutors \(tutorBillingMonth.tutorBillingRows.count)")
				(resultFlag, resultMessage) = await studentBillingMonth.copyStudentBillingMonth(billingMonth: billingMonth, billingMonthYear: billingYear, referenceData: referenceData)
				guard resultFlag else {
					return(false,resultMessage)
				}
						
				if alreadyBilledTutors.count > 0 {
					let (resetSuccess, resetMessage) = resetBillingStats(alreadyBilledTutors: alreadyBilledTutors, tutorBillingMonth: tutorBillingMonth, studentBillingMonth: studentBillingMonth, referenceData: referenceData, billingMonth: billingMonth, billingYear: billingYear)
					guard resetSuccess else {
						return (false, resetMessage)
					}
				}
				
				// Go through each line in the Invoice and update the Student, Tutor and Location billing stats in the Reference Data and
				// Tutor Billing and Student Billing spreadsheets
				var invoiceLineNum: Int = 0
				let invoiceLineCount: Int = invoice.invoiceLines.count
				while invoiceLineNum < invoiceLineCount {
					let tutorName = invoice.invoiceLines[invoiceLineNum].tutorName
					let studentName = invoice.invoiceLines[invoiceLineNum].studentName
					
					// Look for Billed Tutor in BilledTutor file for month.  However, Tutor may not be present if this is the first month the Tutor is being billed
					let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
					if billedTutorFound {
						
						// Look for Billed Student in BillStudent file for month.  However, Student may not be present if this is the first month the Student is being billed
						let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByStudentName(billedStudentName: studentName)
						if billedStudentFound {
							
							let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
							guard tutorFound else {
								logMessage = "ERROR: BillingVM:updateBillingStats: Could not find Tutor: \(tutorName) in Reference Data"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
								return(false,logMessage)
							}
							
							let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
							guard studentFound  else {
								logMessage = "ERROR: BillingVM:updateBillingStats: Could not find student: \(studentName) in Reference Data"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
								return(false, logMessage)
							}
							
							let studentLocation = referenceData.students.studentsList[studentNum].studentLocation
							let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: studentLocation)
							guard locationFound else {
								logMessage = "Error: BillingVM:updateBillingStats: Could not find Location: \(studentLocation) for Student: \(studentName) in Reference Data"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
								return(false, logMessage)
							}
							
							let duration = invoice.invoiceLines[invoiceLineNum].duration
							let cost = invoice.invoiceLines[invoiceLineNum].cost
							let revenue = invoice.invoiceLines[invoiceLineNum].amount
							let profit = revenue - cost
							
							tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledSessions += 1
							tutorBillingMonth.tutorBillingRows[billedTutorNum].totalBilledSessions += 1
							tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledHours += Double(duration) / 60.0
							tutorBillingMonth.tutorBillingRows[billedTutorNum].totalBilledHours += Double(duration) / 60.0
							tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledCost += cost
							tutorBillingMonth.tutorBillingRows[billedTutorNum].totalBilledCost += cost
							tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledRevenue += revenue
							tutorBillingMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue += revenue
							tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledProfit += profit
							tutorBillingMonth.tutorBillingRows[billedTutorNum].totalBilledProfit += profit
							
							
//							let quarterNum = getCurrentQuarter()
							switch billingQuarter {
								case 1:		// First quarter
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q1BilledSessions += 1
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q1BilledHours += Double(duration) / 60.0
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q1BilledCost += cost
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q1BilledRevenue += revenue
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q1BilledProfit += profit
									
								case 2:		// Second quarter
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q2BilledSessions += 1
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q2BilledHours += Double(duration) / 60.0
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q2BilledCost += cost
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q2BilledRevenue += revenue
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q2BilledProfit += profit
									
								case 3:		// Third quarter
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q3BilledSessions += 1
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q3BilledHours += Double(duration) / 60.0
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q3BilledCost += cost
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q3BilledRevenue += revenue
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q3BilledProfit += profit
									
								case 4:		// Fourth quarter
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q4BilledSessions += 1
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q4BilledHours += Double(duration) / 60.0
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q4BilledCost += cost
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q4BilledRevenue += revenue
									tutorBillingMonth.tutorBillingRows[billedTutorNum].q4BilledProfit += profit
								default:
									break
							}
							
							studentBillingMonth.studentBillingRows[billedStudentNum].monthBilledSessions += 1
							studentBillingMonth.studentBillingRows[billedStudentNum].totalBilledSessions += 1
							studentBillingMonth.studentBillingRows[billedStudentNum].monthBilledCost += cost
							studentBillingMonth.studentBillingRows[billedStudentNum].totalBilledCost += cost
							studentBillingMonth.studentBillingRows[billedStudentNum].monthBilledRevenue += revenue
							studentBillingMonth.studentBillingRows[billedStudentNum].totalBilledRevenue += revenue
							studentBillingMonth.studentBillingRows[billedStudentNum].monthBilledProfit += profit
							studentBillingMonth.studentBillingRows[billedStudentNum].totalBilledProfit += profit
							studentBillingMonth.studentBillingRows[billedStudentNum].tutorName = tutorName
							
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
							}
						}
					
					invoiceLineNum += 1
					}
				
				// After looping through each Invoice line and updating billing stats, save the Reference Data, Student Billing and Tutor Billing spreadsheets
				if resultFlag {
					resultFlag = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: billingMonthStudentFileID, billingMonth: billingMonth, saveValidatedStudentData: false)
					if resultFlag {
						do {
							(resultFlag, billingMonthTutorFileID) = try await getFileID(fileName: billingMonthTutorFileName)
							if resultFlag {
								
								resultFlag = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: billingMonthTutorFileID, billingMonth: billingMonth, saveValidatedTutorData: false)
								if resultFlag {
									let saveTutorResult = await referenceData.tutors.saveTutorData()
									let saveStudentResult = await referenceData.students.saveStudentData()
									let saveLocationResult = await referenceData.locations.saveLocationData()
									if !saveTutorResult || !saveStudentResult || !saveLocationResult {
										resultFlag = false
									}
								}
							} else {
								logMessage = "ERROR: Could not get File ID for Tutor Billing File: \(billingMonthTutorFileName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							}
						} catch {
							logMessage = "ERROR: Saving Tutor Billing Data for BillingMonth: \(billingMonth)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
							resultFlag = false
						}
					}
					
				}
			}
		} catch {
			logMessage = "Could not get File ID for Student Billing File: \(billingMonthStudentFileName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			resultFlag = false
		}
		
		return(resultFlag, "Sucessfully Reset Billing Stats")
	}
	
	// Create the CSV file in from the Invoice and stores in on disk
	//
	@MainActor func generateCSVFile(invoice: Invoice, billingMonth: String, billingYear: String, tutorBillingMonth: TutorBillingMonth, alreadyBilledTutors: [String], referenceData: ReferenceData) async -> (Bool, String) {
		var generationFlag: Bool = true
		var generationMessage: String = ""
		
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		// First update the billing stats for Tutors, Students and Locations
		(generationFlag, generationMessage) = await self.updateBillingStats(invoice: invoice, alreadyBilledTutors: alreadyBilledTutors, tutorBillingMonth: tutorBillingMonth, billingMonth: billingMonth, billingYear: billingYear, referenceData: referenceData)
		
		// Then update the Last Billed Date for each Student being billed
		
		if !generationFlag {
			print(generationMessage)
		} else {
			
			do {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
				let fileDate = dateFormatter.string(from: Date())
				
				let fileName = "CSV Export File for \(billingMonth) \(billingYear) generated on \(fileDate).csv"
				let fileManager = FileManager.default
				
				// Get the path to the Documents directory
				guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
					generationMessage = "ERROR: Could not find the Documents directory generating CSV File"
					print(generationMessage)
					await AppLogger.shared.log(generationMessage, level: .error)
					return(false, generationMessage)
				}
				print("CSV Documents directory: \(documentsDirectory.path)")
				
				// Build the path to our app's dedicated CSV subfolder inside Documents
				let csvDirectory = documentsDirectory.appendingPathComponent("WSAdmin CSV Files", isDirectory: true)
				
				// Create the subfolder if it doesn't already exist
				if !fileManager.fileExists(atPath: csvDirectory.path) {
					try fileManager.createDirectory(at: csvDirectory, withIntermediateDirectories: true, attributes: nil)
				}
				
				// Set the file path inside the CSV subfolder
				let fileURL = csvDirectory.appendingPathComponent(fileName)
				
				// Create the file if it doesn't exist
				if !fileManager.fileExists(atPath: fileURL.path) {
					fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
				}
				// Open the file for writing
				let fileHandle = try FileHandle(forWritingTo: fileURL)
				
				//Create a CSV header line in Xero format
				let csvLine = PgmConstants.csvXeroInvoiceHeader
				if let data = "\(csvLine)\n".data(using: .utf8) { // Convert each line to Data and add a newline
					fileHandle.write(data)
				}
				
				// Loop through the invoice and create a line in the CSV file from each Invoice line in format required by Xero package
				var invoiceLineNum = 0
				let invoiceLineCount = invoice.invoiceLines.count
				
				while invoiceLineNum < invoiceLineCount {
					let csvLine = processXeroInvoiceLine(invoiceLine: invoice.invoiceLines[invoiceLineNum], referenceData: referenceData)
					if let data = "\(csvLine)\n".data(using: .utf8) { // Convert each line to Data and add a newline
						fileHandle.write(data)
					}
					invoiceLineNum += 1
					// referenceData.dataCounts.increaseHighestInvoiceNumber()
				}
				// Save the Students List as the Last Billing Dates will have been updated
				await referenceData.students.saveStudentData()
				await referenceData.dataCounts.saveDataCounts()
				
				// Close the CSV file when done
				fileHandle.closeFile()
				print("Lines written to CSV file successfully.")
			} catch {
				generationFlag = false
				generationMessage = "Error: Could not write to CSV file: \(error)"
				print(generationMessage)
				await AppLogger.shared.log(generationMessage, level: .error)
			}
		}
		
		return(generationFlag, generationMessage)
	}
	
	// Format a CSV file line in Xero format from an Invoice file line
	//
	@MainActor func processXeroInvoiceLine(invoiceLine: InvoiceLine, referenceData: ReferenceData) -> String {
		var logMessage: String
		
		let invoiceNum = invoiceLine.invoiceNum
//		let invoiceNum = referenceData.dataCounts.highestInvoiceNumber + 1
		let invoiceClient = invoiceLine.clientName
		let invoiceEmail = invoiceLine.clientEmail
		let addressLine1 = invoiceLine.addressLine1
		let addressLine2 = invoiceLine.addressLine2
		let city = invoiceLine.city
		let state = invoiceLine.state
		let zipCode = invoiceLine.zipCode
		let invoiceDate = invoiceLine.invoiceDate
		let invoiceDueDate = invoiceLine.dueDate
		let invoiceReference = invoiceLine.studentName
//		let invoiceTerm = invoiceLine.terms
//		let invoiceLocation = invoiceLine.locationName
//		let invoiceTutor = invoiceLine.tutorName
		let invoiceItem = invoiceLine.itemName
		let invoiceDescription = invoiceLine.description
//		let invoiceQuantity = invoiceLine.quantity
		let invoiceServiceDate = invoiceLine.serviceDate
		let invoiceRate = invoiceLine.rate
		let invoiceAmount = String(invoiceLine.amount.formatted(.number.precision(.fractionLength(2))))
		let invoiceTaxCode = invoiceLine.taxCode
		let invoiceItemCode = invoiceLine.serviceCode

		let invoiceTaxType = "TAX EXEMPT"
		let invoiceAccountCode = referenceData.dataCounts.accountCode
		let invoiceBrandingTheme = "Standard"
		let invoiceQuantity = "1"
//		let invoiceItemCode = "100"
		
//		let invoicePOAddress1 = ""
//		let invoicePOAddress2 = ""
//		let invoicePOAddress3 = ""
//		let invoicePOAddress4 = ""
//		let invoicePOCity = ""
//		let invoicePORegion = ""
//		let invoicePOPostalCode = ""
//		let invoicePOCountry = ""
//		let invoicePOReference = ""
//		let invoiceDicount = ""
//		let invoiceTrackingName1 = ""
//		let invoiceTrackingoption1 = ""
//		let invoiceTrackingName2 = ""
//		let invoiceTrackingoption2 = ""
//		let invoiceCurrency = ""

		
		let csvLine = String(invoiceNum) + PgmConstants.csvSeperator + invoiceClient + PgmConstants.csvSeperator + invoiceEmail + PgmConstants.csvSeperator + addressLine1 + PgmConstants.csvSeperator + addressLine2  + PgmConstants.csvSeperator + city + PgmConstants.csvSeperator + state + PgmConstants.csvSeperator + zipCode + PgmConstants.csvSeperator + invoiceReference + PgmConstants.csvSeperator + invoiceDate + PgmConstants.csvSeperator + invoiceDueDate + PgmConstants.csvSeperator + invoiceItemCode + PgmConstants.csvSeperator + invoiceDescription + PgmConstants.csvSeperator + invoiceQuantity + PgmConstants.csvSeperator +  invoiceAmount + PgmConstants.csvSeperator + invoiceAccountCode + PgmConstants.csvSeperator + invoiceTaxType + PgmConstants.csvSeperator + invoiceBrandingTheme
		
		// Set the Last Billed Date for the Student to today's date
		let studentName = invoiceLine.studentName
		let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
		if studentFound {
			referenceData.students.studentsList[studentNum].updateLastBilledDate(serviceDate: invoiceServiceDate)
		} else {
			logMessage = "ERROR: Student not found when updating Student Last Billed Date"
			Task {
				await AppLogger.shared.log(logMessage, level: .error)
			}
			print(logMessage)
		}
		print ("Student \(studentName) Last Billed Date \(invoiceServiceDate) - \(referenceData.students.studentsList[studentNum].studentLastBilledDate)")
		return(csvLine)
	}
	
	// Format a CSV file line In Quickbooks format from an Invoice file line
	// This module is no longer used with the switch to Xero for accounting
	//
	@MainActor func processQBInvoiceLine(invoiceLine: InvoiceLine, referenceData: ReferenceData) -> String {
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
		let invoiceAmount = String(invoiceLine.amount.formatted(.number.precision(.fractionLength(2))))
		let invoiceTaxCode = invoiceLine.taxCode
		let invoiceServiceDate = invoiceLine.serviceDate
		let csvLine = invoiceNum + PgmConstants.csvSeperator + invoiceClient + PgmConstants.csvSeperator + invoiceEmail + PgmConstants.csvSeperator + invoiceDate + PgmConstants.csvSeperator + invoiceDueDate + PgmConstants.csvSeperator + invoiceTerm + PgmConstants.csvSeperator +  invoiceLocation + PgmConstants.csvSeperator + invoiceTutor + PgmConstants.csvSeperator + invoiceItem + PgmConstants.csvSeperator + invoiceDescription + PgmConstants.csvSeperator + invoiceQuantity + PgmConstants.csvSeperator + invoiceRate + PgmConstants.csvSeperator + invoiceAmount + PgmConstants.csvSeperator + invoiceTaxCode + PgmConstants.csvSeperator + invoiceServiceDate
		
		// Set the Last Billed Date for the Student to today's date
		let studentName = invoiceLine.studentName
		let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
		if studentFound {
			referenceData.students.studentsList[studentNum].updateLastBilledDate(serviceDate: invoiceServiceDate)
		} else {
			print ("ERROR: Student not found when updating Student Last Billed Date")
		}
		
		print ("Student: \(studentName) Last Billed Date \(invoiceServiceDate) - \(referenceData.students.studentsList[studentNum].studentLastBilledDate)")
		
		return(csvLine)
	}
	
	// Generate a CSV file of client data (student name, contact name, email, phone, zip code)
	//
	@MainActor func generateClientList(referenceData: ReferenceData) async -> (Bool, String) {
		var generationFlag: Bool = true
		var generationMessage: String = ""
		
		let fileManager = FileManager.default
		let csvDirectory = AppFolders.csvFilesDirectory
		
		do {
			// Create the "WSAdmin CSV Files" subfolder in Documents if it doesn't already exist
			if !fileManager.fileExists(atPath: csvDirectory.path) {
				try fileManager.createDirectory(at: csvDirectory, withIntermediateDirectories: true, attributes: nil)
			}
			
			do {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
				let fileDate = dateFormatter.string(from: Date())
				
				let fileName = "CSV Client List Generated on \(fileDate).csv"
				
				// Set the file path inside the CSV subfolder
				let fileURL = csvDirectory.appendingPathComponent(fileName)
				
				// Create the file if it doesn't exist
				if !fileManager.fileExists(atPath: fileURL.path) {
					fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
				}
				// Open the file for writing
				let fileHandle = try FileHandle(forWritingTo: fileURL)
				
				let csvLine = PgmConstants.csvClientListHeader
				if let data = "\(csvLine)\n".data(using: .utf8) { // Convert each line to Data and add a newline
					fileHandle.write(data)
				}
				
				// Loop through the Students List in the ReferenceData and create a line in the CSV file for each client name
				var studentNum =  0
				let studentCount = referenceData.students.studentsList.count
				while studentNum < studentCount {
					let csvLine = referenceData.students.studentsList[studentNum].studentContactFirstName + "," + referenceData.students.studentsList[studentNum].studentContactLastName + "," + referenceData.students.studentsList[studentNum].studentContactEmail + "," + referenceData.students.studentsList[studentNum].studentContactPhone + "," + referenceData.students.studentsList[studentNum].studentContactZipCode
					if let data = "\(csvLine)\n".data(using: .utf8) { // Convert each line to Data and add a newline
						fileHandle.write(data)
					}
					studentNum += 1
				}
				
				// Close the CSV file when done
				fileHandle.closeFile()
				print("Lines written to CSV file successfully.")
			} catch {
				print("Error: Could not write to CSV file: \(error)")
				generationFlag = false
				generationMessage = "Error: Could not write to CSV file: \(error)"
			}
		} catch {
			print("Error creating directory: \(error)")
			generationFlag = false
			generationMessage = "Error: could not create directory for CSV File"
		}
		
		return(generationFlag, generationMessage)
	}
	
	
	
	// Reset Tutor, Student and Location billing stats in the Reference Data, Tutor Billing and Student Billing spreadsheets (when Tutor is rebilled for a month) by removing session, cost, revenue and profit counts for the current billing month
	@MainActor func resetBillingStats(alreadyBilledTutors: [String], tutorBillingMonth: TutorBillingMonth, studentBillingMonth:StudentBillingMonth, referenceData: ReferenceData, billingMonth: String, billingYear: String) -> (Bool, String) {
		
		var statsMessage: String
		
		// Loop through each Tutor that was already billed
		var alreadyBilledTutorNum = 0
		let alreadyBilledTutorCount = alreadyBilledTutors.count
		while alreadyBilledTutorNum < alreadyBilledTutorCount {
			
			let tutorName = alreadyBilledTutors[alreadyBilledTutorNum]
			
			// Get a count of the number of Students already billed to this Tutor for the month
			let (billedStudentFound, alreadyBilledStudentNumbers) = studentBillingMonth.findBilledStudentsByTutorName(tutorName: tutorName)
			
			guard billedStudentFound else {
				statsMessage = "ERROR: Billed Student assigned to Tutor: \(tutorName) not found in Student Billing Month: \(billingMonth) \(billingYear)"
				print(statsMessage)
				Task {
					await AppLogger.shared.log(statsMessage, level: .error)
				}
				return(false, statsMessage)
			}
			
			// Loop through each Student assigned to the already billed Tutor
			var alreadyBilledStudentNum = 0
			while alreadyBilledStudentNum < alreadyBilledStudentNumbers.count {
				
				let billedStudentNum = alreadyBilledStudentNumbers[alreadyBilledStudentNum]
				let studentName = studentBillingMonth.studentBillingRows[billedStudentNum].studentName
		
				let sessions = studentBillingMonth.studentBillingRows[billedStudentNum].monthBilledSessions
				let cost = studentBillingMonth.studentBillingRows[billedStudentNum].monthBilledCost
				let revenue = studentBillingMonth.studentBillingRows[billedStudentNum].monthBilledRevenue
				
				// Reset the Student Billing month data for the Student
				studentBillingMonth.studentBillingRows[billedStudentNum].resetBilledStudentMonth(sessions: sessions, cost: cost, revenue: revenue, profit: revenue - cost)
				
				let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
				guard studentFound else {
					statsMessage = "ERROR: Student: \(studentName) not found in Reference Data resetting billing stats for \(billingMonth) \(billingYear)"
					Task {
						await AppLogger.shared.log(statsMessage, level: .error)
					}
					return(false, statsMessage)
				}
				// Reset the Reference Data for the Student
				referenceData.students.studentsList[studentNum].resetStudentBillingStats(monthSessions: sessions, monthCost: cost, monthRevenue: revenue)
				
				// Reset the Location data associated with the Student
				let studentLocation = referenceData.students.studentsList[studentNum].studentLocation
				let (locationFound,locationNum) = referenceData.locations.findLocationByName(locationName: studentLocation)
				guard locationFound  else {
					statsMessage = "ERROR: Location: \(studentLocation) not found in Reference Data resetting billing stats for \(billingMonth) \(billingYear)"
					print(statsMessage)
					Task {
						await AppLogger.shared.log(statsMessage, level: .error)
					}
					return (false, statsMessage)
				}
				referenceData.locations.locationsList[locationNum].resetLocationBillingStats(monthRevenue: revenue)
							
				alreadyBilledStudentNum += 1
				}
			
			let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
			guard billedTutorFound else {
				statsMessage = "ERROR: Tutor: \(tutorName) not found in Tutor Billing Month \(billingMonth) \(billingYear)"
				print(statsMessage)
				Task {
					await AppLogger.shared.log(statsMessage, level: .error)
				}
				return(false, statsMessage)
			}
				
			let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
			guard tutorFound else {
				statsMessage = "ERROR: Tutor: \(tutorName) not found in Reference Data billing stats for \(billingMonth) \(billingYear)"
				print(statsMessage)
				Task {
					await AppLogger.shared.log(statsMessage, level: .error)
				}
				return(false, statsMessage)
			}
			// Reset the Billed Tutor month data for the Tutor and the ReferenceData Tutor data
			let monthTutorSessions = tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledSessions
			let monthTutorCost = tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledCost
			let monthTutorRevenue = tutorBillingMonth.tutorBillingRows[billedTutorNum].monthBilledRevenue
			tutorBillingMonth.tutorBillingRows[billedTutorNum].resetBilledTutorMonth(billingMonth: billingMonth)
			referenceData.tutors.tutorsList[tutorNum].resetTutorBillingStats(sessions: monthTutorSessions, monthCost: monthTutorCost, monthRevenue: monthTutorRevenue)

			alreadyBilledTutorNum += 1
		}
		return(true, "Billing Statistics Reset for \(alreadyBilledTutorCount) Tutors")
	}
	
	// This function updates the Last Billed Dates for each Student by reading through all the Timesheets from system start (July 2025)
	@MainActor func updateStudentLastBilledDates(referenceData: ReferenceData, showBillingDiagnostics: Bool, showEachSession: Bool) async -> (Bool, String) {
		
		let updateResult: Bool = true
		let updateMessage: String = ""
		let billingMessages = WindowMessages()
		
		// Loop through each Tutor
		
		var tutorNum = 0
		while tutorNum < referenceData.tutors.tutorsList.count {
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			print("\nProcessing Tutor: \(tutorName)")
			
			// For each Tutor read in each year's Timesheet (some inactive Tutors will not have a Timesheet each year)
			var timesheetYearNum = 2024
			var timesheetMonthNum = 7
			while(timesheetYearNum < 2026) {
				
				let timesheetYearString = String(timesheetYearNum)
				
				while (timesheetMonthNum < 13) {
					let timesheetMonthString = monthArray[timesheetMonthNum - 1]
					print (timesheetYearString, timesheetMonthString)
					
					let timesheet = await getTimesheet(tutorName: tutorName, timesheetYear: timesheetYearString, timesheetMonth: timesheetMonthString, billingMessages: billingMessages, referenceData: referenceData, showBillingDiagnostics: showBillingDiagnostics, showEachSession: showEachSession)
					
					// For each month's Timesheet, read each row and update the Last Billed Date for that Student
					var timesheetNum = 0
					while timesheetNum < timesheet.timesheetRows.count {
						
						let studentName = timesheet.timesheetRows[timesheetNum].studentName
						let serviceDate = timesheet.timesheetRows[timesheetNum].serviceDate
						
						let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
						if studentFound {
							print ("\t\(studentName), \(serviceDate)")
							referenceData.students.studentsList[studentNum].updateLastBilledDate(serviceDate: serviceDate)
						} else {
							print ("Could not find Student: \(studentName)")
						}
						
						timesheetNum += 1
					}
					
					timesheetMonthNum += 1
				}
				
				timesheetYearNum += 1
				timesheetMonthNum = 1
			}
			
			
			
			tutorNum += 1
		}
		
		// Save the updated Student List
		
		await referenceData.students.saveStudentData()
		
		return(updateResult, updateMessage)
		
	}
	
}

