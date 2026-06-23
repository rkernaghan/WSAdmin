//
//  Timesheet.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-15.
//

import Foundation

// Timesheet is a class to hold one Tutor Timesheet for one month.  It consists of an array of TimesheetRow classes, each of which holds a Timesheet row (one tutoring session)
//
class Timesheet: Identifiable {
	var timesheetRows = [TimesheetRow]()
	var isTimesheetLoaded: Bool
	
	init() {
		isTimesheetLoaded = false
	}
//
// This function adds one row to a Timesheet
//		timesheetRow: an object containing data from one row of a Timesheet spreadsheet
	func addTimesheetRow(timesheetRow: TimesheetRow) {
		self.timesheetRows.append(timesheetRow)
	}

//
// This function reads in a Tutor Timesheet for one month and loads the data into this Timesheet object
//		tutorName: the name of the tutor who's Timesheet is being loaded
//		month: the String name of the month to load the Timesheet data from
//		timesheetID: the Google Drive File ID of the Tutor Timesheet
//
	@MainActor func loadTimesheetData(tutorName: String, month: String, timesheetID: String, billingMessages: WindowMessages, referenceData: ReferenceData, showBillingDiagnostics: Bool, showEachSession: Bool) async -> Bool {
		var completionFlag: Bool = true
		
		// Read in the header rows from the Timesheet to get the number of sessions in the Timesheet from Cell Bs
		var headerData: SheetData?
		var range = month + PgmConstants.timesheetHeaderRange
		do {
			headerData = try await readSheetCells(fileID: timesheetID, range: range)
		}
		catch {
			print("ERROR: in Timesheet.loadTimesheetData - Could not read header rows for \(tutorName) Timesheet with File ID \(timesheetID)")
			billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: in Timesheet.loadTimesheetData - could not read header rows for \(tutorName) Timesheet File ID \(timesheetID)"))
			completionFlag = false
		}
		
		let sessionCount = Int(headerData?.values[PgmConstants.timesheetSessionCountLocationRow][PgmConstants.timesheetSessionCountLocationCol] ?? "100") ?? 100
		
		range = month + PgmConstants.timesheetSessionRange + String(PgmConstants.timesheetHeaderRowCount + sessionCount + PgmConstants.timesheetMaxBlankRowCount )
		// read in the cells from one month's Timesheet
		do {
			var sheetData: SheetData?
			sheetData = try await readSheetCells(fileID: timesheetID, range: range)
			// Load the sheet cells into this Timesheet
			if let sheetData = sheetData {
				loadTimesheetRows(tutorName: tutorName, sheetCells: sheetData.values, sessionCount: sessionCount, billingMessages: billingMessages, monthName: month, referenceData: referenceData, showBillingDiagnostics: showBillingDiagnostics, showEachSession: showEachSession)
			} else {
				completionFlag = false
			}
		} catch {
			print("ERROR: in Timesheet.loadTimesheetData - Could not read SheetCells for \(tutorName) Timesheet with File ID \(timesheetID)")
			billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: in Timesheet.loadTimesheetData - could not read SheetCells for \(tutorName) Timesheet File ID \(timesheetID)"))
			completionFlag = false
		}
		return(completionFlag)
	}

//
// This function takes a 2 dimensional array of strings (spreadsheet cells from a Tutor Timesheet for a month) and loads them into this Timesheet object
//		tutorName: the name of the tutor who's Timesheet is being loaded
//		sheetCells: a 2 dimensional array of Strings with each element containing one spreadsheet cell
//		sessionCount: the number of sessions billed in the Timesheet (from the formula in Timesheet cell B3
//		billingMessages:
//		monthName:
//		referenceData:
//		showBillingMessages:
//		showEachSession:
//
	@MainActor func loadTimesheetRows(tutorName: String, sheetCells: [[String]], sessionCount: Int, billingMessages: WindowMessages, monthName: String, referenceData: ReferenceData, showBillingDiagnostics: Bool, showEachSession: Bool) {
		
		var duration: Int = 0
		let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
		if !tutorFoundFlag {
			billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: " ** Error in Timesheet.loadTimesheetRows - Tutor \(tutorName) not found in Reference Data"))
		}
		
		// CHeck if at least one session in the Timesheet
		if sheetCells.count > 0 {
//			let entryCount = Int(sheetCells[PgmConstants.timesheetSessionCountRow][PgmConstants.timesheetSessionCountCol]) ?? 0		// Number of session rows in Timesheet
			// entryCounter counts actual sessions whereas rowNum counts rows as there may be blank rows in the Timesheet
			var entryCounter = 0														// Current session being processed in loop
//			var rowNum = PgmConstants.timesheetFirstSessionRow
			var rowNum: Int = 0
			
			// Loop through each row in Timesheet; stop when all sessions processed or 12th extra Timesheet row without a valid session encountered
			let rowCounter = sessionCount + PgmConstants.timesheetMaxBlankRowCount                                               							// 12 blank rows allowed
			while entryCounter < sessionCount && rowNum < rowCounter {
				// Check if the session has at least 9 cells (not missing fields)
				let cellCount = sheetCells[rowNum].count
				if cellCount < 9 {						// Check if all required Timesheet cells populated for this row, else ignore the row and warn
					print("Skipping row \(rowNum) as it only has \(cellCount) cells")
					billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: Skipping Timesheet row \(rowNum + 1) as it only has \(cellCount) cells"))
				} else {
					// Validate session date
					let date = sheetCells[rowNum][PgmConstants.timesheetDateCol]
					if date == "" || date == " " {
						print("WARNING: Date missing for Session on Timesheet row \(rowNum + 1); skipping this entry")
						billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Date missing for Session on Timesheet row \(rowNum + 1); skipping this entry"))
					} else {
						// validate student name not empty
						let student = sheetCells[rowNum][PgmConstants.timesheetStudentCol]
						if student == "" || student == "-" || student == " " {
							print("WARNING: Student cell empty for \(date) on timesheet row \(rowNum + 1)")
							billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Student cell empty for \(date) on Timesheet row \(rowNum + 1)"))
						} else {
							// Validate Student assigned to Tutor being billed
							let (tutorStudentFound, tutorStudentNum) = referenceData.tutors.tutorsList[tutorNum].findTutorStudentByName(studentName: student)
							if !tutorStudentFound {
								print("WARNING: Student: \(student) on Timesheet row \(rowNum + 1) not assigned to Tutor \(tutorName)")
								billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Student: \(student) on Timesheet row \(rowNum + 1) not assigned to Tutor \(tutorName)"))
							} else {
								// Check if service date is for month being billed (Warning only - processing of the session continues)
								let validateDateFlag = validateDateField(dateField: date, monthName: monthName)
								if !validateDateFlag {
									print("WARNING: Date: \(date) not within \(monthName) for Student \(student) in Timesheet row \(rowNum + 1)")
									billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Date: \(date) not within \(monthName) for Student \(student) in Timesheet row \(rowNum + 1)"))
								}
								// Validate session duration not blank
								let durationCell = sheetCells[rowNum][PgmConstants.timesheetDurationCol]
								if durationCell == "" || durationCell == " " {
									print("WARNING: Duration cell empty for \(date) with Student \(student) in Timesheet row \(rowNum + 1)")
									billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Duration cell empty for \(date) with Student \(student) in Timesheet row \(rowNum + 1)"))
								} else {
									// Validate duration field an integer > 0
									duration = Int(durationCell) ?? 0
									if duration == 0 {
										print("WARNING: Duration cell = 0 for \(date) with Student \(student) in Timesheet row \(rowNum + 1)")
										billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Duration cell = 0 for \(date) with Student \(student) in Timesheet row \(rowNum + 1)"))
									} else {
										// Validate the Service field is not blank
										let service = sheetCells[rowNum][PgmConstants.timesheetServiceCol]
										if service == "" || service == "-" || service == " " {
											print("WARNING: Service cell empty for \(date) with Student \(student) in Timesheet row \(rowNum + 1)")
											billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Service cell empty for \(date) with Student \(student) in Timesheet row \(rowNum + 1)"))
										} else {
											// Validate the session Service is assigned to the Tutor
											let (tutorServiceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByName(serviceName: service)
											if !tutorServiceFound {
												print("WARNING: Service: \(service) on Timesheet row \(rowNum + 1) not assigned to Tutor \(tutorName)")
												billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Service: \(service) on Timesheet row \(rowNum + 1) not assigned to Tutor \(tutorName)"))
											} else {
												
												let notes = sheetCells[rowNum][PgmConstants.timesheetNotesCol]
												
												// Validate the Client Name field is not empty
												let clientName = sheetCells[rowNum][PgmConstants.timesheetClientNameCol]
												if clientName == "" || clientName == " " {
													print("WARNING: Client Name cell empty for \(date) with Student \(student) on Timesheet row \(rowNum + 1)")
													billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "**   Warning: Client Name cell empty for \(date) with Student \(student) in Timesheet row \(rowNum + 1)"))
												} else {
													
													let cost = Double(sheetCells[rowNum][PgmConstants.timesheetCostCol]) ?? 0.0
													
													let clientEmail = sheetCells[rowNum][PgmConstants.timesheetClientEmailCol]
													let clientPhone = sheetCells[rowNum][PgmConstants.timesheetClientPhoneCol]
													
													let newTimesheetRow = TimesheetRow(studentName: student, serviceDate: date, duration: duration, timesheetServiceName: service, notes: notes, cost: cost, clientName: clientName, clientEmail: clientEmail, clientPhone: clientPhone, tutorName: tutorName)
													self.addTimesheetRow(timesheetRow: newTimesheetRow)
													
													if showEachSession {
														billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "                      Student: \(student);  Date: \(date);  Duration: \(duration);  Service: \(service);  Cost: \(cost)"))
													}
													
													entryCounter += 1
												}
											}
										}
									}
								}
								
							}
						}
					}
				}
			rowNum += 1
			}
			// Display the total number of sessions for the Tutor in the Timesheet
			billingMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "                 \(tutorName) Session Count for \(monthName): \(entryCounter)"))

		}
	}
	
}
