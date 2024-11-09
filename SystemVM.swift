//
//  ValidateSystemVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-28.
//
import Foundation

@Observable class SystemVM {
	
	//
	// This function does an integrity assessment of the data in the system by ensuring that counts and totals are equal across the system.  It does the following tests:
	//	- that the number of Students in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that the number of Services in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that the number of Locations in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that the number of Tutors in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that there is one Tutor Details sheet for each Tutor
	//	- that the count of Tutor Details sheets equals the number of non-deleted Tutors
	
	func validateSystem(referenceData: ReferenceData) async {
		print ("//")
		print("Validating System - Stand By for Adventure!")
		print("//")
		
		let (prevMonthName, prevMonthYear) = getPrevMonthYear()
		let prevBilledStudentMonth = await buildBilledStudentMonth(monthName: prevMonthName, yearName: prevMonthYear)
		let prevBilledTutorMonth = await buildBilledTutorMonth(monthName: prevMonthName, yearName: prevMonthYear)
				
		let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
		let currentBilledStudentMonth = await buildBilledStudentMonth(monthName: currentMonthName, yearName: currentMonthYear)
		let currentBilledTutorMonth = await buildBilledTutorMonth(monthName: currentMonthName, yearName: currentMonthYear)
	
		var locationRevenue: Float = 0.0
		var studentRevenue: Float = 0.0
		var tutorRevenue: Float = 0.0
		
		var tutorStudentCount: Int = 0
		var assignedStudentCount = 0
		
// Check if any Students assigned to more than one Tutor

		


		
// Validate that each Tutor has a Timesheet

		
// Check if the count of Students in the Tutor Details sheet matches the count for the Tutor in the Reference Data
		

// Check if the count of Services in the Tutor Details sheet matches the count for the Tutor in the Reference Data
		

		// Check that the number of Students in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalStudents = 0
		var activeStudents = 0
		var deletedStudents = 0
		
		var studentNum = 0
		let studentCount = referenceData.students.studentsList.count
		while studentNum < studentCount {
			let studentName = referenceData.students.studentsList[studentNum].studentName
			
			switch referenceData.students.studentsList[studentNum].studentStatus {
			case "Assigned":
				activeStudents += 1
				assignedStudentCount += 1
			case "Unassigned", "Suspended":
				activeStudents += 1
			case "Deleted":
				deletedStudents += 1
			default:
				print("Validation Error: Invalid Status for Student \(studentName)")
			}
			totalStudents += 1
			studentRevenue += referenceData.students.studentsList[studentNum].studentTotalRevenue
			// Check if Student found in Billed Student List for previous month
			if referenceData.students.studentsList[studentNum].studentStatus != "Deleted" {
				let (studentFoundFlag, billedStudentNum) = prevBilledStudentMonth.findBilledStudentByName(billedStudentName: studentName)
				if !studentFoundFlag {
					print("Validation Error: Student \(studentName) not found in Billed Student Month for \(prevMonthName)")
				}
				// If current Billed Student Month populated (i.e. billing has started for this month), check if Student is in current month Billed Student List
				if currentBilledStudentMonth.studentBillingRows.count > 0 {
					let (studentFoundFlag, billedStudentNum) = currentBilledStudentMonth.findBilledStudentByName(billedStudentName: studentName)
					if !studentFoundFlag {
						print("Validation Error: Student \(studentName) not found in Billed Student Month for \(currentMonthName)")
					}
				}
				// Validate the Location Name for the Student
				let (findResult, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
				if !findResult {
					print("Validation Error: Location \(referenceData.students.studentsList[studentNum].studentLocation) for Student \(studentName) not found in Locations List")
				}
			}
			studentNum += 1
		}
		print("          Total Students \(totalStudents), Active Students \(activeStudents), Deleted Students \(deletedStudents)")

		if totalStudents != referenceData.dataCounts.totalStudents {
			print("Validation Error: Reference Data Count for Total Students \(referenceData.dataCounts.totalStudents) does not match actual count in Reference Data Students list of \(totalStudents)")
		}
		if activeStudents != referenceData.dataCounts.activeStudents {
			print("Validation Error: Reference Data Count for Active Students \(referenceData.dataCounts.activeStudents) does not match actual count in Reference Data Students list of \(activeStudents)")
		}
		//		if deletedStudents != referenceData.dataCounts.totalStudents - referenceData.dataCounts.activeStudents  {
		//			print("Validation Error: Reference Data Count for Deleted Students \(referenceData.dataCounts.deletedStudents) does not match actual count in Reference Data Students list of \(deletedStudents)")
		//		}

		
		// Check that the number of Services in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalServices = 0
		var activeServices = 0
		var deletedServices = 0
		
		var serviceNum = 0
		let serviceCount = referenceData.services.servicesList.count
		while serviceNum < serviceCount {
			switch referenceData.services.servicesList[serviceNum].serviceStatus {
			case "Unassigned", "Assigned":
				activeServices += 1
			case "Deleted", "Suspended":
				deletedServices += 1
			default:
				print("Invalid Status for Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)")
			}
			totalServices += 1
			
			serviceNum += 1
		}
		print("          Total Services \(totalServices), Active Services \(activeServices), Deleted Services \(deletedServices)")
		if totalServices != referenceData.dataCounts.totalServices {
			print("Validation Error: Reference Data Count for Total Services \(referenceData.dataCounts.totalServices) does not match actual count in Reference Data Services list of \(totalServices)")
		}
		if activeServices != referenceData.dataCounts.activeServices {
			print("Validation Error: Reference Data Count for Active Services \(referenceData.dataCounts.activeServices) does not match actual count in Reference Data Services list of \(activeServices)")
		}
//		if deletedServices != referenceData.dataCounts.totalServices - referenceData.dataCounts.activeServices  {
//			print("Validation Error: Reference Data Count for Deleted Services \(referenceData.dataCounts.deletedServices) does not match actual count in Reference Data Services list of \(deletedServices)")
//		}
		
		// Check that the number of Locations in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalLocations = 0
		var activeLocations = 0
		var deletedLocations = 0
		
		var locationNum = 0
		var locationStudents = 0
		let locationCount = referenceData.locations.locationsList.count
		while locationNum < locationCount {
			switch referenceData.locations.locationsList[locationNum].locationStatus {
			case "Active":
				activeLocations += 1
			case "Deleted":
				deletedLocations += 1
			default:
				print("Validation Error: Invalid Location Status for Location \(referenceData.locations.locationsList[locationNum].locationName)")
			}
			locationStudents += referenceData.locations.locationsList[locationNum].locationStudentCount
			totalLocations += 1
			locationRevenue += referenceData.locations.locationsList[locationNum].locationTotalRevenue
			
			locationNum += 1
		}
		print("          Total Locations \(totalLocations), Active Locations \(activeLocations), Deleted Locations \(deletedLocations)")
		
		if locationStudents != activeStudents {
			print("Validation Error: Count of Location Students \(locationStudents) does not match actual count of Students in Reference Data Locations list of \(activeStudents)")
		}
		if totalLocations != referenceData.dataCounts.totalLocations {
			print("Validation Error: Reference Data Count for Total Locations \(referenceData.dataCounts.totalLocations) does not match actual count in Reference Data Locations list of \(totalLocations)")
		}
		if activeLocations != referenceData.dataCounts.activeLocations {
			print("Validation Error: Reference Data Count for Active Locations \(referenceData.dataCounts.activeLocations) does not match actual count in Reference Data Locations list of \(activeLocations)")
		}
		//		if deletedLocations != referenceData.dataCounts.totalLocations - referenceData.dataCounts.activeLocations  {
		//			print("Validation Error: Reference Data Count for Deleted Locations \(referenceData.dataCounts.deletedLocations) does not match actual count in Reference Data Locations list of \(deletedLocations)")
		//		}

		
		// Check that the number of Tutors in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalTutors = 0
		var activeTutors = 0
		var deletedTutors = 0
		var sheetNum: Int?
		
		var tutorNum = 0
		let tutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < tutorCount {
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			switch referenceData.tutors.tutorsList[tutorNum].tutorStatus {
			case "Assigned":
				activeTutors += 1
				tutorStudentCount += referenceData.tutors.tutorsList[tutorNum].tutorStudentCount
			case "Unassigned", "Suspended":
				activeTutors += 1
				if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount != 0 {
					print("Validation Error: Student Count for \(tutorName) not equal to zero and Tutor Status is not Assigned")
				}
			case "Deleted":
				deletedTutors += 1
				if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount != 0 {
					print("Validation Error: Student Count for \(tutorName) not equal to zero and Tutor Status is not Assigned")
				}
			default:
				print("Validation Error: Invalid Tutor Status for Tutor \(tutorName)")
			}
			

			if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
				// Validate that there is one Tutor Details sheet for each active (non-deleted) Tutor
				do {
					sheetNum = try await getSheetIdByName(spreadsheetId: tutorDetailsFileID, sheetName: tutorName )
				} catch {
					print("Validation Error: could not get Tutor Details sheet ID for Tutor \(tutorName)")
				}
				if sheetNum == nil {
					print("Validation Error: could not get Tutor Details sheet ID for Tutor \(tutorName)")
				}
				
				// Check if Tutor found in Billed Tutor List for previous month
				let (tutorFoundFlag, billedTutorNum) = prevBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
				if !tutorFoundFlag {
					print("Validation Error: Tutor \(tutorName) not found in Billed Tutor Month for \(prevMonthName)")
				}
				
				// If current Billed Tutor Month populated (i.e. billing has started for this month), check if Tutor is in current month Billed Tutor List
				if currentBilledTutorMonth.tutorBillingRows.count > 0 {
					let (tutorFoundFlag, billedTutorNum) = currentBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
					if !tutorFoundFlag {
						print("Validation Error: Tutor \(tutorName) not found in Billed Tutor Month for \(currentMonthName)")
					}
				}
				
				// Check if Student and Service counts in the Tutor Details sheet match the Tutor's counts in the Reference Data entry for the Tutor
				let (studentCount, serviceCount) = await referenceData.tutors.tutorsList[tutorNum].fetchTutorDataCounts(tutorName: tutorName)
				if studentCount != referenceData.tutors.tutorsList[tutorNum].tutorStudentCount {
					print("Validation Error: Reference Data Service count for Tutor \(tutorName) is \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) but Tutor Details count is \(studentCount)")
				}
				
				if serviceCount != referenceData.tutors.tutorsList[tutorNum].tutorServiceCount {
					print("Validation Error: Reference Data Service count for Tutor \(tutorName) is \(referenceData.tutors.tutorsList[tutorNum].tutorServiceCount) but Tutor Details count is \(serviceCount)")
				}
			}
			
			totalTutors += 1
			tutorRevenue += referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue
			
			tutorNum += 1
		}
		
		print("          Total Tutors \(totalTutors), Active Tutors \(activeTutors), Deleted Tutors \(deletedTutors)")
		
		do {
			let tutorDetailsSheetCount = try await getSheetCount(spreadsheetId: tutorDetailsFileID)
			if (tutorDetailsSheetCount - 1) != activeTutors {	// Subtract 1 from sheet count for shared RefData sheet
				print("Validation Error - count of active tutors: \(activeTutors) does not equal number of Tutor Details sheets: \(tutorDetailsSheetCount)")
			}
		} catch {
			print("ERROR: could get get count of TutorDetails sheets")
		}
		
		if totalTutors != referenceData.dataCounts.totalTutors {
			print("Validation Error: Reference Data Count for Total Tutors \(referenceData.dataCounts.totalTutors) does not match actual count in Reference Data Tutors list of \(totalTutors)")
		}
		if activeTutors != referenceData.dataCounts.activeTutors {
			print("Validation Error: Reference Data Count for Active Tutors \(referenceData.dataCounts.activeTutors) does not match actual count in Reference Data Tutors list of \(activeTutors)")
		}
		//		if deletedTutors != referenceData.dataCounts.totalTutors - referenceData.dataCounts.activeTutors  {
		//			print("Validation Error: Reference Data Count for Deleted Tutors \(referenceData.dataCounts.deletedTutors) does not match actual count in Reference Data Tutors list of \(deletedTutors)")
		//		}



// Validate that the Tutor names in the Master Reference worksheet match the tutor names in the Tutors Billing spreadsheet
		

// Validate that the Student names in the Master Reference worksheet match the student names in the Student Billing spreadsheet
		

// Validate that the sum of the Tutors total billing equals Student total billing equals City total billing
		if tutorRevenue != studentRevenue || studentRevenue != locationRevenue || tutorRevenue != locationRevenue {
			print("Validation Error: Tutor revenue \(tutorRevenue), Student revenue \(studentRevenue) and Location revenue \(locationRevenue) do not match")
		}
		
		if tutorStudentCount != assignedStudentCount {
			print("Validation Error: Tutor Student count \(tutorStudentCount) does not match assigned Student count \(assignedStudentCount)")
		}

// Validate master reference spreadsheet file key matches the import file keys in each timesheet and timesheet template

// Validate that the total number of Tutors in the previous month Billed Tutor List is equal to the number of active Tutors
		
		if prevBilledTutorMonth.tutorBillingRows.count != activeTutors {
			print("Validation Error: Active Tutor count \(activeTutors) does not match number of Tutors in \(prevMonthName) Billed Tutor list \(prevBilledTutorMonth.tutorBillingRows.count)")
		}

		// Validate that the total number of Students in the previous month Billed Student List is equal to the number of active Students\
		
		if prevBilledStudentMonth.studentBillingRows.count != activeStudents {
			print("Validation Error: Active Student count \(activeStudents) does not match number of Students in \(prevMonthName) Billed Student list \(prevBilledStudentMonth.studentBillingRows.count)")
		}

		
	}
	//
	// This function creates backup copies of the key Google Drive spreadsheets for the system.  Copied files are suffixed with current date and time.  If the system is running
	// against the production files, they are backed up. If its running against the test files, those are backed up.
	//	1) The ReferenceData spreadsheet
	//	2) The TutorDetails spreadsheet
	//	3) The Billed Tutor spreadsheet for the current year
	//	4) The Billed Student spreadsheet for the current year
	//
	func backupSystem() async {
		print("Backing up system")
		
		var tutorBillingFileName: String = ""
		var studentBillingFileName: String = ""
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
		let backupDate = dateFormatter.string(from: Date())
		dateFormatter.dateFormat = "yyyy"
		let currentYear = dateFormatter.string(from: Date())

		do {
			// Copy the Reference Data spreadsheet
			try await copyGoogleDriveFile(sourceFileId: referenceDataFileID, newFileName: PgmConstants.referenceDataProdFileName + " Backup " + backupDate)
			print("Reference Data spreadsheet copied to file: \(PgmConstants.referenceDataProdFileName + " Backup " + backupDate)")
			
			// Copy the Tutor Details spreadsheet
			try await copyGoogleDriveFile(sourceFileId: tutorDetailsFileID, newFileName: PgmConstants.tutorDetailsProdFileName + " Backup " + backupDate)
			print("Tutor Details spreadsheet copied to file: \(PgmConstants.tutorDetailsProdFileName + " Backup " + backupDate)")
			
			// Copy the Tutor Billing spreadsheet
			tutorBillingFileName = tutorBillingFileNamePrefix + currentYear
			let (tutorFileFound, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			try await copyGoogleDriveFile(sourceFileId: tutorBillingFileID, newFileName: tutorBillingFileName + " Backup " + backupDate)
			print("Billed Tutor spreadsheet copied to file: \(tutorBillingFileName + " Backup " + backupDate)")
			
			// Copy the Student Billing spreadsheet
			studentBillingFileName = studentBillingFileNamePrefix + currentYear
			let (studentFileFound, studentBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			try await copyGoogleDriveFile(sourceFileId: studentBillingFileID, newFileName: studentBillingFileName + " Backup " + backupDate)
			print("Billed Student spreadsheet copied to file: \(studentBillingFileName + " Backup " + backupDate)")
		} catch {
			print("ERROR: Could not backup application files")
		}
		
	}
	//
	// This function creates a new Billed Tutor object for a month, reads in the data for that month and returns that new Billed Tutor object
	//		monthName: the month to load the Billed Tutor data for
	//		yearName: the year of the month to load the Billed Tutor data for
	//
	func buildBilledTutorMonth(monthName: String, yearName: String) async -> TutorBillingMonth {
		let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
		var fileIdResult: Bool = true
		var tutorBillingFileID = ""
		let tutorBillingMonth = TutorBillingMonth()
		
		// Get the fileID of the Billed Tutor spreadsheet for the year containing the month's Billed Tutor data
		do {
			(fileIdResult, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
		} catch {
			print("Could not get FileID for file: \(tutorBillingFileName)")
		}
		// Read the data from the Billed Tutor spreadsheet for the month into a new TutorBillingMonth object
		if fileIdResult {
			await tutorBillingMonth.loadTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID)
		} else {
			print("ERROR: could notget FileID for file: \(tutorBillingFileName)")
		}
		return(tutorBillingMonth)
	}
	//
	// This function creates a new Billed Student object for a month, reads in the data for that month and returns that new Billed Student object
	//		monthName: the month to load the Billed Student data for
	//		yearName: the year of the month to load the Billed Student data for
	//
	func buildBilledStudentMonth(monthName: String, yearName: String) async -> StudentBillingMonth {
		let studentBillingFileName = studentBillingFileNamePrefix + yearName
		var fileIdResult: Bool = true
		var studentBillingFileID = ""
		let studentBillingMonth = StudentBillingMonth()
		
		// Get the fileID of the Billed Student spreadsheet for the year containing the month's Billed Student data
		do {
			(fileIdResult, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
		} catch {
			print("Could not get FileID for file: \(studentBillingFileName)")
		}
		// Read the data from the Billed Student spreadsheet for the month into a new StudentBillingMonth object
		if fileIdResult {
			await studentBillingMonth.loadStudentBillingMonth(monthName: monthName, studentBillingFileID: studentBillingFileID)
		} else {
			print("ERROR: could notget FileID for file: \(studentBillingFileName)")
		}
		return(studentBillingMonth)
	}
	
	func generateNewYearFiles(referenceData: ReferenceData) async {
		var nextYear: String = ""
		var newTimesheetFileID: String = ""
		
		if let yearInt = Calendar.current.dateComponents([.year], from: Date()).year {
			nextYear = String(yearInt + 1)
			
			let newTutorBillingProdFileName = PgmConstants.tutorBillingProdFileNamePrefix + nextYear
			let newTutorBillingTestFileName = PgmConstants.tutorBillingTestFileNamePrefix + nextYear
			let tutorBillingTemplateFileName = PgmConstants.billedTutorTemplateFileName
			
			do {
				let (fileFound, tutorBillingTemplateFileID) = try await getFileID(fileName: tutorBillingTemplateFileName)
				if fileFound {
					do {
						if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: tutorBillingTemplateFileID, newFileName: newTutorBillingProdFileName) {
							
							if let fileID = copiedFileData["id"] as? String {
								newTimesheetFileID = fileID
							} else {
								print("No valid string found for the key 'name'")
							}
						}
					} catch {
						print("ERROR:  Could not create Billed Tutor Prod file: \(newTutorBillingProdFileName)")
					}
					
					do {
						if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: tutorBillingTemplateFileID, newFileName: newTutorBillingTestFileName) {
							
							if let fileID = copiedFileData["id"] as? String {
								newTimesheetFileID = fileID
							} else {
								print("No valid string found for the key 'name'")
							}
						}
					} catch {
						print("ERROR:  Could not create Billed Tutor Test file: \(newTutorBillingTestFileName)")
					}
				} else {
					print("ERROR: Could not get File ID for Tutor Billing Template file \(tutorBillingTemplateFileName)")
				}
			} catch {
				print("ERROR: Could not get File ID for \(tutorBillingTemplateFileName)")
			}
			
			let newStudentBillingProdFileName = PgmConstants.studentBillingProdFileNamePrefix + nextYear
			let newStudentBillingTestFileName = PgmConstants.studentBillingTestFileNamePrefix + nextYear
			let studentBillingTemplateFileName = PgmConstants.billedStudentTemplateFileName
			
			do {
				let (fileFound, studentBillingTemplateFileID) = try await getFileID(fileName: studentBillingTemplateFileName)
				if fileFound {
					do {
						if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: studentBillingTemplateFileID, newFileName: newStudentBillingProdFileName) {
							
							if let fileID = copiedFileData["id"] as? String {
								newTimesheetFileID = fileID
							} else {
								print("No valid string found for the key 'name'")
							}
						}
					} catch {
						print("ERROR:  Could not create Billed Student Prod file: \(newStudentBillingProdFileName)")
					}
					
					do {
						if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: studentBillingTemplateFileID, newFileName: newStudentBillingTestFileName) {
							
							if let fileID = copiedFileData["id"] as? String {
								newTimesheetFileID = fileID
							} else {
								print("No valid string found for the key 'name'")
							}
						}
					} catch {
						print("ERROR:  Could not create Billed Student Test file: \(newStudentBillingTestFileName)")
					}
				} else {
					print("ERROR: Could not get File ID for Student Billing Template file \(studentBillingTemplateFileName)")
				}
			} catch {
				print("ERROR: Could not get File ID for \(studentBillingTemplateFileName)")
			}
			
			var tutorNum = 0
			let tutorCount = referenceData.tutors.tutorsList.count
			while tutorNum < tutorCount {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
					let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
					let tutorEmail = referenceData.tutors.tutorsList[tutorNum].tutorEmail
					let newTutorTimesheetName = "Timesheet " + nextYear + " " + tutorName
					do {
						if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: timesheetTemplateFileID, newFileName: newTutorTimesheetName) {
							
							if let fileID = copiedFileData["id"] as? String {
								newTimesheetFileID = fileID
								try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: tutorEmail)
							} else {
								print("No valid string found for the key 'name'")
							}
							
						}
					} catch {
						print("ERROR:  Could not create Timesheet for Tutor: \(tutorName)")
					}
				}
				tutorNum += 1
			}
		}
		
		
		
	}
}


