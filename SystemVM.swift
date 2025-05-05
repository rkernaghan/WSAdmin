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
	
	func validateSystem(referenceData: ReferenceData, validationMessages: WindowMessages) async {
		
		var billedTutorMonth = TutorBillingMonth(monthName: "")
		var billedStudentMonth = StudentBillingMonth(monthName: "")
		var billedMonthName: String = ""
		
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "\n** Validating System - Stand By for Adventure! **"))
		
		let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
		
		billedTutorMonth = await buildBilledTutorMonth(monthName: currentMonthName, yearName: currentMonthYear, loadValidatedData: false)
		if billedTutorMonth.tutorBillingRows.count > 0 {
			billedStudentMonth = await buildBilledStudentMonth(monthName: currentMonthName, yearName: currentMonthYear, loadValidatedData: false)
			billedMonthName = currentMonthName
		} else {
			let (prevMonthName, prevMonthYear) = getPrevMonthYear()
			billedStudentMonth = await buildBilledStudentMonth(monthName: prevMonthName, yearName: prevMonthYear, loadValidatedData: false)
			billedTutorMonth = await buildBilledTutorMonth(monthName: prevMonthName, yearName: prevMonthYear, loadValidatedData: false)
			billedMonthName = prevMonthName
		}
		
		var locationRevenue: Float = 0.0
		var studentRevenue: Float = 0.0
		var studentCost: Float = 0.0
		var tutorRevenue: Float = 0.0
		var tutorCost: Float = 0.0
		
		var tutorSessions: Int = 0
		var studentSessions: Int = 0
		
		var tutorStudentCount: Int = 0
		var assignedStudentCount = 0
		
		// Check if any Students assigned to more than one Tutor
		
		var studentNum = 0
		let studentCount = referenceData.students.studentsList.count
		while studentNum < studentCount {
			let studentKey = referenceData.students.studentsList[studentNum].studentKey
			let studentName = referenceData.students.studentsList[studentNum].studentName
			var tutorNum:Int = 0
			var assignedCount:Int = 0
			var assignedTutors:String = ""
			let tutorCount = referenceData.tutors.tutorsList.count
			while tutorNum < tutorCount {
				let (studentFound, tutorStudentNum) = referenceData.tutors.tutorsList[tutorNum].findTutorStudentByKey(studentKey: studentKey)
				if studentFound {
					assignedCount += 1
					assignedTutors += referenceData.tutors.tutorsList[tutorNum].tutorName + "; "
				}
				tutorNum += 1
			}
			if assignedCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Warning: \(studentName) assigned to Tutors \(assignedTutors)"))
			}
			studentNum += 1
		}
		
		
		
		// Validate that each Tutor has a Timesheet
		
		
		
		
		studentNum = 0
		while studentNum < studentCount {
			
			// Check for duplicate Student keys
			let studentKey = referenceData.students.studentsList[studentNum].studentKey
			let studentKeyCount = referenceData.students.studentsList.filter { $0.studentKey == studentKey }.count
			if studentKeyCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Student Key \(studentKey) for \(referenceData.students.studentsList[studentNum].studentName)"))
			}
			
			// Check for duplicate Student names
			let studentName = referenceData.students.studentsList[studentNum].studentName
			let studentNameCount = referenceData.students.studentsList.filter { $0.studentName == studentName }.count
			if studentNameCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Student Name \(studentName)"))
			}
			
			studentNum += 1
		}
		
		var serviceNum = 0
		let serviceCount = referenceData.services.servicesList.count
		while serviceNum < serviceCount {
			
			// Check for duplicate Service keys
			let serviceKey = referenceData.services.servicesList[serviceNum].serviceKey
			let serviceKeyCount = referenceData.services.servicesList.filter { $0.serviceKey == serviceKey }.count
			if serviceKeyCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Service Key \(serviceKey) for Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"))
			}
			
			// Check for duplicate Service names
			let serviceName = referenceData.services.servicesList[serviceNum].serviceTimesheetName
			let serviceNameCount = referenceData.services.servicesList.filter { $0.serviceTimesheetName == serviceName }.count
			if serviceNameCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Service Name \(serviceName)"))
			}
			serviceNum += 1
		}
		
		var locationNum = 0
		let locationCount = referenceData.locations.locationsList.count
		while locationNum < locationCount {
			
			// Check for duplicate Location keys
			let locationKey = referenceData.locations.locationsList[locationNum].locationKey
			let locationKeyCount = referenceData.locations.locationsList.filter { $0.locationKey == locationKey }.count
			if locationKeyCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Location Key \(locationKey) for Location \(referenceData.locations.locationsList[locationNum].locationName)"))
			}
			// Check for duplicate Location names
			let locationName = referenceData.locations.locationsList[locationNum].locationName
			let locationNameCount = referenceData.locations.locationsList.filter { $0.locationName == locationName }.count
			if locationNameCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Location Name \(locationName)"))
			}
			
			locationNum += 1
		}
		
		var tutorNum = 0
		let tutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < tutorCount {
			
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			
			// Check for duplicate Tutor Keys in Reference Data
			let tutorKey = referenceData.tutors.tutorsList[tutorNum].tutorKey
			let tutorKeyCount = referenceData.tutors.tutorsList.filter { $0.tutorKey == tutorKey }.count
			if tutorKeyCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Tutor Key \(tutorKey)"))
			}
			
			// Check for duplicate Tutor Names in Reference Data
			let tutorNameCount = referenceData.tutors.tutorsList.filter { $0.tutorName == tutorName }.count
			if tutorNameCount > 1 {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Duplicate Tutor Name \(tutorName)"))
			}
			
			// Check that the Student Keys in the Reference Dasta matches the Student Keys in the Tutor Details file for each Tutor
			var tutorStudentNum = 0
			let tutorStudentCount = referenceData.tutors.tutorsList[tutorNum].tutorStudents.count
			while tutorStudentNum < tutorStudentCount {
				let tutorStudentKey = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentKey
				let tutorStudentName = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentName
				let (studentFound, studentNum) = referenceData.students.findStudentByKey(studentKey: tutorStudentKey)
				if studentFound {
					let studentName = referenceData.students.studentsList[studentNum].studentName
					
					if studentName != tutorStudentName {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: \(tutorStudentKey) associated with \(studentName) in Reference Data and \(tutorStudentName) in Tutor Details for Tutor \(tutorName)"))
					}
				} else {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: \(tutorStudentKey) not found in Reference Data"))
				}
				tutorStudentNum += 1
			}
			
			// Check that the Service Keys in the Reference Dasta matches the Service Keys in the Tutor Details file for each Tutor
			var tutorServiceNum = 0
			let tutorServiceCount = referenceData.tutors.tutorsList[tutorNum].tutorServices.count
			while tutorServiceNum < tutorServiceCount {
				let tutorServiceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
				let tutorServiceName = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName
				
				let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: tutorServiceKey)
				if serviceFound {
					let serviceName = referenceData.services.servicesList[serviceNum].serviceTimesheetName
					
					if serviceName != tutorServiceName {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: \(tutorServiceKey) associated with \(serviceName) in Reference Data and \(tutorServiceName) in Tutor Details for Tutor \(tutorName)"))
					}
				} else {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: \(tutorServiceKey) not found in Reference Data"))
				}
				tutorServiceNum += 1
			}
			
			
			tutorNum += 1
		}
		
		
		
		// Check that the number of Students in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalStudents = 0
		var activeStudents = 0
		var deletedStudents = 0
		
		studentNum = 0
		//		studentCount = referenceData.students.studentsList.count
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
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Invalid Status for Student \(studentName)"))
			}
			totalStudents += 1
			studentRevenue += referenceData.students.studentsList[studentNum].studentTotalRevenue
			studentCost += referenceData.students.studentsList[studentNum].studentTotalCost
			studentSessions += referenceData.students.studentsList[studentNum].studentSessions
			
			// Check if Student found in Billed Student List for current/previous month
			if referenceData.students.studentsList[studentNum].studentStatus != "Deleted" {
				let (studentFoundFlag, billedStudentNum) = billedStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
				if !studentFoundFlag {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Student \(studentName) not found in Billed Student Month for \(billedMonthName)"))
				}
				
				// Validate the Location Name for the Student
				let (findResult, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
				if !findResult {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Location \(referenceData.students.studentsList[studentNum].studentLocation) for Student \(studentName) not found in Locations List"))
				}
			}
			studentNum += 1
		}
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "          Total Students \(totalStudents), Active Students \(activeStudents), Deleted Students \(deletedStudents)"))
		
		if totalStudents != referenceData.dataCounts.totalStudents {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Reference Data Count for Total Students \(referenceData.dataCounts.totalStudents) does not match actual count in Reference Data Students list of \(totalStudents)"))
		}
		if activeStudents != referenceData.dataCounts.activeStudents {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Reference Data Count for Active Students \(referenceData.dataCounts.activeStudents) does not match actual count in Reference Data Students list of \(activeStudents)"))
		}
		//		if deletedStudents != referenceData.dataCounts.totalStudents - referenceData.dataCounts.activeStudents  {
		//			print("Validation Error: Reference Data Count for Deleted Students \(referenceData.dataCounts.deletedStudents) does not match actual count in Reference Data Students list of \(deletedStudents)")
		//		}
		
		
		// Check that the number of Services in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalServices = 0
		var activeServices = 0
		var deletedServices = 0
		
		serviceNum = 0
		while serviceNum < serviceCount {
			switch referenceData.services.servicesList[serviceNum].serviceStatus {
				case "Unassigned", "Assigned":
					activeServices += 1
				case "Deleted", "Suspended":
					deletedServices += 1
				default:
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Invalid Status for Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"))
			}
			totalServices += 1
			
			serviceNum += 1
		}
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"          Total Services \(totalServices), Active Services \(activeServices), Deleted Services \(deletedServices)"))
		if totalServices != referenceData.dataCounts.totalServices {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Reference Data Count for Total Services \(referenceData.dataCounts.totalServices) does not match actual count in Reference Data Services list of \(totalServices)"))
		}
		if activeServices != referenceData.dataCounts.activeServices {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Reference Data Count for Active Services \(referenceData.dataCounts.activeServices) does not match actual count in Reference Data Services list of \(activeServices)"))
		}
		//		if deletedServices != referenceData.dataCounts.totalServices - referenceData.dataCounts.activeServices  {
		//			print("Validation Error: Reference Data Count for Deleted Services \(referenceData.dataCounts.deletedServices) does not match actual count in Reference Data Services list of \(deletedServices)")
		//		}
		
		// Check that the number of Locations in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalLocations = 0
		var activeLocations = 0
		var deletedLocations = 0
		
		locationNum = 0
		var locationStudents = 0
		while locationNum < locationCount {
			switch referenceData.locations.locationsList[locationNum].locationStatus {
				case "Active":
					activeLocations += 1
				case "Deleted":
					deletedLocations += 1
				default:
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Invalid Location Status for Location \(referenceData.locations.locationsList[locationNum].locationName)"))
			}
			locationStudents += referenceData.locations.locationsList[locationNum].locationStudentCount
			totalLocations += 1
			locationRevenue += referenceData.locations.locationsList[locationNum].locationTotalRevenue
			
			locationNum += 1
		}
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "          Total Locations \(totalLocations), Active Locations \(activeLocations), Deleted Locations \(deletedLocations)"))
		
		
		if locationStudents != activeStudents {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Count of Location Students \(locationStudents) does not match actual count of Students in Reference Data Locations list of \(activeStudents)"))
		}
		if totalLocations != referenceData.dataCounts.totalLocations {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Reference Data Count for Total Locations \(referenceData.dataCounts.totalLocations) does not match actual count in Reference Data Locations list of \(totalLocations)"))
		}
		if activeLocations != referenceData.dataCounts.activeLocations {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Reference Data Count for Active Locations \(referenceData.dataCounts.activeLocations) does not match actual count in Reference Data Locations list of \(activeLocations)"))
		}
		//		if deletedLocations != referenceData.dataCounts.totalLocations - referenceData.dataCounts.activeLocations  {
		//			print("Validation Error: Reference Data Count for Deleted Locations \(referenceData.dataCounts.deletedLocations) does not match actual count in Reference Data Locations list of \(deletedLocations)")
		//		}
		
		
		// Check that the number of Tutors in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalTutors = 0
		var activeTutors = 0
		var deletedTutors = 0
		var sheetNum: Int?
		
		tutorNum = 0
		while tutorNum < tutorCount {
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			switch referenceData.tutors.tutorsList[tutorNum].tutorStatus {
				case "Assigned":
					activeTutors += 1
					tutorStudentCount += referenceData.tutors.tutorsList[tutorNum].tutorStudentCount
				case "Unassigned", "Suspended":
					activeTutors += 1
					if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount != 0 {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Student Count for \(tutorName) not equal to zero and Tutor Status is not Assigned"))
					}
				case "Deleted":
					deletedTutors += 1
					if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount != 0 {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Student Count for \(tutorName) not equal to zero and Tutor Status is not Assigned"))
					}
				default:
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Invalid Tutor Status for Tutor \(tutorName)"))
			}
			
			
			if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
				// Validate that there is one Tutor Details sheet for each active (non-deleted) Tutor
				do {
					sheetNum = try await getSheetIdByName(spreadsheetId: tutorDetailsFileID, sheetName: tutorName )
				} catch {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: could not get Tutor Details sheet ID for Tutor \(tutorName)"))
				}
				if sheetNum == nil {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: could not get Tutor Details sheet ID for Tutor \(tutorName)"))
				}
				
				// Check if Tutor found in Billed Tutor List for previous month
				let (tutorFoundFlag, billedTutorNum) = billedTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
				if !tutorFoundFlag {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Tutor \(tutorName) not found in Billed Tutor Month for \(billedMonthName)"))
				}
				
				// Check if Student and Service counts in the Tutor Details sheet match the Tutor's counts in the Reference Data entry for the Tutor
				let (studentCount, serviceCount, timesheetFileID) = await referenceData.tutors.tutorsList[tutorNum].fetchTutorDataCounts(tutorName: tutorName)
				if studentCount != referenceData.tutors.tutorsList[tutorNum].tutorStudentCount {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Reference Data Service count for Tutor \(tutorName) is \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) but Tutor Details count is \(studentCount)"))
				}
				
				if serviceCount != referenceData.tutors.tutorsList[tutorNum].tutorServiceCount {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Reference Data Service count for Tutor \(tutorName) is \(referenceData.tutors.tutorsList[tutorNum].tutorServiceCount) but Tutor Details count is \(serviceCount)"))
				}
				
			}
			
			totalTutors += 1
			tutorRevenue += referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue
			tutorCost += referenceData.tutors.tutorsList[tutorNum].tutorTotalCost
			tutorSessions += referenceData.tutors.tutorsList[tutorNum].tutorTotalSessions
			
			tutorNum += 1
		}
		
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "          Total Tutors \(totalTutors), Active Tutors \(activeTutors), Deleted Tutors \(deletedTutors)"))
		
		do {
			let tutorDetailsSheetCount = try await getSheetCount(spreadsheetId: tutorDetailsFileID)
			if (tutorDetailsSheetCount - 1) != activeTutors {	// Subtract 1 from sheet count for shared RefData sheet
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error - count of active tutors: \(activeTutors) does not equal number of Tutor Details sheets: \(tutorDetailsSheetCount)"))
			}
		} catch {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: could get get count of TutorDetails sheets"))
		}
		
		if totalTutors != referenceData.dataCounts.totalTutors {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Reference Data Count for Total Tutors \(referenceData.dataCounts.totalTutors) does not match actual count in Reference Data Tutors list of \(totalTutors)"))
		}
		if activeTutors != referenceData.dataCounts.activeTutors {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Reference Data Count for Active Tutors \(referenceData.dataCounts.activeTutors) does not match actual count in Reference Data Tutors list of \(activeTutors)"))
		}
		//		if deletedTutors != referenceData.dataCounts.totalTutors - referenceData.dataCounts.activeTutors  {
		//			print("Validation Error: Reference Data Count for Deleted Tutors \(referenceData.dataCounts.deletedTutors) does not match actual count in Reference Data Tutors list of \(deletedTutors)")
		//		}
		
		
		
		// Validate that the Tutor names in the Master Reference worksheet match the tutor names in the Tutors Billing spreadsheet
		
		
		// Validate that the Student names in the Master Reference worksheet match the student names in the Student Billing spreadsheet
		
		
		
		// Get the session count, total cost and total revenue for the previous Billed Student month (current month may not be done yet)
		var billedStudentSessionCount: Int  = 0
		var billedStudentTotalCost: Float = 0.0
		var billedStudentTotalRevenue: Float = 0.0
		var billedStudentNum = 0
		let billedStudentCount = billedStudentMonth.studentBillingRows.count
		while billedStudentNum < billedStudentCount {
			billedStudentSessionCount += billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledSessions
			billedStudentTotalRevenue += billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue
			billedStudentTotalCost += billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost
			
			billedStudentNum += 1
		}
		
		// Get the session count, total cost and total revenue for the previous Bill Tutor month (current month may not be done yet)
		var billedTutorSessionCount: Int  = 0
		var billedTutorTotalCost: Float = 0.0
		var billedTutorTotalRevenue: Float = 0.0
		var billedTutorNum = 0
		let billedTutorCount = billedTutorMonth.tutorBillingRows.count
		while billedTutorNum < billedTutorCount {
			//			print("Billed Tutor: \(billedTutorMonth.tutorBillingRows[billedTutorNum].tutorName)  \(billedTutorMonth.tutorBillingRows[billedTutorNum].totalBillingSessions)")
			billedTutorSessionCount += billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledSessions
			billedTutorTotalRevenue += billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue
			billedTutorTotalCost += billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost
			
			billedTutorNum += 1
		}
		
		// Validate that the sum of the Tutors total revenue equals Student total revenue equals Location total revenue equals Billed Student revenue count equals Billed Tutor revenue Count
		if tutorRevenue != studentRevenue || studentRevenue != locationRevenue || tutorRevenue != locationRevenue || locationRevenue != billedTutorTotalRevenue || billedTutorTotalRevenue != billedStudentTotalRevenue {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Tutor revenue \(tutorRevenue), Student revenue \(studentRevenue), Location revenue \(locationRevenue), Billed Tutor revenue \(billedTutorTotalRevenue) and Billed Student revenue \(billedStudentTotalRevenue) do not match"))
			
			// If total Student revenue in RefData does not equal total Student revenue in Billed Student list, find the difference
			if studentRevenue != billedStudentTotalRevenue {
				var studentNum = 0
				let studentCount = referenceData.students.studentsList.count
				while studentNum < studentCount {
					let studentName = referenceData.students.studentsList[studentNum].studentName
					let refStudentRevenue = referenceData.students.studentsList[studentNum].studentTotalRevenue
					let (studentFoundFlag, billedStudentNum) = billedStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
					if !studentFoundFlag {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: could not find Student \(studentName) in Billed Student month comparing Student revenue differences"))
					} else {
						let billedStudentRevenue = billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue
						if billedStudentRevenue != refStudentRevenue {
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Billed Student revenue \(billedStudentRevenue) does not match Reference Data Student revenue \(refStudentRevenue) for \(studentName) "))
						}
					}
					studentNum += 1
				}
			}
			
			// If total Tutor revenue in RefData does not equal total Tutor revenue in Billed Tutor list, find the difference
			if tutorRevenue != billedTutorTotalRevenue {
				var tutorNum = 0
				let tutorCount = referenceData.tutors.tutorsList.count
				while tutorNum < tutorCount {
					let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
					let refTutorRevenue = referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue
					let (tutorFoundFlag, billedTutorNum) = billedTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
					if !tutorFoundFlag {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Error: could not find Tutor \(tutorName) in Billed Tutor month comparing Tutor revenue differences"))
					} else {
						let billedTutorRevenue = billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue
						if billedTutorRevenue != refTutorRevenue {
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Billed Tutor revenue \(billedTutorRevenue) does not match Reference Data Tutor revenue \(refTutorRevenue) for \(tutorName) "))
						}
					}
					tutorNum += 1
				}
			}
		}
		
		// Validate that the Tutors total cost, Student total cost, billed Student total cost and billed Tutor Total Cost all match
		if tutorCost != studentCost || studentCost != billedTutorTotalCost || billedTutorTotalCost != billedStudentTotalCost {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Tutor cost \(tutorCost), Student cost \(studentCost), Billed Tutor cost \(billedStudentTotalCost) and Billed Student total cost \(billedStudentTotalCost) do not match"))
			
			// If total Student cost in RefData does not equal total Student cost in Billed Student list, find the difference
			if studentCost != billedStudentTotalCost {
				var studentNum = 0
				let studentCount = referenceData.students.studentsList.count
				while studentNum < studentCount {
					let studentName = referenceData.students.studentsList[studentNum].studentName
					let refStudentCost = referenceData.students.studentsList[studentNum].studentTotalCost
					let (studentFoundFlag, billedStudentNum) = billedStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
					if !studentFoundFlag {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Error: could not find Student \(studentName) in Billed Student month comparing Student cost differences"))
					} else {
						let billedStudentCost = billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost
						if billedStudentCost != refStudentCost {
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Billed Student cost \(billedStudentCost) does not match Reference Data Student cost \(refStudentCost) for \(studentName) "))
						}
					}
					studentNum += 1
				}
			}
			
			// If total Tutor cost in RefData does not equal total Tutor cost in Billed Tutor list, find the difference
			if tutorCost != billedTutorTotalCost {
				var tutorNum = 0
				let tutorCount = referenceData.tutors.tutorsList.count
				while tutorNum < tutorCount {
					let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
					let refTutorCost = referenceData.tutors.tutorsList[tutorNum].tutorTotalCost
					let (tutorFoundFlag, billedTutorNum) = billedTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
					if !tutorFoundFlag {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: could not find Tutor \(tutorName) in Billed Tutor month comparing Tutor cost differences"))
					} else {
						let billedTutorCost = billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost
						if billedTutorCost != refTutorCost {
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Billed Tutor cost \(billedTutorCost) does not match Reference Data Tutor cost \(refTutorCost) for \(tutorName) "))
						}
					}
					tutorNum += 1
				}
			}
		}
		
		// Validate that the Tutor session count, Student session count, Billed Tutor session count and the Billed Student session count all match
		if tutorSessions != studentSessions || studentSessions != billedStudentSessionCount || billedStudentSessionCount != billedTutorSessionCount {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Tutor session count \(tutorSessions), Student session count \(studentSessions), Billed Tutor session count \(billedTutorSessionCount) and Billed Student Session count \(billedStudentSessionCount) do not match"))
		}
		
		if tutorStudentCount != assignedStudentCount {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Validation Error: Tutor Student count \(tutorStudentCount) does not match assigned Student count \(assignedStudentCount) -- could be due to re-assignment"))
		}
		
		// Validate master reference spreadsheet file key matches the import file keys in each timesheet and timesheet template
		
		// Validate that the total number of Tutors in the previous month Billed Tutor List is equal to the number of active Tutors
		
		if billedTutorMonth.tutorBillingRows.count != totalTutors {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Total Tutor count \(totalTutors) does not match number of Tutors in \(billedMonthName) Billed Tutor list \(billedTutorMonth.tutorBillingRows.count)"))
		}
		
		// Validate that the total number of Students in the previous month Billed Student List is equal to the number of active Students\
		
		if billedStudentMonth.studentBillingRows.count != totalStudents {
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:"Validation Error: Total Student count \(totalStudents) does not match number of Students in \(billedMonthName) Billed Student list \(billedStudentMonth.studentBillingRows.count)"))
			// If more Students in Billed Student list, find missing Student
			if totalStudents < billedStudentMonth.studentBillingRows.count {
				var studentNum = 0
				var studentCount = billedStudentMonth.studentBillingRows.count
				while studentNum < studentCount {
					let studentName = billedStudentMonth.studentBillingRows[studentNum].studentName
					let (studentFoundFlag, billedStudentNum) = referenceData.students.findStudentByName(studentName: studentName)
					if !studentFoundFlag {
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Student \(studentName) is in Billed Student list but not Reference Data Students"))
					}
					studentNum += 1
				}
			}
		}
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "** Validation Complete **\n"))
		
	}
	//
	// This function validates the Tutor and Student Billing data for a single month by reading through all the Timesheets for that month and checking the timesheet data against the Tutor and Student Billing data.
	// Step 1 - read in all the Tutor Timesheets for the month being validated
	// Step 2 - read in the Student Billing data for the month being validated
	// Step 3 - read in the Tutor Billing data for the month being validated
	// Step 4 - read in the validated Student Billing Data for the previous month
	// Step 5 - read in the validated Tutor Billing data for the previous month
	// Step 6 - calculate the Tutor Billing and Student Billing data for the current month from the Timesheets
	// Step 7 - assess the month's Student Billing data against the calculated student billing data
	// Step 8 - assess the month's Tutor Billing data against the calculated tutor billing data
	// Step 9 - assess the total Student Billing data against the calculated value for the current month plus the validated total for the previous month
	// Step 10 - assess the total Tutor Billing data against the calculated value for the current month plus the validated total for the previous month
	// Step 11 - update the validated month and total student data in the Student Billing data spreadsheet
	// Step 12 - update the validated month and total tutor data in the Tutor Billing data spreadsheet
	// Step 13 - compare the Validated Tutor billing stat data against the Reference data Tutor billing stat date
	// Step 14 - compare the validated Student billing stat data against the Reference data STudent billing stat data
	//
	func ValidateMonthBillingData(referenceData: ReferenceData, monthName: String, yearName: String, validationMessages: WindowMessages) async {
		
		let billingMessages = WindowMessages()
		
		let (prevMonthName, prevMonthYearName) = findPrevMonthYear(currentMonth: monthName, currentYear: yearName)
		
		
		// Step 1 - Read in all of the Timesheets for the month into an array of monthly Timesheet data
		// Each yearBillArray element contains a Bill Array of all of the Timesheets for that month processed by client
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: " Step 1 - Read in all the Tutor Timesheets for \(monthName) \(yearName)"))
		
		let billArray = BillArray(monthName: monthName )	// Used for detailed messages generated when processing Timesheet.  Not displayed for this validate month function.  Basically a bit bucket.
		
		var tutorNum = 0
		let refTutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < refTutorCount {
			
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Processing \(monthName) Timesheet for \(tutorName)"))
				let fileName = "Timesheet " + yearName + " " + tutorName
				do {
					let (result, timesheetFileID) = try await getFileID(fileName: fileName)
					if result {
						let timesheet = Timesheet()
						let timesheetResult = await timesheet.loadTimesheetData(tutorName: tutorName, month: monthName, timesheetID: timesheetFileID, billingMessages: billingMessages, referenceData: referenceData)
						if !timesheetResult {
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: Could not load Timesheet for Tutor \(tutorName)"))
						} else {
							billArray.processTimesheet(timesheet: timesheet, billingMessages: validationMessages)
						}
					}
				} catch {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: could not get timesheet fileID for \(fileName)"))
				}
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "*Not processing Timesheet for deleted Tutor \(tutorName)"))
			}
			tutorNum += 1
		}
		
		
		// Step 2 - Read in all of the Student Billing data for the month into an array of Student Billing data
		//
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Step 2 - Read in the Student Billing Months"))
		
		let currentBilledStudentMonth = await buildBilledStudentMonth(monthName: monthName, yearName: yearName, loadValidatedData: false)
		
		
		// Step 3 - Read in all of the Tutor Billing data for the month into an array of Tutor Billing data
		//
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Step 3 - Read in the Tutor Billing Months"))
		
		let currentBilledTutorMonth =  await buildBilledTutorMonth(monthName: monthName, yearName: yearName, loadValidatedData: false)
		
		
		// Step 4 - Read in the Validated Student Billing data for the month previous to the one being processed
		//
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Step 4 - read in previous month validated student billing data"))
		let prevBilledStudentMonth = await buildBilledStudentMonth(monthName: prevMonthName, yearName: prevMonthYearName, loadValidatedData: true)
		
		// Step 5 - Read in the Validated Tutor Billing data for the month previous to the one being processed
		//
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Step 5 - read in previous month validated tutor billing data"))
		let prevBilledTutorMonth = await buildBilledTutorMonth(monthName: prevMonthName, yearName: prevMonthYearName, loadValidatedData: true)
		
		
		// Loop through each session for each client for each month in the array of Timesheets
		
		
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "// Step 6 - Processing Month \(monthName)"))
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "//"))
		
		//loop through each Client in the Bill Array
		
		// Create Billed Tutor and Billed Student instances for the month to hold the costs, revenues and session counts extracted
		// directly from the Tutor Timesheets for the month
		
		var clientNum = 0
		let clientCount = billArray.billClients.count
		while clientNum < clientCount {
			
			//Loop through each tutoring session for the client that month
			var itemNum = 0
			let itemCount = billArray.billClients[clientNum].billItems.count
			while itemNum < itemCount {
				// Get the tutoring session data that was on the Timesheet
				let studentName = billArray.billClients[clientNum].billItems[itemNum].studentName
				let timesheetServiceName = billArray.billClients[clientNum].billItems[itemNum].timesheetServiceName
				let serviceDate = billArray.billClients[clientNum].billItems[itemNum].serviceDate
				let duration = billArray.billClients[clientNum].billItems[itemNum].duration
				let tutorName = billArray.billClients[clientNum].billItems[itemNum].tutorName
				// Get the costs and prices for the Service for the Tutor that conducted the tutoring
				let (tutorFindResult, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
				let (serviceFindResult, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByName(serviceName: timesheetServiceName)
				if serviceFindResult {
					let (quantity, rate, cost, price) = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].computeSessionCostPrice(duration: duration)
					// Find the Tutor in the compareBilledTutor instance for the month -- if not found, add the Tutor
					var (billedTutorFound, billedTutorNum) = currentBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
					if !billedTutorFound {
						currentBilledTutorMonth.addNewBilledTutor(tutorName: tutorName)
						(billedTutorFound, billedTutorNum) = currentBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
					}
					// Increment the month cost, price and sessions for the Tutor for the month based on this tutoring session data
					currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthValidatedCost += cost
					currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthValidatedRevenue += price
					currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthValidatedProfit += (price - cost)
					currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthValidatedSessions += 1
					
					// Find the Student in the compareBilledStudent instance for the month -- if not found, add the Student
					var (billedStudentFound, billedStudentNum) = currentBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
					if !billedStudentFound {
						currentBilledStudentMonth.addNewBilledStudent(studentName: studentName)
						(billedStudentFound, billedStudentNum) = currentBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
					}
					// Increment the month cost, price and sessions for the Student based on this tutoring session data
					currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthValidatedCost += cost
					currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthValidatedRevenue += price
					currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthValidatedProfit += (price - cost)
					currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthValidatedSessions += 1
				} else {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "Error: could not find Service \(timesheetServiceName) for Tutor \(tutorName)"))
				}
				
				itemNum += 1
			}
			
			clientNum += 1
		}
		
		// Calculate the Tutor total Sessions, Cost, Revenue and Profit to this month (previous month Validated Total plus current month Validated Totals
		tutorNum = 0
		while tutorNum < refTutorCount {
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			let (currentMonthTutorFound,currentMonthTutorNum) = currentBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
			if currentMonthTutorFound {
				let (prevMonthTutorFound, prevMonthTutorNum) = prevBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
				if prevMonthTutorFound {
					currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedSessions = prevBilledTutorMonth.tutorBillingRows[prevMonthTutorNum].totalValidatedSessions + currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].monthValidatedSessions
					currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedCost = prevBilledTutorMonth.tutorBillingRows[prevMonthTutorNum].totalValidatedCost + currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].monthValidatedCost
					currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedRevenue = prevBilledTutorMonth.tutorBillingRows[prevMonthTutorNum].totalValidatedRevenue + currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].monthValidatedRevenue
					currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedProfit = prevBilledTutorMonth.tutorBillingRows[prevMonthTutorNum].totalValidatedProfit + currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].monthValidatedProfit
				}
			}
			tutorNum += 1
		}
		
		// Calculate the Student total Sessions, Cost, Revenue and Profit to this month (previous month Validated Total plus current month Validated Totals
		var studentNum = 0
		let refStudentCount = referenceData.students.studentsList.count
		
		while studentNum < refStudentCount {
			let studentName = referenceData.students.studentsList[studentNum].studentName
			let (currentMonthStudentFound,currentMonthStudentNum) = currentBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
			if currentMonthStudentFound {
				let (prevMonthStudentFound, prevMonthStudentNum) = prevBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
				if prevMonthStudentFound {
					currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedSessions = prevBilledStudentMonth.studentBillingRows[prevMonthStudentNum].totalValidatedSessions + currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].monthValidatedSessions
					currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedCost = prevBilledStudentMonth.studentBillingRows[prevMonthStudentNum].totalValidatedCost + currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].monthValidatedCost
					currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedRevenue = prevBilledStudentMonth.studentBillingRows[prevMonthStudentNum].totalValidatedRevenue + currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].monthValidatedRevenue
					currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedProfit = prevBilledStudentMonth.studentBillingRows[prevMonthStudentNum].totalValidatedProfit + currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].monthValidatedProfit
				}
			}
			studentNum += 1
		}
		
		
		// Go through each Tutor and compared their monthly Billed Tutor cost, price and session data to what is calculated in the compareBilledTutor data
		var billedTutorNum = 0
		let billedTutorCount = currentBilledTutorMonth.tutorBillingRows.count
		while billedTutorNum < billedTutorCount {
			let tutorName = currentBilledTutorMonth.tutorBillingRows[billedTutorNum].tutorName
			
			let billedTutorMonthCost = currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledCost
			let compareMonthCost = currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthValidatedCost
			let billedTutorMonthRevenue = currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledRevenue
			let compareMonthRevenue = currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthValidatedRevenue
			let billedTutorMonthSessions = currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledSessions
			let compareMonthSessions = currentBilledTutorMonth.tutorBillingRows[billedTutorNum].monthValidatedSessions
			
			if compareMonthCost.rounded() == billedTutorMonthCost.rounded() {
//				validationMessages.addMessage(windowLineText: WindowMessageLine(windowLineText: "          \(currentBilledTutorMonth.monthName): Tutor \(tutorName) Billed Tutor month costs matches computed value: \(billedTutorMonthCost) vs \(compareMonthCost)"))
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "\(currentBilledTutorMonth.monthName): Tutor \(tutorName) Billed Tutor month costs do not match computed value: \(billedTutorMonthCost) vs \(compareMonthCost)\n"))
			}
			if compareMonthRevenue.rounded() == billedTutorMonthRevenue.rounded() {
//				validationMessages.addMessage(windowLineText: WindowMessageLine(windowLineText: "          \(currentBilledTutorMonth.monthName): Tutor \(tutorName) Billed Tutor month revenue matches computed value: \(billedTutorMonthRevenue) vs \(compareMonthRevenue)"))
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "\(currentBilledTutorMonth.monthName): Tutor \(tutorName) Billed Tutor month revenue does not match computed value: \(billedTutorMonthRevenue) vs \(compareMonthRevenue)\n"))
			}
			if compareMonthSessions == billedTutorMonthSessions {
//				validationMessages.addMessage(windowLineText: WindowMessageLine(windowLineText: "          \(currentBilledTutorMonth.monthName): Tutor \(tutorName) Billed Tutor month sessions matches computed value: \(billedTutorMonthSessions) vs \(compareMonthSessions)"))
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "\(currentBilledTutorMonth.monthName): Tutor \(tutorName) Billed Tutor month sessions do not match computed value: \(billedTutorMonthSessions) vs \(compareMonthSessions)\n"))
			}
			
			billedTutorNum += 1
		}
		
		// Go through each Student and compared their monthly Billed Student cost, price and session data to what is calculated in the compareBilledStudent data
		var billedStudentNum = 0
		let billedStudentCount = currentBilledStudentMonth.studentBillingRows.count
		while billedStudentNum < billedStudentCount {
			let studentName = currentBilledStudentMonth.studentBillingRows[billedStudentNum].studentName
			//				let (compareStudentFound, compareStudentNum) = compareBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
			//				if compareStudentFound {
			let billedStudentMonthCost = currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledCost
			let compareMonthCost = currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthValidatedCost
			let billedStudentMonthRevenue = currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledRevenue
			let compareMonthRevenue = currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthValidatedRevenue
			let billedStudentMonthSessions = currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledSessions
			let compareMonthSessions = currentBilledStudentMonth.studentBillingRows[billedStudentNum].monthValidatedSessions
			//					print("Student:\(studentName) Billed Student Cost:\(billedStudentCost) Compare Cost:\(compareCost)")
			if compareMonthCost.rounded() == billedStudentMonthCost.rounded() {
//				validationMessages.addMessage(windowLineText: WindowMessageLine(windowLineText: "          \(currentBilledTutorMonth.monthName): Student \(studentName) Billed Student month costs matched \(billedStudentMonthCost) vs \(compareMonthCost)"))
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "\(currentBilledTutorMonth.monthName): Student \(studentName) Billed Student month costs do not match computed value: \(billedStudentMonthCost) vs \(compareMonthCost)\n"))
			}
			if compareMonthRevenue.rounded() == billedStudentMonthRevenue.rounded() {
//				validationMessages.addMessage(windowLineText: WindowMessageLine(windowLineText: "          \(currentBilledTutorMonth.monthName): Student \(studentName) Billed Student month revenue matches computed value: \(billedStudentMonthRevenue) vs \(compareMonthRevenue)"))
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "\(currentBilledTutorMonth.monthName): Student \(studentName) Billed Student month revenue does not match computed value: \(billedStudentMonthRevenue) vs \(compareMonthRevenue)\n"))
			}
			if compareMonthSessions  == billedStudentMonthSessions {
//				validationMessages.addMessage(windowLineText: WindowMessageLine(windowLineText: "          \(currentBilledTutorMonth.monthName): Student \(studentName) Billed Student month sessions matches computed value: \(billedStudentMonthSessions) vs \(compareMonthSessions)"))
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "\(currentBilledTutorMonth.monthName): Student \(studentName) Billed Student month sessions do not match computed value: \(billedStudentMonthSessions) vs \(compareMonthSessions)\n"))
			}
			
			billedStudentNum += 1
		}
		
		// Save the validated Tutor data for the month to the Billed Tutor spreadsheet for the month
		let saveTutorValidationResult = await saveBilledTutorMonth(tutorBillingMonth: currentBilledTutorMonth, monthName: monthName, yearName: yearName, saveValidatedData: true)
		tutorNum = 0
		
		
		// Save the validated Student data for the month to the Billed Student spreadsheet for the month
		let saveStudentValidationResult =  await saveBilledStudentMonth(studentBillingMonth: currentBilledStudentMonth, monthName: monthName, yearName: yearName, saveValidatedData: true)
		
		// Step 13 - compare the Validated Tutor billing stat data against the Reference data Tutor billing stat date
		
		tutorNum = 0
		while tutorNum < referenceData.tutors.tutorsList.count {
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			let refSessionCount = referenceData.tutors.tutorsList[tutorNum].tutorTotalSessions
			let refTotalCost = round(referenceData.tutors.tutorsList[tutorNum].tutorTotalCost)
			let refTotalRevenue = round(referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue)
			let refTotalProfit = round(referenceData.tutors.tutorsList[tutorNum].tutorTotalProfit)
			
			let (currentMonthTutorFound, currentMonthTutorNum) = currentBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
			if currentMonthTutorFound {
				
				let validatedSessionCount = currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedSessions
				let validatedTotalCost = round(currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedCost)
				let validatedTotalRevenue = round(currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedRevenue)
				let validatedTotalProfit = round(currentBilledTutorMonth.tutorBillingRows[currentMonthTutorNum].totalValidatedProfit)
				
				if refSessionCount != validatedSessionCount {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Tutor \(tutorName) Reference Data Total Sessions \(refSessionCount) does not match Validated Data Stats \(validatedSessionCount)"))
				}
				
				if refTotalCost != validatedTotalCost {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Tutor \(tutorName) Reference Data Total Cost \(refTotalCost) does not match Validated Data Stats \(validatedTotalCost)"))
				}
				
				if refTotalRevenue != validatedTotalRevenue {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Tutor \(tutorName) Reference Data Total Revenue \(refTotalRevenue) does not match Validated Data Stats \(validatedTotalRevenue)"))
				}
				
				if refTotalProfit != validatedTotalProfit {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Tutor \(tutorName) Reference Data Total Profit \(refTotalProfit) does not match Validated Data Stats \(validatedTotalProfit)"))
					
				}
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Tutor \(tutorName) not found in Current Tutor Month comparing against Reference Stats"))
			}
			
			
			tutorNum += 1
		}
		
		// Step 14 - compare the validated Student billing stat data against the Reference data STudent billing stat data
		studentNum = 0
		while studentNum < referenceData.students.studentsList.count {
			let studentName = referenceData.students.studentsList[studentNum].studentName
			let refSessionCount = referenceData.students.studentsList[studentNum].studentSessions
			let refTotalCost = round(referenceData.students.studentsList[studentNum].studentTotalCost)
			let refTotalRevenue = round(referenceData.students.studentsList[studentNum].studentTotalRevenue)
			let refTotalProfit = round(referenceData.students.studentsList[studentNum].studentTotalProfit)
			
			let (currentMonthStudentFound,currentMonthStudentNum) = currentBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
			if currentMonthStudentFound {
				let validatedSessionCount = currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedSessions
				let validatedTotalCost = round(currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedCost)
				let validatedTotalRevenue = round(currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedRevenue)
				let validatedTotalProfit = round(currentBilledStudentMonth.studentBillingRows[currentMonthStudentNum].totalValidatedProfit)
				
				if refSessionCount != validatedSessionCount {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Student \(studentName) Reference Data Total Sessions \(refSessionCount) does not match Validated Data Stats \(validatedSessionCount)"))
				}
				
				if refTotalCost != validatedTotalCost {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Student \(studentName)  Reference Data Total Cost \(refTotalCost) does not match Validated Data Stats \(validatedTotalCost)"))
				}
				
				if refTotalRevenue != validatedTotalRevenue {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Student \(studentName) Reference Data Total Revenue \(refTotalRevenue) does not match Validated Data Stats \(validatedTotalRevenue)"))
				}
				
				if refTotalProfit != validatedTotalProfit {
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Student \(studentName) Reference Data Total Profit \(refTotalProfit) does not match Validated Data Stats \(validatedTotalProfit)"))
				}
			} else {
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: "ERROR: Student \(studentName) not found in Current Student Month comparing against Reference Stats"))
			}
				
			studentNum += 1
		}
		
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: " Month Validation Complete for \(monthName)"))
		
		
	}
	
	// ** This Function is Obsolete **
	// This function validates the Tutor and Student Billing data for the year by reading through all the Timesheets and checking the timesheet data against the Tutor and Student Billing data.
	//
	func ValidateBillingData(referenceData: ReferenceData) async {
		var yearBillArray = [BillArray]()					// The monthly processed Timesheet data
		var yearTutorBilling = [TutorBillingMonth]()				// The monthly Tutor Billing data from the Tutor Billing spreadsheets
		var yearStudentBilling = [StudentBillingMonth]()			// The monthly Student billing data from the Student Billing spreadsheets
		var compareTutorBilling = [TutorBillingMonth]()				// The new monthly computed Tutor Billing data directly from the timesheets
		var compareStudentBilling = [StudentBillingMonth]()			// The new monthly computed Student Billing data directly from the timesheets
		var openingMonthNum: Int = 0
		
		let billingMessages = WindowMessages()
		
		let currentMonthNum = Calendar.current.component(.month, from: Date())                 // Current month may not be billed yet
		
		let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
		//	let currentMonthNum = 13
		if currentMonthYear == "2024" {
			openingMonthNum = 7
			//	openingMonthNum = 11
		} else {
			openingMonthNum = 1
		}
		// Read in all of the Timesheets for the year (for 2024 -- starting September) into an array of monthly Timesheet data indexed by month
		// Each yearBillArray element contains a Bill Array of all of the Timesheets for that month processed by client
		print(" Step 1 - Read in all Tutor Timesheets")
		var monthNum = openingMonthNum
		let monthCount = currentMonthNum
		while monthNum < monthCount {
			let monthName = monthArray[monthNum - 1]
			
			let billArray = BillArray(monthName: monthArray[monthNum] )
			
			var tutorNum = 0
			let tutorCount = referenceData.tutors.tutorsList.count
			while tutorNum < tutorCount {
				
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
					print("Processing \(monthName) Timesheet for \(tutorName)")
					let fileName = "Timesheet " + currentMonthYear + " " + tutorName
					do {
						let (result, timesheetFileID) = try await getFileID(fileName: fileName)
						if result {
							let timesheet = Timesheet()
							let timesheetResult = await timesheet.loadTimesheetData(tutorName: tutorName, month: monthName, timesheetID: timesheetFileID, billingMessages: billingMessages, referenceData: referenceData)
							if !timesheetResult {
								print("Error: Could not load Timesheet for Tutor \(tutorName)")
							} else {
								billArray.processTimesheet(timesheet: timesheet, billingMessages: billingMessages)
							}
						}
					} catch {
						print("Error: could not get timesheet fileID for \(fileName)")
					}
				} else {
					print("*Not processing Timesheet for deleted Tutor \(tutorName)")
				}
				tutorNum += 1
			}
			
			yearBillArray.append(billArray)
			monthNum += 1
		}
		
		// Read in all of the Student Billing data for the year into a monthly array of Student Billing data
		// Each yearStudentBilling element contains a StudentBillingMonth instance containing all of the Tutor Billing data for that month
		print("Step 2 - Read in all Student Billing Months")
		monthNum = openingMonthNum
		while monthNum < monthCount {
			let monthName = monthArray[monthNum - 1]
			yearStudentBilling.append( await buildBilledStudentMonth(monthName: monthName, yearName: currentMonthYear, loadValidatedData: false) )
			monthNum += 1
		}
		
		// Read in all of the Tutor Billing data for the year into a monthly array of Tutor Billing data
		//Each yearTutorBilling element contains a TutorBillingMonth instance containing all of the Tutor Billing data for that month
		print("Step 3 - Read in all Tutor Billing Months")
		monthNum = openingMonthNum
		while monthNum < monthCount {
			let monthName = monthArray[monthNum - 1]
			yearTutorBilling.append( await buildBilledTutorMonth(monthName: monthName, yearName: currentMonthYear, loadValidatedData: false) )
			monthNum += 1
		}
		
		// Loop through each session for each client for each month in the array of Timesheets
		var monthIndex = 0
		let monthTotal = yearBillArray.count
		while monthIndex < monthTotal {
			
			print("// Processing Month \(monthIndex) \(yearTutorBilling[monthIndex].monthName)")
			print("//")
			//loop through each Client in the Bill Array
			
			// Create Billed Tutor and Billed Student instances for the month to hold the costs, revenues and session counts extracted
			// directly from the Tutor Timesheets for the month
			let compareBilledTutorMonth = TutorBillingMonth(monthName: yearBillArray[monthIndex].monthName)
			let compareBilledStudentMonth = StudentBillingMonth(monthName: yearBillArray[monthIndex].monthName)
			
			var clientNum = 0
			let clientCount = yearBillArray[monthIndex].billClients.count
			while clientNum < clientCount {
//				let clientName = yearBillArray[monthIndex].billClients[clientNum].clientName
//				var monthCost = 0
//				var monthRevenue = 0
				//Loop through each tutoring session for the client that month
				var itemNum = 0
				let itemCount = yearBillArray[monthIndex].billClients[clientNum].billItems.count
				while itemNum < itemCount {
					// Get the tutoring session data that was on the Timesheet
					let studentName = yearBillArray[monthIndex].billClients[clientNum].billItems[itemNum].studentName
					let timesheetServiceName = yearBillArray[monthIndex].billClients[clientNum].billItems[itemNum].timesheetServiceName
//					let serviceDate = yearBillArray[monthIndex].billClients[clientNum].billItems[itemNum].serviceDate
					let duration = yearBillArray[monthIndex].billClients[clientNum].billItems[itemNum].duration
					let tutorName = yearBillArray[monthIndex].billClients[clientNum].billItems[itemNum].tutorName
					// Get the costs and prices for the Service for the Tutor that conducted the tutoring
					let (tutorFindResult, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
					let (serviceFindResult, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByName(serviceName: timesheetServiceName)
					if serviceFindResult {
						let (quantity, rate, cost, price) = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].computeSessionCostPrice(duration: duration)
						// Find the Tutor in the compareBilledTutor instance for the month -- if not found, add the Tutor
						var (billedTutorFound, billedTutorNum) = compareBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
						if !billedTutorFound {
							compareBilledTutorMonth.addNewBilledTutor(tutorName: tutorName)
							(billedTutorFound, billedTutorNum) = compareBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
						}
						// Increment the month cost, price and sessions for the Tutor for the month based on this tutoring session data
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledCost += cost
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledRevenue += price
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledSessions += 1
						// Find the Student in the compareBilledStudent instance for the month -- if not found, add the Student
						var (billedStudentFound, billedStudentNum) = compareBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
						if !billedStudentFound {
							compareBilledStudentMonth.addNewBilledStudent(studentName: studentName)
							(billedStudentFound, billedStudentNum) = compareBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
						}
						// Increment the month cost, price and sessions for the Student based on this tutoring session data
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledCost += cost
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledRevenue += price
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledSessions += 1
					} else {
						print("Error: could not find Service \(timesheetServiceName) for Tutor \(tutorName)")
					}
					
					itemNum += 1
				}
				
				clientNum += 1
			}
			
			// For Tutors that did not have a tutoring session this month, copy their previous month's compareTutorBilling cost, price and session data to this month's totals
			var tutorNum = 0
			var tutorCount = referenceData.tutors.tutorsList.count
			while tutorNum < tutorCount {
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				var (compareTutorFound,compareTutorNum) = compareBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
				if !compareTutorFound {
					compareBilledTutorMonth.addNewBilledTutor(tutorName: tutorName)
					(compareTutorFound,compareTutorNum) = compareBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
					if monthIndex > 1 {
						let (prevMonthFound, prevMonthCompareTutorNum) = compareTutorBilling[monthIndex - 1].findBilledTutorByName(billedTutorName: tutorName)
						compareBilledTutorMonth.tutorBillingRows[compareTutorNum].totalBilledCost = compareTutorBilling[monthIndex - 1].tutorBillingRows[prevMonthCompareTutorNum].totalBilledCost
						compareBilledTutorMonth.tutorBillingRows[compareTutorNum].totalBilledRevenue = compareTutorBilling[monthIndex - 1].tutorBillingRows[prevMonthCompareTutorNum].totalBilledRevenue
						compareBilledTutorMonth.tutorBillingRows[compareTutorNum].totalBilledSessions = compareTutorBilling[monthIndex - 1].tutorBillingRows[prevMonthCompareTutorNum].totalBilledSessions
						print("Carrying over previous month's compare Tutor data for \(tutorName)")
					}
				}
				tutorNum += 1
			}
			
			// For Students that did not have a tutoring session this month, copy their previous month's compareStudent Billing cost, price and session data to this month's totals
			var studentNum = 0
			var studentCount = referenceData.students.studentsList.count
			while studentNum < studentCount {
				let studentName = referenceData.students.studentsList[studentNum].studentName
				var (compareStudentFound,compareStudentNum) = compareBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
				if !compareStudentFound {
					compareBilledStudentMonth.addNewBilledStudent(studentName: studentName)
					(compareStudentFound,compareStudentNum) = compareBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
					if monthIndex > 1 {
						let (prevMonthFound, prevMonthCompareStudentNum) = compareStudentBilling[monthIndex - 1].findBilledStudentByStudentName(billedStudentName: studentName)
						compareBilledStudentMonth.studentBillingRows[compareStudentNum].totalBilledCost = compareStudentBilling[monthIndex - 1].studentBillingRows[prevMonthCompareStudentNum].totalBilledCost
						compareBilledStudentMonth.studentBillingRows[compareStudentNum].totalBilledRevenue = compareStudentBilling[monthIndex - 1].studentBillingRows[prevMonthCompareStudentNum].totalBilledRevenue
						compareBilledStudentMonth.studentBillingRows[compareStudentNum].totalBilledSessions = compareStudentBilling[monthIndex - 1].studentBillingRows[prevMonthCompareStudentNum].totalBilledSessions
						print("Carrying over previous month's compare Student data for \(studentName)")
					}
				}
				studentNum += 1
			}
			
			// Go through each Tutor and compared their monthly Billed Tutor cost, price and session data to what is calculated in the compareBilledTutor data
			var billedTutorNum = 0
			tutorCount = yearTutorBilling[monthIndex].tutorBillingRows.count
			while billedTutorNum < tutorCount {
				let tutorName = yearTutorBilling[monthIndex].tutorBillingRows[billedTutorNum].tutorName
				let (compareTutorFound, compareTutorNum) = compareBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
				if compareTutorFound {
					let billedTutorMonthCost = yearTutorBilling[monthIndex].tutorBillingRows[billedTutorNum].monthBilledCost
					let compareMonthCost = compareBilledTutorMonth.tutorBillingRows[compareTutorNum].monthBilledCost
					let billedTutorMonthRevenue = yearTutorBilling[monthIndex].tutorBillingRows[billedTutorNum].monthBilledRevenue
					let compareMonthRevenue = compareBilledTutorMonth.tutorBillingRows[compareTutorNum].monthBilledRevenue
					let billedTutorMonthSessions = yearTutorBilling[monthIndex].tutorBillingRows[billedTutorNum].monthBilledSessions
					let compareMonthSessions = compareBilledTutorMonth.tutorBillingRows[compareTutorNum].monthBilledSessions
					//					print("Tutor:\(tutorName) Billed Student Cost:\(billedTutorCost) Compare Cost:\(compareCost)")
					if compareMonthCost.rounded() == billedTutorMonthCost.rounded() {
						print("          \(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor month costs matches computed value: \(billedTutorMonthCost) vs \(compareMonthCost)")
					} else {
						print("\(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor month costs do not match computed value: \(billedTutorMonthCost) vs \(compareMonthCost)\n")
					}
					if compareMonthRevenue.rounded() == billedTutorMonthRevenue.rounded() {
						print("          \(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor month revenue matches computed value: \(billedTutorMonthRevenue) vs \(compareMonthRevenue)")
					} else {
						print("\(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor month revenue does not match computed value: \(billedTutorMonthRevenue) vs \(compareMonthRevenue)\n")
					}
					if compareMonthSessions == billedTutorMonthSessions {
						print("          \(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor month sessions matches computed value: \(billedTutorMonthSessions) vs \(compareMonthSessions)")
					} else {
						print("\(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor month sessions do not match computed value: \(billedTutorMonthSessions) vs \(compareMonthSessions)\n")
					}
					
				}
				billedTutorNum += 1
			}
			
			// Go through each Student and compared their monthly Billed Student cost, price and session data to what is calculated in the compareBilledStudent data
			var billedStudentNum = 0
			studentCount = yearStudentBilling[monthIndex].studentBillingRows.count
			while billedStudentNum < studentCount {
				let studentName = yearStudentBilling[monthIndex].studentBillingRows[billedStudentNum].studentName
				let (compareStudentFound, compareStudentNum) = compareBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
				if compareStudentFound {
					let billedStudentMonthCost = yearStudentBilling[monthIndex].studentBillingRows[billedStudentNum].monthBilledCost
					let compareMonthCost = compareBilledStudentMonth.studentBillingRows[compareStudentNum].monthBilledCost
					let billedStudentMonthRevenue = yearStudentBilling[monthIndex].studentBillingRows[billedStudentNum].monthBilledRevenue
					let compareMonthRevenue = compareBilledStudentMonth.studentBillingRows[compareStudentNum].monthBilledRevenue
					let billedStudentMonthSessions = yearStudentBilling[monthIndex].studentBillingRows[billedStudentNum].monthBilledSessions
					let compareMonthSessions = compareBilledStudentMonth.studentBillingRows[compareStudentNum].monthBilledSessions
					//					print("Student:\(studentName) Billed Student Cost:\(billedStudentCost) Compare Cost:\(compareCost)")
					if compareMonthCost.rounded() == billedStudentMonthCost.rounded() {
						print("          \(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student month costs matched \(billedStudentMonthCost) vs \(compareMonthCost)")
					} else {
						print("\(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student month costs do not match computed value: \(billedStudentMonthCost) vs \(compareMonthCost)\n")
					}
					if compareMonthRevenue.rounded() == billedStudentMonthRevenue.rounded() {
						print("          \(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student month revenue matches computed value: \(billedStudentMonthRevenue) vs \(compareMonthRevenue)")
					} else {
						print("\(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student month revenue does not match computed value: \(billedStudentMonthRevenue) vs \(compareMonthRevenue)\n")
					}
					if compareMonthSessions  == billedStudentMonthSessions {
						print("          \(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student month sessions matches computed value: \(billedStudentMonthSessions) vs \(compareMonthSessions)")
					} else {
						print("\(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student month sessions do not match computed value: \(billedStudentMonthSessions) vs \(compareMonthSessions)\n")
					}
					
				}
				billedStudentNum += 1
			}
			
			billedTutorNum = 0
			let billedTutorCount = compareBilledTutorMonth.tutorBillingRows.count
			while billedTutorNum < billedTutorCount {
				let tutorName = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].tutorName
				if monthIndex == 0 {
					compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledCost
					compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledRevenue
					compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledSessions = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledSessions
				} else {
					let (prevMonthTutorFound, prevMonthTutorNum) = compareTutorBilling[monthIndex - 1].findBilledTutorByName(billedTutorName: tutorName)
					if prevMonthTutorFound {
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledCost + compareTutorBilling[monthIndex - 1].tutorBillingRows[prevMonthTutorNum].totalBilledCost
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledRevenue + compareTutorBilling[monthIndex - 1].tutorBillingRows[prevMonthTutorNum].totalBilledRevenue
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledSessions = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledSessions + compareTutorBilling[monthIndex - 1].tutorBillingRows[prevMonthTutorNum].totalBilledSessions
					} else {
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledCost
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledRevenue
						compareBilledTutorMonth.tutorBillingRows[billedTutorNum].totalBilledSessions = compareBilledTutorMonth.tutorBillingRows[billedTutorNum].monthBilledSessions
						print("Warning: could not find tutor \(tutorName) in previous month compareBilledTutorMonth \(yearTutorBilling[monthIndex - 1].monthName)")
					}
				}
				
				let (compareTutorFound, compareTutorNum) = compareBilledTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
				if compareTutorFound {
					let (monthBilledTutorFound, monthBilledTutorNum) = yearTutorBilling[monthIndex].findBilledTutorByName(billedTutorName: tutorName)
					if monthBilledTutorFound {
						let billedTutorTotalCost = yearTutorBilling[monthIndex].tutorBillingRows[monthBilledTutorNum].totalBilledCost
						let compareTotalCost = compareBilledTutorMonth.tutorBillingRows[compareTutorNum].totalBilledCost
						let billedTutorTotalRevenue = yearTutorBilling[monthIndex].tutorBillingRows[monthBilledTutorNum].totalBilledRevenue
						let compareTotalRevenue = compareBilledTutorMonth.tutorBillingRows[compareTutorNum].totalBilledRevenue
						let billedTutorTotalSessions = yearTutorBilling[monthIndex].tutorBillingRows[monthBilledTutorNum].totalBilledSessions
						let compareTotalSessions = compareBilledTutorMonth.tutorBillingRows[compareTutorNum].totalBilledSessions
						//					print("Tutor:\(tutorName) Billed Student Cost:\(billedTutorCost) Compare Cost:\(compareCost)")
						if compareTotalCost.rounded() == billedTutorTotalCost.rounded() {
							print("          \(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor total costs matches computed value: \(billedTutorTotalCost) vs \(compareTotalCost)")
						} else {
							print("\(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor total costs do not match computed value: \(billedTutorTotalCost) vs \(compareTotalCost)\n")
						}
						if compareTotalRevenue.rounded() == billedTutorTotalRevenue.rounded() {
							print("          \(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor total revenue matched computed value: \(billedTutorTotalRevenue) vs \(compareTotalRevenue)")
						} else {
							print("\(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor total revenue does not match computed value: \(billedTutorTotalRevenue) vs \(compareTotalRevenue)\n")
						}
						if compareTotalSessions == billedTutorTotalSessions {
							print("          \(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor total sessions matches computed value: \(billedTutorTotalSessions) vs \(compareTotalSessions)")
						} else {
							print("\(yearTutorBilling[monthIndex].monthName): Tutor \(tutorName) Billed Tutor total sessions do not match computed value: \(billedTutorTotalSessions) vs \(compareTotalSessions)\n")
						}
					} else {
						print("Error: Could not find \(tutorName) in yearTutorBilling \(yearTutorBilling[monthIndex].monthName)")
					}
				} else {
					print("Error: Could not find \(tutorName) in compareBilledTutorMonth \(yearTutorBilling[monthIndex].monthName)")
				}
				
				
				billedTutorNum += 1
			}
			compareTutorBilling.append(compareBilledTutorMonth)
			compareStudentBilling.append(compareBilledStudentMonth)
			
			billedStudentNum = 0
			let billedStudentCount = compareBilledStudentMonth.studentBillingRows.count
			while billedStudentNum < billedStudentCount {
				let studentName = compareBilledStudentMonth.studentBillingRows[billedStudentNum].studentName
				if monthIndex == 0 {
					compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledCost
					compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledRevenue
					compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledSessions = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledSessions
				} else {
					let (prevMonthBilledStudentFound, prevMonthStudentNum) = compareStudentBilling[monthIndex - 1].findBilledStudentByStudentName(billedStudentName: studentName)
					if prevMonthBilledStudentFound {
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledCost + compareStudentBilling[monthIndex - 1].studentBillingRows[prevMonthStudentNum].totalBilledCost
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledRevenue + compareStudentBilling[monthIndex - 1].studentBillingRows[prevMonthStudentNum].totalBilledRevenue
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledSessions = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledSessions + compareStudentBilling[monthIndex - 1].studentBillingRows[prevMonthStudentNum].totalBilledSessions
					} else {
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledCost
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledRevenue
						compareBilledStudentMonth.studentBillingRows[billedStudentNum].totalBilledSessions = compareBilledStudentMonth.studentBillingRows[billedStudentNum].monthBilledSessions
						print("Warning: could not find Billed Student \(studentName) in comparBilledStudentMonth \(yearTutorBilling[monthIndex - 1].monthName)")
					}
				}
				
				let (compareStudentFound, compareStudentNum) = compareBilledStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
				if compareStudentFound {
					let (monthBilledStudentFound, monthBilledStudentNum) = yearStudentBilling[monthIndex].findBilledStudentByStudentName(billedStudentName: studentName)
					if monthBilledStudentFound {
						let billedStudentTotalCost = yearStudentBilling[monthIndex].studentBillingRows[monthBilledStudentNum].totalBilledCost
						let compareTotalCost = compareBilledStudentMonth.studentBillingRows[compareStudentNum].totalBilledCost
						let billedStudentTotalRevenue = yearStudentBilling[monthIndex].studentBillingRows[monthBilledStudentNum].totalBilledRevenue
						let compareTotalRevenue = compareBilledStudentMonth.studentBillingRows[compareStudentNum].totalBilledRevenue
						let billedStudentTotalSessions = yearStudentBilling[monthIndex].studentBillingRows[monthBilledStudentNum].totalBilledSessions
						let compareTotalSessions = compareBilledStudentMonth.studentBillingRows[compareStudentNum].totalBilledSessions
						//					print("Student:\(studentName) Billed Student Cost:\(billedStudentCost) Compare Cost:\(compareCost)")
						if compareTotalCost.rounded() == billedStudentTotalCost.rounded() {
							print("          \(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student total costs matches computed value: \(billedStudentTotalCost) vs \(compareTotalCost)")
						} else {
							print("\(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student total costs do not match computed value: \(billedStudentTotalCost) vs \(compareTotalCost)\n")
						}
						if compareTotalRevenue.rounded() == billedStudentTotalRevenue.rounded() {
							print("          \(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student total revenue matches computed value: \(billedStudentTotalRevenue) vs \(compareTotalRevenue)")
						} else {
							print("\(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student total revenue does not match computed value: \(billedStudentTotalRevenue) vs \(compareTotalRevenue)\n")
						}
						if compareTotalSessions  == billedStudentTotalSessions {
							print("          \(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student total sessions matches computed value: \(billedStudentTotalSessions) vs \(compareTotalSessions)")
						} else {
							print("\(yearTutorBilling[monthIndex].monthName): Student \(studentName) Billed Student total sessions do not match computed value: \(billedStudentTotalSessions) vs \(compareTotalSessions)\n")
						}
					} else {
						print("Error: Could not find Student \(studentName) in yearStudentBilling \(yearTutorBilling[monthIndex].monthName)")
					}
				} else {
					print("Error: Could not find Student \(studentName) in compareBilledStudentMonth \(yearTutorBilling[monthIndex].monthName)")
				}
				
				billedStudentNum += 1
			}
			
			monthIndex += 1
		}
		
		// Sum up total Costs, Revenue and Sessions for Tutors and Students from Bill Students, Billed Tutors, Compare Students and Compare Tutors
		
		monthIndex -= 1				// Set to last processed month
		var totalBilledTutorCosts: Float = 0.0
		var totalBilledTutorRevenue: Float = 0.0
		var totalBilledTutorSessions: Int = 0
		var totalCompareTutorCosts: Float = 0.0
		var totalCompareTutorRevenue: Float = 0.0
		var totalCompareTutorSessions: Int = 0
		var totalBilledStudentCosts: Float = 0.0
		var totalBilledStudentRevenue: Float = 0.0
		var totalBilledStudentSessions: Int = 0
		var totalCompareStudentCosts: Float = 0.0
		var totalCompareStudentRevenue: Float = 0.0
		var totalCompareStudentSessions: Int = 0
		
		var tutorNum: Int = 0
		var tutorCount = yearTutorBilling[monthIndex].tutorBillingRows.count
		while tutorNum < tutorCount {
			totalBilledTutorCosts += yearTutorBilling[monthIndex].tutorBillingRows[tutorNum].totalBilledCost
			totalBilledTutorRevenue += yearTutorBilling[monthIndex].tutorBillingRows[tutorNum].totalBilledRevenue
			totalBilledTutorSessions += yearTutorBilling[monthIndex].tutorBillingRows[tutorNum].totalBilledSessions
			tutorNum += 1
		}
		
		var studentNum: Int = 0
		var studentCount = yearStudentBilling[monthIndex].studentBillingRows.count
		while studentNum < studentCount {
			totalBilledStudentCosts += yearStudentBilling[monthIndex].studentBillingRows[studentNum].totalBilledCost
			totalBilledStudentRevenue += yearStudentBilling[monthIndex].studentBillingRows[studentNum].totalBilledRevenue
			totalBilledStudentSessions += yearStudentBilling[monthIndex].studentBillingRows[studentNum].totalBilledSessions
			studentNum += 1
		}
		
		tutorNum = 0
		tutorCount = compareTutorBilling[monthIndex].tutorBillingRows.count
		while tutorNum < tutorCount {
			totalCompareTutorCosts += compareTutorBilling[monthIndex].tutorBillingRows[tutorNum].totalBilledCost
			totalCompareTutorRevenue += compareTutorBilling[monthIndex].tutorBillingRows[tutorNum].totalBilledRevenue
			totalCompareTutorSessions += compareTutorBilling[monthIndex].tutorBillingRows[tutorNum].totalBilledSessions
			tutorNum += 1
		}
		
		studentNum = 0
		studentCount = compareStudentBilling[monthIndex].studentBillingRows.count
		while studentNum < studentCount {
			totalCompareStudentCosts += compareStudentBilling[monthIndex].studentBillingRows[studentNum].totalBilledCost
			totalCompareStudentRevenue += compareStudentBilling[monthIndex].studentBillingRows[studentNum].totalBilledRevenue
			totalCompareStudentSessions += compareStudentBilling[monthIndex].studentBillingRows[studentNum].totalBilledSessions
			studentNum += 1
		}
		
		var totalReferenceTutorCosts:Float = 0.0
		var totalReferenceTutorRevenue:Float = 0.0
		var totalReferenceTutorSessions:Int = 0
		tutorNum = 0
		tutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < tutorCount {
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			let refDataCost = referenceData.tutors.tutorsList[tutorNum].tutorTotalCost
			let refDataRevenue = referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue
			let refDataSessions = referenceData.tutors.tutorsList[tutorNum].tutorTotalSessions
			print("Tutor: \(tutorName) ReferenceData  \(refDataCost) \(refDataRevenue) \(refDataSessions)")
			
			let (billedTutorFound, billingTutorNum) = yearTutorBilling[monthIndex].findBilledTutorByName(billedTutorName: tutorName)
			if billedTutorFound {
				let billedCost = yearTutorBilling[monthIndex].tutorBillingRows[billingTutorNum].totalBilledCost
				let billedRevenue = yearTutorBilling[monthIndex].tutorBillingRows[billingTutorNum].totalBilledRevenue
				let billedSessions = yearTutorBilling[monthIndex].tutorBillingRows[billingTutorNum].totalBilledSessions
				print("Tutor: \(tutorName) Billed Tutor   \(billedCost) \(billedRevenue) \(billedSessions) \(yearTutorBilling[monthIndex].monthName)")
			} else {
				print("Tutor: \(tutorName) not found in Billed Tutor list \(yearTutorBilling[monthIndex].monthName)")
			}
			
			let (compareTutorFound, compareTutorNum) = compareTutorBilling[monthIndex].findBilledTutorByName(billedTutorName: tutorName)
			if compareTutorFound {
				let compareCost = compareTutorBilling[monthIndex].tutorBillingRows[compareTutorNum].totalBilledCost
				let compareRevenue = compareTutorBilling[monthIndex].tutorBillingRows[compareTutorNum].totalBilledRevenue
				let compareSessions = compareTutorBilling[monthIndex].tutorBillingRows[compareTutorNum].totalBilledSessions
				print("Tutor: \(tutorName) Compare Tutor  \(compareCost) \(compareRevenue) \(compareSessions) \(compareTutorBilling[monthIndex].monthName)\n")
			} else {
				print("Tutor: \(tutorName) not found in Compare Tutor list for \(compareTutorBilling[monthIndex].monthName)\n")
			}
			
			totalReferenceTutorCosts += referenceData.tutors.tutorsList[tutorNum].tutorTotalCost
			totalReferenceTutorRevenue += referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue
			totalReferenceTutorSessions += referenceData.tutors.tutorsList[tutorNum].tutorTotalSessions
			tutorNum += 1
		}
		
		var totalReferenceStudentCosts:Float = 0.0
		var totalReferenceStudentRevenue:Float = 0.0
		var totalReferenceStudentSessions:Int = 0
		studentNum = 0
		studentCount = referenceData.students.studentsList.count
		while studentNum < studentCount {
			let studentName = referenceData.students.studentsList[studentNum].studentName
			let refDataCost = referenceData.students.studentsList[studentNum].studentTotalCost
			let refDataRevenue = referenceData.students.studentsList[studentNum].studentTotalRevenue
			let refDataSessions = referenceData.students.studentsList[studentNum].studentSessions
			print("Student: \(studentName) ReferenceData   \(refDataCost) \(refDataRevenue) \(refDataSessions) \(yearTutorBilling[monthIndex].monthName)")
			
			let (billedStudentFound, billingStudentNum) = yearStudentBilling[monthIndex].findBilledStudentByStudentName(billedStudentName: studentName)
			if billedStudentFound {
				let billedCost = yearStudentBilling[monthIndex].studentBillingRows[billingStudentNum].totalBilledCost
				let billedRevenue = yearStudentBilling[monthIndex].studentBillingRows[billingStudentNum].totalBilledRevenue
				let billedSessions = yearStudentBilling[monthIndex].studentBillingRows[billingStudentNum].totalBilledSessions
				print("Student: \(studentName) Billed Student  \(billedCost) \(billedRevenue) \(billedSessions) \(yearTutorBilling[monthIndex].monthName)")
			} else {
				print("Student: \(studentName) not found Billed Student list \(yearTutorBilling[monthIndex].monthName) \(yearTutorBilling[monthIndex].monthName)")
			}
			let (compareStudentFound, compareStudentNum) = compareStudentBilling[monthIndex].findBilledStudentByStudentName(billedStudentName: studentName)
			if compareStudentFound {
				let compareCost = compareStudentBilling[monthIndex].studentBillingRows[compareStudentNum].totalBilledCost
				let compareRevenue = compareStudentBilling[monthIndex].studentBillingRows[compareStudentNum].totalBilledRevenue
				let compareSessions = compareStudentBilling[monthIndex].studentBillingRows[compareStudentNum].totalBilledSessions
				print("Student: \(studentName) Compare Student \(compareCost) \(compareRevenue) \(compareSessions) \(compareTutorBilling[monthIndex].monthName)\n")
			} else {
				print("Student: \(studentName) not found in Compare Student list \(compareTutorBilling[monthIndex].monthName)\n")
			}
			totalReferenceStudentCosts += referenceData.students.studentsList[studentNum].studentTotalCost
			totalReferenceStudentRevenue += referenceData.students.studentsList[studentNum].studentTotalRevenue
			totalReferenceStudentSessions += referenceData.students.studentsList[studentNum].studentSessions
			studentNum += 1
		}
		
		print("Tutor Reference Data Totals \(totalReferenceTutorCosts) \(totalReferenceTutorRevenue) \(totalReferenceTutorSessions)")
		print("Tutor Billing Totals \(totalBilledTutorCosts) \(totalBilledTutorRevenue) \(totalBilledTutorSessions)")
		print("Compare Tutor Totals \(totalCompareTutorCosts) \(totalCompareTutorRevenue) \(totalCompareTutorSessions)\n")
		print("Student Reference Data Totals \(totalReferenceStudentCosts) \(totalReferenceStudentRevenue) \(totalReferenceStudentSessions)")
		print("Student Billing Totals \(totalBilledStudentCosts) \(totalBilledStudentRevenue) \(totalBilledStudentSessions)")
		print("Compare Student Totals \(totalCompareStudentCosts) \(totalCompareStudentRevenue) \(totalCompareStudentSessions)")
	}
	//
	// This function creates backup copies of the key Google Drive spreadsheets for the system.  Copied files are suffixed with current date and time.  If the system is running
	// against the production files, they are backed up. If its running against the test files, those are backed up.
	//	1) The ReferenceData spreadsheet
	//	2) The TutorDetails spreadsheet
	//	3) The Billed Tutor spreadsheet for the current year
	//	4) The Billed Student spreadsheet for the current year
	//
	func backupSystem() async -> Bool {
		var completionFlag: Bool = true
		var copyBilledTutorResult: [String: Any]?
		var copyBilledStudentResult: [String: Any]?
		
		var tutorBillingFileName: String = ""
		var studentBillingFileName: String = ""
		var copyFileName: String = ""
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
		let backupDate = dateFormatter.string(from: Date())
		dateFormatter.dateFormat = "yyyy"
		let currentYear = dateFormatter.string(from: Date())
		
		print(" ")
		print("** Backing up system ** ")
		
		do {
			// Copy the Reference Data spreadsheet
			if runMode == "PROD" {
				copyFileName = PgmConstants.referenceDataProdFileName + " Backup " + backupDate
			} else {
				copyFileName = PgmConstants.referenceDataTestFileName + " Backup " + backupDate
			}
			let copyRefDataResult = try await copyGoogleDriveFile(sourceFileId: referenceDataFileID, newFileName: copyFileName)
			print("Reference Data spreadsheet copied to file: \(copyFileName)")
			
			
			// Copy the Tutor Details spreadsheet
			if runMode == "PROD" {
				copyFileName = PgmConstants.tutorDetailsProdFileName + " Backup " + backupDate
			} else {
				copyFileName = PgmConstants.tutorDetailsTestFileName + " Backup " + backupDate
			}
			let copyDetailsDataResult = try await copyGoogleDriveFile(sourceFileId: tutorDetailsFileID, newFileName: copyFileName)
			print("Tutor Details spreadsheet copied to file: \(copyFileName)")
			
			// Copy the Tutor Billing spreadsheet
			tutorBillingFileName = tutorBillingFileNamePrefix + currentYear
			let (tutorFileFound, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			if tutorFileFound {
				copyBilledTutorResult = try await copyGoogleDriveFile(sourceFileId: tutorBillingFileID, newFileName: tutorBillingFileName + " Backup " + backupDate)
				print("Billed Tutor spreadsheet copied to file: \(tutorBillingFileName + " Backup " + backupDate)")
			} else {
				completionFlag = false
			}
			
			// Copy the Student Billing spreadsheet
			studentBillingFileName = studentBillingFileNamePrefix + currentYear
			let (studentFileFound, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
			if studentFileFound {
				copyBilledStudentResult = try await copyGoogleDriveFile(sourceFileId: studentBillingFileID, newFileName: studentBillingFileName + " Backup " + backupDate)
				print("Billed Student spreadsheet copied to file: \(studentBillingFileName + " Backup " + backupDate)")
			} else {
				completionFlag = false
			}
			
			if copyRefDataResult == nil || copyDetailsDataResult == nil || copyBilledTutorResult == nil || copyBilledStudentResult == nil {
				completionFlag = false
			}
		} catch {
			print("ERROR: Could not backup application files")
			completionFlag = false
		}
		
		print("** Backup Complete **")
		print(" ")
		
		return(completionFlag)
	}
	
	
	// This function generates the next year's spreadsheets (Tutor Billing, Student Billing) and a new Timesheet for each Tutor
	//
	func generateNewYearFiles(referenceData: ReferenceData) async -> (Bool, String) {
		var generateResult: Bool = true
		var generateMessage: String = ""
		
		var nextYear: String = ""
		var newTimesheetFileID: String = ""
		
		
		if let yearInt = Calendar.current.dateComponents([.year], from: Date()).year {
			//			nextYear = String(yearInt + 1)
			nextYear = "2025"
			
			// Create the next year's Production Tutor Billing spreadsheet
			
			let newTutorBillingProdFileName = PgmConstants.tutorBillingProdFileNamePrefix + nextYear
			let newTutorBillingTestFileName = PgmConstants.tutorBillingTestFileNamePrefix + nextYear
			let tutorBillingTemplateFileName = PgmConstants.billedTutorTemplateFileName
			
			do {
				let (fileFound, fileID) = try await getFileID(fileName: newTutorBillingProdFileName)
				if !fileFound {
					let (fileFound, tutorBillingTemplateFileID) = try await getFileID(fileName: tutorBillingTemplateFileName)
					if fileFound {
						do {
							if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: tutorBillingTemplateFileID, newFileName: newTutorBillingProdFileName) {
								
								if let fileID = copiedFileData["id"] as? String {
									newTimesheetFileID = fileID
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.russellEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.writeSeattleEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.stephenEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.serviceAccountEmail)
									print("Created Tutor Billing Prod file: \(newTutorBillingProdFileName)")
								} else {
									print("No valid string found for the key 'name'")
								}
							}
						} catch {
							generateResult = false
							generateMessage += "Error: Could create Tutor Billing Prod file: \(newTutorBillingProdFileName)\n"
						}
					} else {
						generateResult = false
						generateMessage += "Error: Could not get File ID for Tutor Template File: \(tutorBillingTemplateFileName)\n"
					}
				} else {
					generateResult = false
					generateMessage += "Error: \(newTutorBillingProdFileName) already exists\n"
				}
			} catch {
				generateResult = false
				generateMessage += "Error: could not create \(newTutorBillingProdFileName)\n"
			}
			
			// Create the next year's Test Tutor Billing spreadsheet
			do {
				let (fileFound, fileID) = try await getFileID(fileName: newTutorBillingTestFileName)
				if !fileFound {
					let (fileFound, tutorBillingTemplateFileID) = try await getFileID(fileName: tutorBillingTemplateFileName)
					if fileFound {
						do {
							if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: tutorBillingTemplateFileID, newFileName: newTutorBillingTestFileName) {
								
								if let fileID = copiedFileData["id"] as? String {
									newTimesheetFileID = fileID
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.russellEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.writeSeattleEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.stephenEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.serviceAccountEmail)
									print( "Created Tutor Billing Test file: \(newTutorBillingTestFileName)")
								} else {
									print("No valid string found for the key 'name'")
								}
							}
						} catch {
							generateResult = false
							generateMessage += "Error: Could create Tutor Billing Test file: \(newTutorBillingTestFileName)\n"
						}
					} else {
						generateResult = false
						generateMessage += "Error: Could not get File ID for Tutor Template File: \(tutorBillingTemplateFileName)\n"
					}
				} else {
					generateResult = false
					generateMessage += "Error: \(newTutorBillingTestFileName) already exists\n"
				}
				
			} catch {
				generateResult = false
				generateMessage += "Error: could not create \(newTutorBillingTestFileName) \n"
			}
			
			// Create the next year's Production Student Billing spreadsheets
			
			let newStudentBillingProdFileName = PgmConstants.studentBillingProdFileNamePrefix + nextYear
			let newStudentBillingTestFileName = PgmConstants.studentBillingTestFileNamePrefix + nextYear
			let studentBillingTemplateFileName = PgmConstants.billedStudentTemplateFileName
			
			do {
				let (fileFound, fileID) = try await getFileID(fileName: newStudentBillingProdFileName)
				if !fileFound {
					let (fileFound, studentBillingTemplateFileID) = try await getFileID(fileName: studentBillingTemplateFileName)
					if fileFound {
						do {
							if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: studentBillingTemplateFileID, newFileName: newStudentBillingProdFileName) {
								
								if let fileID = copiedFileData["id"] as? String {
									newTimesheetFileID = fileID
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.russellEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.writeSeattleEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.stephenEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.serviceAccountEmail)
									print("Created Billed Student Prod file: \(newStudentBillingProdFileName)\n")
								} else {
									print("No valid string found for the key 'name'")
								}
							}
						} catch {
							generateResult = false
							generateMessage += "Error:  Could not create Billed Student Prod file: \(newStudentBillingProdFileName)\n"
						}
					} else {
						generateResult = false
						generateMessage += "Error: Could not get File ID for Student Template File: \(studentBillingTemplateFileName)\n"
					}
				} else {
					generateResult = false
					generateMessage += "Error: \(newStudentBillingProdFileName) already exists \n"
				}
			} catch {
				generateResult = false
				generateMessage += "Error: could not create \(newStudentBillingProdFileName)\n"
			}
			
			// Create the next year's Test Student Billing spreadsheets
			do {
				let (fileFound, fileID) = try await getFileID(fileName: newStudentBillingTestFileName)
				if !fileFound {
					let (fileFound, studentBillingTemplateFileID) = try await getFileID(fileName: studentBillingTemplateFileName)
					if fileFound {
						do {
							if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: studentBillingTemplateFileID, newFileName: newStudentBillingTestFileName) {
								
								if let fileID = copiedFileData["id"] as? String {
									newTimesheetFileID = fileID
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.russellEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.writeSeattleEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.stephenEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.serviceAccountEmail)
									print("Created Billed Student Test file: \(newStudentBillingTestFileName)\n")
								} else {
									print("No valid string found for the key 'name'")
								}
							}
						} catch {
							generateResult = false
							generateMessage += "ERROR:  Could not create Billed Student Test file: \(newStudentBillingTestFileName)\n"
						}
					} else {
						generateResult = false
						generateMessage += "ERROR: Could not get File ID for Student Template File: \(studentBillingTemplateFileName)\n"
					}
					
				} else {
					generateResult = false
					generateMessage += "ERROR: \(newStudentBillingTestFileName) already exists\n"
				}
			} catch {
				generateResult = false
				generateMessage += "ERROR: could not create \(newStudentBillingTestFileName)\n"
			}
			//  Create a Timesheet for each Tutor for the year
			var tutorNum = 0
			let tutorCount = referenceData.tutors.tutorsList.count
			while tutorNum < tutorCount {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
					let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
					let tutorEmail = referenceData.tutors.tutorsList[tutorNum].tutorEmail
					let newTutorTimesheetName = "Timesheet " + nextYear + " " + tutorName
					do {
						let (fileFound, fileID) = try await getFileID(fileName: newTutorTimesheetName)
						if !fileFound {
							if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: timesheetTemplateFileID, newFileName: newTutorTimesheetName) {
								
								if let fileID = copiedFileData["id"] as? String {
									newTimesheetFileID = fileID
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: tutorEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.russellEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.writeSeattleEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.stephenEmail)
									try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.serviceAccountEmail)
									print("Created Timesheet: \(newTutorTimesheetName)")
									// Write the Tutor name into the RefData tab of the new Tutor Timesheet
									let range = PgmConstants.timesheetTutorNameCell
									do {
										try await writeSheetCells(fileID: newTimesheetFileID, range:range, values: [[tutorName]])
									} catch {
										print("ERROR: can not write Tutor Name into new Tutor Timesheet")
									}
								} else {
									print("No valid string found for the key 'name'")
								}
							}
						} else {
							generateResult = false
							generateMessage += "ERROR: Timesheet: \(newTutorTimesheetName) already exists\n"
						}
						
					} catch {
						generateResult = false
						generateMessage += "ERROR:  Could not create Timesheet for Tutor: \(tutorName)"
						print("ERROR:  Could not create Timesheet for Tutor: \(tutorName)")
					}
				}
				tutorNum += 1
			}
		}
		return(generateResult, generateMessage)
	}
	
	func updateTimesheetFileIDs(referenceData: ReferenceData) async -> (Bool, String) {
		var updateResult: Bool = true
		var updateMessage: String = ""
		
		let (currentMonth, currentMonthYear) = getCurrentMonthYear()
		
		var tutorNum = 0
		let tutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < tutorCount {
			if referenceData.tutors.tutorsList[tutorNum].tutorStatus != "Deleted" {
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				let timesheetFileName = "Timesheet " + currentMonthYear + " " + tutorName
				do {
					let (getResult, timesheetFileID) = try await getFileID(fileName: timesheetFileName)
					let range = tutorName + PgmConstants.tutorDataTimesheetFileIDRange
					let updateValues = [[timesheetFileID]]
					do {
						let updateResult = try await writeSheetCells(fileID: tutorDetailsFileID, range: range, values: updateValues)
						print("   Information: Updating Timesheet File ID for \(tutorName) in Tutor Details spreadsheet")
					} catch {
						updateResult = false
						updateMessage = "Error updating timesheet file ID for \(tutorName)"
					}
				} catch {
					updateResult = false
					updateMessage = "Error getting file ID for \(timesheetFileName)"
				}
			}
			
			tutorNum += 1
		}
		
		return(updateResult, updateMessage)
	}
	
	
	//
	// This function creates a new Billed Tutor object for a month, reads in the data for that month and returns that new Billed Tutor object
	//		monthName: the month to load the Billed Tutor data for
	//		yearName: the year of the month to load the Billed Tutor data for
	//
	func buildBilledTutorMonth(monthName: String, yearName: String, loadValidatedData: Bool) async -> TutorBillingMonth {
		let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
		var fileIdResult: Bool = true
		var tutorBillingFileID = ""
		let tutorBillingMonth = TutorBillingMonth(monthName: monthName)
		
		// Get the fileID of the Billed Tutor spreadsheet for the year containing the month's Billed Tutor data
		do {
			(fileIdResult, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			// Read the data from the Billed Tutor spreadsheet for the month into a new TutorBillingMonth object
			if fileIdResult {
				let readResult = await tutorBillingMonth.getTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID, loadValidatedData: loadValidatedData)
				if !readResult {
					print("Warning: Could not load Tutor Billing Data for \(monthName)")
				}
			} else {
				print("Error: could not get FileID for file: \(tutorBillingFileName)")
			}
		} catch {
			print("Error: Could not get FileID for file: \(tutorBillingFileName)")
		}
		
		return(tutorBillingMonth)
	}
	//
	// This function creates a new Billed Student object for a month, reads in the data for that month and returns that new Billed Student object
	//		monthName: the month to load the Billed Student data for
	//		yearName: the year of the month to load the Billed Student data for
	//
	func buildBilledStudentMonth(monthName: String, yearName: String, loadValidatedData: Bool) async -> StudentBillingMonth {
		let studentBillingFileName = studentBillingFileNamePrefix + yearName
		var fileIdResult: Bool = true
		var studentBillingFileID = ""
		let studentBillingMonth = StudentBillingMonth(monthName: monthName)
		
		// Get the fileID of the Billed Student spreadsheet for the year containing the month's Billed Student data
		do {
			(fileIdResult, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
			// Read the data from the Billed Student spreadsheet for the month into a new StudentBillingMonth object
			if fileIdResult {
				let readResult = await studentBillingMonth.getStudentBillingMonth(monthName: monthName, studentBillingFileID: studentBillingFileID, loadValidatedData: loadValidatedData)
				if !readResult {
					print("Warning: Could not load Student Billing Data for \(monthName)")
				}
			} else {
				print("Error: could not get FileID for file: \(studentBillingFileName)")
			}
		} catch {
			print("Error: Could not get FileID for file: \(studentBillingFileName)")
		}
		
		return(studentBillingMonth)
	}
	
	//
	// This function creates a new Billed Tutor object for a month, reads in the data for that month and returns that new Billed Tutor object
	//		monthName: the month to load the Billed Tutor data for
	//		yearName: the year of the month to load the Billed Tutor data for
	//
	func saveBilledTutorMonth(tutorBillingMonth: TutorBillingMonth, monthName: String, yearName: String, saveValidatedData: Bool) async -> Bool {
		let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
		var fileIdResult: Bool = true
		var tutorBillingFileID = ""
		var saveResult: Bool = true
		
		
		// Get the fileID of the Billed Tutor spreadsheet for the year containing the month's Billed Tutor data
		do {
			(fileIdResult, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			// Read the data from the Billed Tutor spreadsheet for the month into a new TutorBillingMonth object
			if fileIdResult {
				saveResult = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName, saveValidatedTutorData: saveValidatedData)
				if !saveResult {
					print("Warning: Could not save Tutor Billing Data for \(monthName)")
				}
			} else {
				print("Error: could not get FileID for file: \(tutorBillingFileName)")
			}
		} catch {
			print("Error: Could not get FileID for file: \(tutorBillingFileName)")
		}
		
		return(saveResult)
	}
	//
	// This function creates a new Billed Student object for a month, reads in the data for that month and returns that new Billed Student object
	//		monthName: the month to load the Billed Student data for
	//		yearName: the year of the month to load the Billed Student data for
	//
	func saveBilledStudentMonth(studentBillingMonth: StudentBillingMonth, monthName: String, yearName: String, saveValidatedData: Bool) async -> Bool {
		let studentBillingFileName = studentBillingFileNamePrefix + yearName
		var fileIdResult: Bool = true
		var studentBillingFileID = ""
		var saveResult: Bool = true
		
		// Get the fileID of the Billed Student spreadsheet for the year containing the month's Billed Student data
		do {
			(fileIdResult, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
			// Read the data from the Billed Student spreadsheet for the month into a new StudentBillingMonth object
			if fileIdResult {
				saveResult = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: studentBillingFileID, billingMonth: monthName, saveValidatedStudentData: saveValidatedData)
				if !saveResult {
					print("Warning: Could not save Student Billing Data for \(monthName)")
				}
			} else {
				print("Error: could not get FileID for file: \(studentBillingFileName)")
			}
		} catch {
			print("Error: Could not get FileID for file: \(studentBillingFileName)")
		}
		
		return(saveResult)
	}
	
}
