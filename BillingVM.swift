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

        // This function will generate an online invoice for the selected tutors to be billed so it can be displayed to the user (to determine whether to generate the CSV file and update billing stats).
	
	func generateInvoice(tutorSet: Set<Tutor.ID>, billingYear: String, billingMonth: String, referenceData: ReferenceData, billingMessages: BillingMessages) async -> (Invoice, TutorBillingMonth, [String]) {
		var invoice = Invoice()
		var tutorList = [String]()
		var tutorBillingFileID: String = ""
		var resultFlag: Bool = true
		var alreadyBilledFlag: Bool = false
		var alreadyBilledTutors = [String]()
		
		let tutorBillingMonth = TutorBillingMonth(monthName: billingMonth)
		
		let tutorBillingFileName = tutorBillingFileNamePrefix + billingYear
		let billArray = BillArray(monthName: billingMonth)
		print ("\n ** Starting Generate Invoice **")
		
		// Go through each selected Tutor, read the Tutor's Timesheet and add the data to the billArray.
		for objectID in tutorSet {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				print("Read Timesheet for Tutor: \(tutorName)")
				billingMessages.addMessage(billingMessage: BillingMessage(billingMessageText: "          Information: Processing Timesheet for Tutor: \(tutorName)"))
				tutorList.append(tutorName)
				
				let timesheet = await getTimesheet(tutorName: tutorName, timesheetYear: billingYear, timesheetMonth: billingMonth, billingMessages: billingMessages)
				
				billArray.processTimesheet(timesheet: timesheet, billingMessages: billingMessages)
			}
		}
		
		// Load Billed Tutor month for current month. If this month has already been billed, get list of already billed Tutors for the month. Then
		// generate the Invoice.
		do {
			(resultFlag, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			if !resultFlag {
				print("Error: Could not get File ID for Tutor Billing file \(tutorBillingFileName)")
			} else {
				let loadBilledTutorFlag = await tutorBillingMonth.loadTutorBillingMonth(monthName: billingMonth, tutorBillingFileID: tutorBillingFileID)
				if loadBilledTutorFlag {				// If no Tutors billed this month, the flag will be false, which is not an error
					(alreadyBilledFlag, alreadyBilledTutors) = tutorBillingMonth.checkAlreadyBilled(tutorList: tutorList)
					
					if alreadyBilledFlag {
						print("Already Billed Tutors: \(alreadyBilledTutors)")
						billingMessages.addMessage(billingMessage: BillingMessage(billingMessageText: "          Information: Tutors already billed for month: \(alreadyBilledTutors)"))
					}
				}
				invoice = billArray.generateInvoice(alreadyBilledTutors: alreadyBilledTutors, referenceData: referenceData)
			}
		} catch {
			print("Error: could not load Billed Tutor Month")
			billingMessages.addMessage(billingMessage: BillingMessage(billingMessageText: "Error: could not load Billed Tutor Month"))
			
		}
		
		// Return the invoice data, the Tutor Billing data for the month so it can be updated if user bills the invoice (creates CSV) and the list of any Tutors already billed
		billingMessages.addMessage(billingMessage: BillingMessage(billingMessageText: "          Information: Invoice generation completed"))
		return(invoice, tutorBillingMonth, alreadyBilledTutors)
		
	}
	
	// Read in a Timesheet for a Tutor
	func getTimesheet(tutorName: String, timesheetYear: String, timesheetMonth: String, billingMessages: BillingMessages) async -> Timesheet {
		let timesheet = Timesheet()
		var timesheetFileID: String = " "
		var result: Bool = true
		
		let fileName = "Timesheet " + timesheetYear + " " + tutorName
		do {
			(result, timesheetFileID) = try await getFileID(fileName: fileName)
			if result {
				let timesheetResult = await timesheet.loadTimesheetData(tutorName: tutorName, month: timesheetMonth, timesheetID: timesheetFileID, billingMessages: billingMessages)
				if !timesheetResult {
					print("Error: Could not load Timesheet for Tutor \(tutorName)")
					billingMessages.addMessage(billingMessage: BillingMessage(billingMessageText: "Error: Could not load Timesheet for Tutor \(tutorName)"))
				}
			}
		} catch {
			print("Error: could not get timesheet fileID for \(fileName)")
			billingMessages.addMessage(billingMessage: BillingMessage(billingMessageText: "Error: could not get timesheet fileID for \(fileName)"))
		}

		return(timesheet)
	}
	

	// Update the billing stats for Tutors, Students and Locations in the Reference Data, Student Billing and Tutor Billing spreadsheets.  If the Tutor was already billed, reset the billing stats
	// for that Tutor before updating the billing stats
	func updateBillingStats(invoice: Invoice, alreadyBilledTutors: [String], tutorBillingMonth: TutorBillingMonth, billingMonth: String, billingYear: String, referenceData: ReferenceData) async -> Bool {
		
		print(" Starting updating billing stats for \(billingMonth)")
		
		var billingMonthStudentFileID: String = ""
		var billingMonthTutorFileID: String = ""
		
		let studentBillingMonth = StudentBillingMonth(monthName: billingMonth)
		var resultFlag: Bool = false
		
		let (prevMonth, prevMonthYear) = findPrevMonthYear(currentMonth: billingMonth, currentYear: billingYear)
		
		let billingMonthStudentFileName = studentBillingFileNamePrefix + billingYear
		let billingMonthTutorFileName = tutorBillingFileNamePrefix + billingYear

		
		do {
			// Read in the current month Student Billing month, copy the previous month's Student and Tutor billing months to current month's files
			(resultFlag, billingMonthStudentFileID) = try await getFileID(fileName: billingMonthStudentFileName)
			if resultFlag {
				resultFlag = await studentBillingMonth.getStudentBillingMonth(monthName: billingMonth, studentBillingFileID: billingMonthStudentFileID)
				if resultFlag {
					resultFlag = await tutorBillingMonth.copyTutorBillingMonth(billingMonth: billingMonth, billingMonthYear: billingYear, referenceData: referenceData)
					if resultFlag {
						resultFlag = await studentBillingMonth.copyStudentBillingMonth(billingMonth: billingMonth, billingMonthYear: billingYear, referenceData: referenceData)
						if resultFlag {
							
							if alreadyBilledTutors.count > 0 {
								resetBillingStats(alreadyBilledTutors: alreadyBilledTutors, tutorBillingMonth: tutorBillingMonth, studentBillingMonth: studentBillingMonth, referenceData: referenceData, billingMonth: billingMonth, billingYear: billingYear)
							}
							
							// Go through each line in the Invoice and update the Student, Tutor and Location billing stats in the Reference Data and
							// Tutor Billing and Student Billing spreadsheets
							var invoiceLineNum: Int = 0
							let invoiceLineCount: Int = invoice.invoiceLines.count
							while invoiceLineNum < invoiceLineCount {
								let tutorName = invoice.invoiceLines[invoiceLineNum].tutorName
								let studentName = invoice.invoiceLines[invoiceLineNum].studentName
								let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
								if billedTutorFound {
									let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByStudentName(billedStudentName: studentName)
									if billedStudentFound {
										let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
										if tutorFound {
											let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
											if studentFound {
												let studentLocation = referenceData.students.studentsList[studentNum].studentLocation
												let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: studentLocation)
												if locationFound {
												
													let cost = invoice.invoiceLines[invoiceLineNum].cost
													let revenue = invoice.invoiceLines[invoiceLineNum].amount
													let profit = revenue - cost
													
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
										}
									}
								}
								invoiceLineNum += 1
							}
							
							// After looping through each Invoice line and updating billing stats, save the Reference Data, Student Billing and Tutor Billing spreadsheets
							if resultFlag {
								resultFlag = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: billingMonthStudentFileID, billingMonth: billingMonth)
								if resultFlag {
									do {
										(resultFlag, billingMonthTutorFileID) = try await getFileID(fileName: billingMonthTutorFileName)
										if resultFlag {
											
											resultFlag = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: billingMonthTutorFileID, billingMonth: billingMonth)
											if resultFlag {
												let saveTutorResult = await referenceData.tutors.saveTutorData()
												let saveStudentResult = await referenceData.students.saveStudentData()
												let saveLocationResult = await referenceData.locations.saveLocationData()
												if !saveTutorResult || !saveStudentResult || !saveLocationResult {
													resultFlag = false
												}
											}
										} else {
											print("Could not get File ID for Tutor Billing File \(billingMonthTutorFileName)")
										}
									} catch {
										print("Error Saving Tutor Billing Data")
										resultFlag = false
									}
								}
							}
						}
					}
				}
			}
		} catch {
			print("Could not get File ID for Student Billing File \(billingMonthStudentFileName)")
			resultFlag = false
		}
		
		return(resultFlag)
	}
	
	// Create the CSV file from the Invoice and stores in on disk
	func generateCSVFile(invoice: Invoice, billingMonth: String, billingYear: String, tutorBillingMonth: TutorBillingMonth, alreadyBilledTutors: [String], referenceData: ReferenceData) async -> (Bool, String) {
		var generationFlag: Bool = true
		var generationMessage: String = ""
		
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let userCSVURL = documentsURL.appendingPathComponent("CSVFiles")
		
		// First update the billing stats for Tutors, Students and Locations
		generationFlag = await self.updateBillingStats(invoice: invoice, alreadyBilledTutors: alreadyBilledTutors, tutorBillingMonth: tutorBillingMonth, billingMonth: billingMonth, billingYear: billingYear, referenceData: referenceData)
		if !generationFlag {
			generationMessage = "Error: Could not update Billing Stats"
			print("Error: Could not update billing stats")
		} else {
			do {
				// Create the file in the Documents directory
				try FileManager.default.createDirectory(at: userCSVURL, withIntermediateDirectories: true, attributes: nil)
				
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
					
					let csvLine = PgmConstants.csvHeader
					if let data = "\(csvLine)\n".data(using: .utf8) { // Convert each line to Data and add a newline
						fileHandle.write(data)
					}
					
					// Loop through the invoice and create a line in the CSV file from each Invoice line
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
		}
		
		return(generationFlag, generationMessage)
	}
	
	// Format a CSV file line from an Invoice file line
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
		let invoiceAmount = String(invoiceLine.amount.formatted(.number.precision(.fractionLength(2))))
		let invoiceTaxCode = invoiceLine.taxCode
		let invoiceServiceDate = invoiceLine.serviceDate
		let csvLine = invoiceNum + PgmConstants.csvSeperator + invoiceClient + PgmConstants.csvSeperator + invoiceEmail + PgmConstants.csvSeperator + invoiceDate + PgmConstants.csvSeperator + invoiceDueDate + PgmConstants.csvSeperator + invoiceTerm + PgmConstants.csvSeperator +  invoiceLocation + PgmConstants.csvSeperator + invoiceTutor + PgmConstants.csvSeperator + invoiceItem + PgmConstants.csvSeperator + invoiceDescription + PgmConstants.csvSeperator + invoiceQuantity + PgmConstants.csvSeperator + invoiceRate + PgmConstants.csvSeperator + invoiceAmount + PgmConstants.csvSeperator + invoiceTaxCode + PgmConstants.csvSeperator + invoiceServiceDate 
		return(csvLine)
	}
	
	// Reset Tutor, Student and Location billing stats in the Reference Data, Tutor Billing and Student Billing spreadsheets (when Tutor is rebilled for a month) by removing session, cost, revenue and profit counts for the current billing month
	func resetBillingStats(alreadyBilledTutors: [String], tutorBillingMonth: TutorBillingMonth, studentBillingMonth:StudentBillingMonth, referenceData: ReferenceData, billingMonth: String, billingYear: String) {
		
		// Loop through each Tutor that was already billed
		var alreadyBilledTutorNum = 0
		let alreadyBilledTutorCount = alreadyBilledTutors.count
		while alreadyBilledTutorNum < alreadyBilledTutorCount {
			
			let tutorName = alreadyBilledTutors[alreadyBilledTutorNum]
			let (billedStudentFound, alreadyBilledStudentNumbers) = studentBillingMonth.findBilledStudentsByTutorName(tutorName: tutorName)
			
			if billedStudentFound {
				
				// Loop through each Student assigned to the already billed Tutor
				var alreadyBilledStudentNum = 0
				while alreadyBilledStudentNum < alreadyBilledStudentNumbers.count {
					
					let billedStudentNum = alreadyBilledStudentNumbers[alreadyBilledStudentNum]
					let studentName = studentBillingMonth.studentBillingRows[billedStudentNum].studentName
			
					let sessions = studentBillingMonth.studentBillingRows[billedStudentNum].monthSessions
					let cost = studentBillingMonth.studentBillingRows[billedStudentNum].monthCost
					let revenue = studentBillingMonth.studentBillingRows[billedStudentNum].monthRevenue
					
					// Reset the Student Billing month data for the Student
					studentBillingMonth.studentBillingRows[billedStudentNum].resetBilledStudentMonth(sessions: sessions, cost: cost, revenue: revenue, profit: revenue - cost)
					
					let (studentFound, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
					if studentFound {
						// Reset the Reference Data for the Student
						referenceData.students.studentsList[studentNum].resetBillingStats(monthSessions: sessions, monthCost: cost, monthRevenue: revenue)
						
						// Reset the Location data associated with the Student
						let studentLocation = referenceData.students.studentsList[studentNum].studentLocation
						let (locationFound,locationNum) = referenceData.locations.findLocationByName(locationName: studentLocation)
						if locationFound {
							referenceData.locations.locationsList[locationNum].resetBillingStats(monthRevenue: revenue)
						}
					} else {
						print ("Error: Student \(studentName) not found in Reference Data")
					}
					
					alreadyBilledStudentNum += 1
				}
			} else {
				print("Error: Billed Student assigned to Tutor \(tutorName) not found in Student Billing Month \(billingMonth) \(billingYear)")
			}
			
			
			let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
			if billedTutorFound {
				
				let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
				if tutorFound {
					// Reset the Billed Tutor month data for the Tutor and the ReferenceData Tutor data
					let monthTutorSessions = tutorBillingMonth.tutorBillingRows[billedTutorNum].monthSessions
					let monthTutorCost = tutorBillingMonth.tutorBillingRows[billedTutorNum].monthCost
					let monthTutorRevenue = tutorBillingMonth.tutorBillingRows[billedTutorNum].monthRevenue
					tutorBillingMonth.tutorBillingRows[billedTutorNum].resetBilledTutorMonth()
					referenceData.tutors.tutorsList[tutorNum].resetBillingStats(sessions: monthTutorSessions, monthCost: monthTutorCost, monthRevenue: monthTutorRevenue)
					
				} else {
					print("Error: Tutor \(tutorName) not found in Reference Data")
				}
			} else {
				print("Error: Tutor \(tutorName) not found in Tutor Billing Month \(billingMonth) \(billingYear)")
			}
			
			alreadyBilledTutorNum += 1
		}
	}
	
}
