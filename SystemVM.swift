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
	//      - that Students with a Status of Assigned are actually assigned to a Tutor
	//      - that Students with a Status of Unassigned are not assigned to a Tutor
	//	- that the Service assigned count matches the number of Tutors with the Service actually assigned in their Tutor Details sheet
	//	- that Services with a status of Unassigned are not assigned to any Tutors
	//	- that Services with a status of Assigned are assigned to at least one Tutor
	//	- that each Tutor is assigned all Base services
	//	- that the Location count matches the number of Students with that Location
	//	- that Locations with a status of Assigned have a Student count > 0
	//	- that Locations with a status of Unassigned have a Student count = 0
	//	- that Student names and keys are not duplicated
	//	- that Service names and keys are not duplicated
	//	- that Location names and keys are not duplicated
	//	- that Tutor names and keys are not duplicated
	//	- that the Student keys in the RefData match the Student keys in thr Tutor Details sheet for each Tutor
	//	- that the Service keys in the RefData match the Service keys in thr Tutor Details sheet for each Tutor
	//	- that the number of Students in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that each Student Name in the Reference Data is in the current Student Billing sheet
	//	- that each Student Status is valid
	//	- that each Student is in the Billed Student list for the current month
	//	- that each Student's Location name is valid
	//	- that the number of Services in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that each Service Status is valid
	//	- that the number of Locations in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that each Location Status is valid
	//	- that the number of Tutors in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
	//	- that each Tutor Status is valid
	//	- that Unassigned/Suspended/Deleted Tutors have a Student Count = 0
	//	- that there is one Tutor Details sheet for each non-deleted Tutor
	//	- that each Tutor is in the Billed Tutor list for the previous month
	//	- that the Student and Service counts for each Tutor in the Tutor Details sheets matches the RefData counts
	//	- that the count of Tutor Details sheets equals the number of non-deleted Tutors

	
	@MainActor func validateSystem(referenceData: ReferenceData, validationMessages: WindowMessages) async {
		
		var billedTutorMonth = TutorBillingMonth(monthName: "")
		var billedStudentMonth = StudentBillingMonth(monthName: "")
		var billedMonthName: String = ""
		var highestTutorKey: Int = 0
		var highestServiceKey: Int = 0
		var highestStudentKey: Int = 0
		var highestLocationKey: Int = 0
		var logMessage: String
		
		logMessage = "INFO:     Validating System - Stand By for Adventure! "
		await AppLogger.shared.log(logMessage, newLine: true)
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))

		// Every check below reads tutorStudents/tutorServices for potentially every
		// Tutor (cross-checking Reference Data against each Tutor's own Details), so
		// all Tutors' details must be loaded up front. An unloaded Tutor would read
		// as having zero Students/Services, so mismatch checks against that Tutor
		// would silently pass instead of catching a real problem.
		for tutor in referenceData.tutors.tutorsList {
			if tutor.tutorStatus != .TutorDeleted {
				if await !referenceData.ensureTutorDetailsLoaded(tutorID: tutor.id) {
					logMessage = "ERROR: could not load Tutor Details for Tutor \(tutor.tutorName) - validation results for this Tutor will be unreliable"
					await AppLogger.shared.log(logMessage, level: .error)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
			}
		}

		//Load the most current Student Billing and Tutor Billing spreadsheets.  Could be current month or previous month depending on whether current month billed yet.
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
		
		var locationRevenue: Double = 0.0
		var studentRevenue: Double = 0.0
		var studentCost: Double = 0.0
		var tutorRevenue: Double = 0.0
		var tutorCost: Double = 0.0
		
		var tutorSessions: Int = 0
		var studentSessions: Int = 0
		
		var tutorStudentCount: Int = 0
		var assignedStudentCount: Int = 0
		var reassignedStudentCount: Int = 0
		
		// Check if any Students assigned to more than one Tutor; Unassigned Student assigned to a Tutor or Assigned Student assigned to no Tutor
		
		var studentNum = 0
		let studentCount = referenceData.students.studentsList.count
		while studentNum < studentCount {
			let studentKey = referenceData.students.studentsList[studentNum].studentKey
			let keyNumber = studentKey.dropFirst()
			let studentNumber = Int(keyNumber)
			if let studentNumber = Int(keyNumber) {
				if studentNumber > highestStudentKey { highestStudentKey = studentNumber }
			}
			
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
					
					if referenceData.students.studentsList[studentNum].studentStatus == .StudentUnassigned {
						logMessage = "INFO: *** Validation Error - Unassigned Student \(studentName) assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					}
				}
				tutorNum += 1
			}
			if assignedCount > 1 && referenceData.students.studentsList[studentNum].studentStatus != .StudentReassigned {
				logMessage = "INFO:     Validation Warning: Assigned Student \(studentName) assigned to Tutors \(assignedTutors)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			if assignedCount == 1 && referenceData.students.studentsList[studentNum].studentStatus == .StudentReassigned {
				logMessage = "INFO: *** Validation Error - Reassigned Student \(studentName) assigned to only one Tutor \(assignedTutors)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			if assignedCount == 0 && referenceData.students.studentsList[studentNum].studentStatus == .StudentAssigned {
				logMessage = "INFO: *** Validation Error - Assigned Student \(studentName) assigned to no Tutor"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			studentNum += 1
		}
		
		// Check to ensure no Student keys exceed the highest Student key counter in Reference Data data counts
		if highestStudentKey > referenceData.dataCounts.highestStudentKey {
			logMessage = "INFO: *** Validation Error - Maximum assigned Student key is \(highestStudentKey), which is higher than next available key \(referenceData.dataCounts.highestStudentKey)-- duplicate keys will result"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		// Validate that each Service with a Status of Assigned is actually assigned to a Tutor and no Services with a Status of Unassigned is assigned to a Tutor
		// Validate that the Use Count for each Service is equal to the number of Tutors the Service is assigned to
		// Validate that each Base service is assigned to each Student
		var serviceNum = 0
		let serviceCount = referenceData.services.servicesList.count
		while serviceNum < serviceCount {
			let serviceKey = referenceData.services.servicesList[serviceNum].serviceKey
			let keyNumber = serviceKey.dropFirst()
			let serviceNumber = Int(keyNumber)
			if let serviceNumber = Int(keyNumber) {
				if serviceNumber > highestServiceKey { highestServiceKey = serviceNumber }
			}
			let serviceName = referenceData.services.servicesList[serviceNum].serviceTimesheetName
			let serviceType = referenceData.services.servicesList[serviceNum].serviceType
			
			var tutorNum = 0
			var tutorName: String = ""
			var tutorServiceCount:Int = 0
			let tutorCount = referenceData.tutors.tutorsList.count
			while tutorNum < tutorCount {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorDeleted  && referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorSuspended {
		
					let (serviceFound, _) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: serviceKey)
					if serviceFound {
						tutorName = tutorName + referenceData.tutors.tutorsList[tutorNum].tutorName + "; "
						tutorServiceCount += 1
					} else if serviceType == .Base && referenceData.services.servicesList[serviceNum].serviceStatus != .ServiceDeleted && referenceData.tutors.tutorsList[tutorNum].tutorType != .SpecialistTutor {
						logMessage = "INFO: *** Validation Error - Base Service \(serviceName) not assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
						
					}
				}
				tutorNum += 1
			}
			
			if referenceData.services.servicesList[serviceNum].serviceCount != tutorServiceCount {
				logMessage = "INFO: *** Validation Error - Service \(serviceName) Use Count \(referenceData.services.servicesList[serviceNum].serviceCount) does not match assigned Tutor Count \(tutorServiceCount)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			if referenceData.services.servicesList[serviceNum].serviceStatus == .ServiceAssigned && tutorServiceCount == 0 {
				logMessage = "INFO: *** Validation Error - Assigned Service \(serviceName) assigned to no Tutor"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			if referenceData.services.servicesList[serviceNum].serviceStatus == .ServiceUnassigned && tutorServiceCount > 0 {
				logMessage = "INFO: *** Validation Error - Unassigned Service \(serviceName) assigned to Tutor \(tutorName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			serviceNum += 1
		}
		
		// Check to ensure no Service keys exceed the highest Service key counter in Reference Data data counts
		if highestServiceKey > referenceData.dataCounts.highestServiceKey {
			logMessage = "INFO: *** Validation Error - Maximum assigned Service key is \(highestServiceKey), which is higher than next available key \(referenceData.dataCounts.highestServiceKey)-- duplicate keys will result"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		// Validate that the Location count equals the number of (non-deleted) Students with that Location
		// Validate that no Location with a status of Deleted has a Student Count > 0
		// Validate that no Location with a status of Assigned has a Student Count == 0
		var locationNum = 0
		let locationCount = referenceData.locations.locationsList.count
		while locationNum < locationCount {
			if referenceData.locations.locationsList[locationNum].locationStatus == .LocationDeleted && referenceData.locations.locationsList[locationNum].locationStudentCount > 0 {
				logMessage = "INFO: *** Validation Error - Unassigned Location \(referenceData.locations.locationsList[locationNum].locationName) has a Student Count of \(referenceData.locations.locationsList[locationNum].locationStudentCount)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			if referenceData.locations.locationsList[locationNum].locationStatus == .LocationActive && referenceData.locations.locationsList[locationNum].locationStudentCount == 0 {
				logMessage = "INFO: *** Validation Error - Active Location \(referenceData.locations.locationsList[locationNum].locationName) has a Student Count of \(referenceData.locations.locationsList[locationNum].locationStudentCount)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			studentNum = 0
			var studentLocationCount = 0
			while studentNum < studentCount {
				if referenceData.students.studentsList[studentNum].studentLocation == referenceData.locations.locationsList[locationNum].locationName && referenceData.students.studentsList[studentNum].studentStatus != .StudentDeleted {
					studentLocationCount += 1
				}
				studentNum += 1
			}
			
			if referenceData.locations.locationsList[locationNum].locationStudentCount != studentLocationCount {
				logMessage = "INFO: *** Validation Error - Location \(referenceData.locations.locationsList[locationNum].locationName) assigned Student Count \(referenceData.locations.locationsList[locationNum].locationStudentCount) does not match actual Student Count \(studentLocationCount)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			locationNum += 1
		}
		
		
		
		// Validate that each Tutor has a Timesheet
		
		
		
		// Check for duplicate Student keys or names
		studentNum = 0
		while studentNum < studentCount {
			
			// Check for duplicate Student keys
			let studentKey = referenceData.students.studentsList[studentNum].studentKey
			let studentKeyCount = referenceData.students.studentsList.filter { $0.studentKey == studentKey }.count
			if studentKeyCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Student Key \(studentKey) for \(referenceData.students.studentsList[studentNum].studentName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			// Check for duplicate Student names
			let studentName = referenceData.students.studentsList[studentNum].studentName
			let studentNameCount = referenceData.students.studentsList.filter { $0.studentName == studentName }.count
			if studentNameCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Student Name \(studentName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			studentNum += 1
		}
		
		// check for duplicate Service keys or names
		serviceNum = 0
//		serviceCount = referenceData.services.servicesList.count
		while serviceNum < serviceCount {
			
			// Check for duplicate Service keys
			let serviceKey = referenceData.services.servicesList[serviceNum].serviceKey
			let serviceKeyCount = referenceData.services.servicesList.filter { $0.serviceKey == serviceKey }.count
			if serviceKeyCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Service Key \(serviceKey) for Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			// Check for duplicate Service names
			let serviceName = referenceData.services.servicesList[serviceNum].serviceTimesheetName
			let serviceNameCount = referenceData.services.servicesList.filter { $0.serviceTimesheetName == serviceName }.count
			if serviceNameCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Service Name \(serviceName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			serviceNum += 1
		}
		
		// Check for duplicate Location keys or names
		locationNum = 0
//		locationCount = referenceData.locations.locationsList.count
		while locationNum < locationCount {
			
			// Check for duplicate Location keys
			let locationKey = referenceData.locations.locationsList[locationNum].locationKey
			let keyNumber = locationKey.dropFirst()
			let locationNumber = Int(keyNumber)
			if let locationNumber = Int(keyNumber) {
				if locationNumber > highestLocationKey { highestLocationKey = locationNumber }
			}
			
			let locationKeyCount = referenceData.locations.locationsList.filter { $0.locationKey == locationKey }.count
			if locationKeyCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Location Key \(locationKey) for Location \(referenceData.locations.locationsList[locationNum].locationName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			// Check for duplicate Location names
			let locationName = referenceData.locations.locationsList[locationNum].locationName
			let locationNameCount = referenceData.locations.locationsList.filter { $0.locationName == locationName }.count
			if locationNameCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Location Name \(locationName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			locationNum += 1
		}
		
		// Check to ensure no Location keys exceed the highest Location key counter in Reference Data data counts
		if highestLocationKey > referenceData.dataCounts.highestLocationKey {
			logMessage = "INFO: ** Validation Error - Maximum assigned Location key is \(highestLocationKey), which is higher than next available key \(referenceData.dataCounts.highestLocationKey)-- duplicate keys will result"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		// Various Tutor data checks
		var tutorNum = 0
		let tutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < tutorCount {
			
			let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
			
			// Check for duplicate Tutor Keys in Reference Data
			let tutorKey = referenceData.tutors.tutorsList[tutorNum].tutorKey
			let keyNumber = tutorKey.dropFirst()
			let tutorNumber = Int(keyNumber)
			if let tutorNumber = Int(keyNumber) {
				if tutorNumber > highestTutorKey { highestTutorKey = tutorNumber }
			}
			
			let tutorKeyCount = referenceData.tutors.tutorsList.filter { $0.tutorKey == tutorKey }.count
			if tutorKeyCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Tutor Key \(tutorKey)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			// Check for duplicate Tutor Names in Reference Data
			let tutorNameCount = referenceData.tutors.tutorsList.filter { $0.tutorName == tutorName }.count
			if tutorNameCount > 1 {
				logMessage = "INFO: *** Validation Error: Duplicate Tutor Name \(tutorName)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			// Check that the Student Keys in the Reference Data matches the Student Keys in the Tutor Details file for each Tutor
			var tutorStudentNum = 0
			let tutorStudentCount = referenceData.tutors.tutorsList[tutorNum].tutorStudents.count
			while tutorStudentNum < tutorStudentCount {
				let tutorStudentKey = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentKey
				let tutorStudentName = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentName
				let (studentFound, studentNum) = referenceData.students.findStudentByKey(studentKey: tutorStudentKey)
				if studentFound {
					let studentName = referenceData.students.studentsList[studentNum].studentName
					
					if studentName != tutorStudentName {
						logMessage = "INFO: *** Validation Error: \(tutorStudentKey) associated with \(studentName) in Reference Data and \(tutorStudentName) in Tutor Details for Tutor \(tutorName)"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					}
				} else {
					logMessage = "INFO: *** Validation Error: \(tutorStudentKey) not found in Reference Data"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
				tutorStudentNum += 1
			}
			
			// Check that the Service Keys in the Reference Data matches the Service Keys in the Tutor Details file for each Tutor
			var tutorServiceNum = 0
			let tutorServiceCount = referenceData.tutors.tutorsList[tutorNum].tutorServices.count
			while tutorServiceNum < tutorServiceCount {
				let tutorServiceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
				let tutorServiceName = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName
				
				let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: tutorServiceKey)
				if serviceFound {
					let serviceName = referenceData.services.servicesList[serviceNum].serviceTimesheetName
					
					if serviceName != tutorServiceName {
						logMessage = "INFO: *** Validation Error: \(tutorServiceKey) associated with \(serviceName) in Reference Data and \(tutorServiceName) in Tutor Details for Tutor \(tutorName)"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					}
				} else {
					logMessage = "INFO: *** Validation Error: \(tutorServiceKey) not found in Reference Data"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
				tutorServiceNum += 1
			}
			
			tutorNum += 1
		}
		
		// Check to ensure no Tutor keys exceed the highest Tutor key counter in Reference Data data counts
		if highestTutorKey > referenceData.dataCounts.highestTutorKey {
			logMessage = "INFO: *** Validation Error - Maximum assigned Tutor key is \(highestTutorKey), which is higher than next available key \(referenceData.dataCounts.highestTutorKey)-- duplicate keys will result"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		// Check that the number of Students in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalStudents = 0
		var activeStudents = 0
		var deletedStudents = 0

		studentNum = 0
		while studentNum < studentCount {
			let studentName = referenceData.students.studentsList[studentNum].studentName
			
			switch referenceData.students.studentsList[studentNum].studentStatus {
				case .StudentAssigned:
					activeStudents += 1
					assignedStudentCount += 1
				case .StudentReassigned:
					activeStudents += 1
					reassignedStudentCount += 1
				case .StudentUnassigned, .StudentSuspended:
					activeStudents += 1
				case .StudentDeleted:
					deletedStudents += 1
				default:
					logMessage = "INFO: *** Validation Error: Invalid Status for Student \(studentName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:logMessage))
			}
			totalStudents += 1
			studentRevenue += referenceData.students.studentsList[studentNum].studentTotalRevenue
			studentCost += referenceData.students.studentsList[studentNum].studentTotalCost
			studentSessions += referenceData.students.studentsList[studentNum].studentSessions
			
			// Check if Student found in Billed Student List for current/previous month
			if referenceData.students.studentsList[studentNum].studentStatus != .StudentDeleted {
				let (studentFoundFlag, billedStudentNum) = billedStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
				if !studentFoundFlag {
					logMessage = "INFO: *** Validation Error: Student \(studentName) not found in Billed Student Month for \(billedMonthName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:logMessage))
				}
				
				// Validate the Location Name for the Student
				let (findResult, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
				if !findResult {
					logMessage = "INFO: *** Validation Error: Location \(referenceData.students.studentsList[studentNum].studentLocation) for Student \(studentName) not found in Locations List"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
			}
			studentNum += 1
		}
		logMessage = "INFO:           Total Students \(totalStudents), Active Students \(activeStudents), Deleted Students \(deletedStudents)"
		await AppLogger.shared.log(logMessage)
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		
		if totalStudents != referenceData.dataCounts.totalStudents {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Total Students \(referenceData.dataCounts.totalStudents) does not match actual count in Reference Data Students list of \(totalStudents)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:logMessage))
		}
		if activeStudents != referenceData.dataCounts.activeStudents {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Active Students \(referenceData.dataCounts.activeStudents) does not match actual count in Reference Data Students list of \(activeStudents)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
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
				case .ServiceUnassigned, .ServiceAssigned:
					activeServices += 1
				case .ServiceDeleted, .ServiceSuspended:
					deletedServices += 1
				default:
					logMessage = "INFO: *** Validation Error - Invalid Status for Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			totalServices += 1
			
			serviceNum += 1
		}
		logMessage = "INFO:           Total Services \(totalServices), Active Services \(activeServices), Deleted Services \(deletedServices)"
		await AppLogger.shared.log(logMessage)
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		
		if totalServices != referenceData.dataCounts.totalServices {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Total Services \(referenceData.dataCounts.totalServices) does not match actual count in Reference Data Services list of \(totalServices)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		if activeServices != referenceData.dataCounts.activeServices {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Active Services \(referenceData.dataCounts.activeServices) does not match actual count in Reference Data Services list of \(activeServices)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
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
				case .LocationActive:
					activeLocations += 1
				case .LocationDeleted:
					deletedLocations += 1
				default:
					logMessage = "INFO: *** Validation Error: Invalid Location Status for Location \(referenceData.locations.locationsList[locationNum].locationName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			locationStudents += referenceData.locations.locationsList[locationNum].locationStudentCount
			totalLocations += 1
			locationRevenue += referenceData.locations.locationsList[locationNum].locationTotalRevenue
			
			locationNum += 1
		}
		logMessage = "INFO:           Total Locations \(totalLocations), Active Locations \(activeLocations), Deleted Locations \(deletedLocations)"
		await AppLogger.shared.log(logMessage)
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		
		
		if locationStudents != activeStudents {
			logMessage = "INFO: *** Validation Error: Count of Location Students \(locationStudents) does not match actual count of Students in Reference Data Locations list of \(activeStudents)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		if totalLocations != referenceData.dataCounts.totalLocations {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Total Locations \(referenceData.dataCounts.totalLocations) does not match actual count in Reference Data Locations list of \(totalLocations)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		if activeLocations != referenceData.dataCounts.activeLocations {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Active Locations \(referenceData.dataCounts.activeLocations) does not match actual count in Reference Data Locations list of \(activeLocations)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
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
				case .TutorAssigned:
					activeTutors += 1
					tutorStudentCount += referenceData.tutors.tutorsList[tutorNum].tutorStudentCount
				case .TutorUnassigned, .TutorSuspended:
					activeTutors += 1
					if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount != 0 {
						logMessage = "INFO: *** Validation Error: Student Count for \(tutorName) not equal to zero and Tutor Status is not Assigned"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					}
				case .TutorDeleted:
					deletedTutors += 1
					if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount != 0 {
						logMessage = "INFO: *** Validation Error: Student Count for \(tutorName) not equal to zero and Tutor Status is Deleted"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					}
				default:
					logMessage = "INFO: *** Validation Error: Invalid Tutor Status for Tutor \(tutorName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			
			if referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorDeleted {
				// Validate that there is one Tutor Details sheet for each active (non-deleted) Tutor
				do {
					sheetNum = try await getSheetIdByName(spreadsheetID: tutorDetailsFileID, sheetName: tutorName )
				} catch {
					logMessage = "INFO: *** Validation Error: could not get Tutor Details sheet ID for Tutor \(tutorName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
				
				if sheetNum == nil {
					logMessage = "INFO: *** Validation Error: could not get Tutor Details sheet ID for Tutor \(tutorName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
				
				// Check if Tutor found in Billed Tutor List for previous month
				let (tutorFoundFlag, billedTutorNum) = billedTutorMonth.findBilledTutorByName(billedTutorName: tutorName)
				if !tutorFoundFlag {
					logMessage = "INFO: *** Validation Error: Tutor \(tutorName) not found in Billed Tutor Month for \(billedMonthName)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
				
				// Check if Student and Service counts in the Tutor Details sheet match the Tutor's counts in the Reference Data entry for the Tutor
				let (studentCount, serviceCount, timesheetFileID) = await referenceData.tutors.tutorsList[tutorNum].fetchTutorDataCounts(tutorName: tutorName)
				if studentCount != referenceData.tutors.tutorsList[tutorNum].tutorStudentCount {
					logMessage = "INFO: *** Validation Error: Reference Data Student count for Tutor \(tutorName) is \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) but Tutor Details count is \(studentCount)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
				
				if serviceCount != referenceData.tutors.tutorsList[tutorNum].tutorServiceCount {
					logMessage = "INFO: *** Validation Error: Reference Data Service count for Tutor \(tutorName) is \(referenceData.tutors.tutorsList[tutorNum].tutorServiceCount) but Tutor Details count is \(serviceCount)"
					await AppLogger.shared.log(logMessage)
					validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				}
				
			}
			
			totalTutors += 1
			tutorRevenue += referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue
			tutorCost += referenceData.tutors.tutorsList[tutorNum].tutorTotalCost
			tutorSessions += referenceData.tutors.tutorsList[tutorNum].tutorTotalSessions
			
			tutorNum += 1
		}
		logMessage = "INFO:           Total Tutors \(totalTutors), Active Tutors \(activeTutors), Deleted Tutors \(deletedTutors)"
		await AppLogger.shared.log(logMessage)
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		
		do {
			let tutorDetailsSheetCount = try await getSheetCount(spreadsheetID: tutorDetailsFileID)
			if (tutorDetailsSheetCount - 1) != activeTutors {	// Subtract 1 from sheet count for shared RefData sheet
				logMessage = "INFO: *** Validation Error - count of active tutors: \(activeTutors) does not equal number of Tutor Details sheets: \(tutorDetailsSheetCount)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
		} catch {
			logMessage = "INFO: *** Validation Error: could get get count of TutorDetails sheets"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		if totalTutors != referenceData.dataCounts.totalTutors {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Total Tutors \(referenceData.dataCounts.totalTutors) does not match actual count in Reference Data Tutors list of \(totalTutors)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		if activeTutors != referenceData.dataCounts.activeTutors {
			logMessage = "INFO: *** Validation Error: Reference Data Count for Active Tutors \(referenceData.dataCounts.activeTutors) does not match actual count in Reference Data Tutors list of \(activeTutors)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		//		if deletedTutors != referenceData.dataCounts.totalTutors - referenceData.dataCounts.activeTutors  {
		//			print("Validation Error: Reference Data Count for Deleted Tutors \(referenceData.dataCounts.deletedTutors) does not match actual count in Reference Data Tutors list of \(deletedTutors)")
		//		}
		
		
		// Get the session count, total cost and total revenue for the previous Billed Student month (current month may not be done yet)
		var billedStudentSessionCount: Int  = 0
		var billedStudentTotalCost: Double = 0.0
		var billedStudentTotalRevenue: Double = 0.0
		var billedStudentNum = 0
		let billedStudentCount = billedStudentMonth.studentBillingRows.count
		while billedStudentNum < billedStudentCount {
			billedStudentSessionCount += billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledSessions
			billedStudentTotalRevenue += billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue
			billedStudentTotalCost += billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost
			
			let billedStudentRevenue = billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue
			let billedStudentCost = billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost
			let billedStudentProfit = billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledProfit
			let computedProfit = billedStudentRevenue - billedStudentCost
			
			// Check if Revenue - Cost == Profit for Student Billing row
			if ( abs(computedProfit - billedStudentProfit) ) > 1.00  {
				logMessage = "INFO: *** Validation Error: Billed Student Profit \(billedStudentProfit) for for Student: \(billedStudentMonth.studentBillingRows[billedStudentNum].studentName)  does not match Revenue - Cost \(computedProfit)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
				
			}
			billedStudentNum += 1
		}
		
		// Get the session count, total cost and total revenue for the previous Bill Tutor month (current month may not be done yet)
		var billedTutorSessionCount: Int  = 0
		var billedTutorTotalCost: Double = 0.0
		var billedTutorTotalRevenue: Double = 0.0
		var billedTutorNum = 0
		let billedTutorCount = billedTutorMonth.tutorBillingRows.count
		while billedTutorNum < billedTutorCount {
			//			print("Billed Tutor: \(billedTutorMonth.tutorBillingRows[billedTutorNum].tutorName)  \(billedTutorMonth.tutorBillingRows[billedTutorNum].totalBillingSessions)")
			billedTutorSessionCount += billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledSessions
			billedTutorTotalRevenue += billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue
			billedTutorTotalCost += billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost
			
			let billedStudentRevenue = billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue
			let billedStudentCost = billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost
			let billedStudentProfit = billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledProfit
			let computedProfit = billedStudentRevenue - billedStudentCost
			
			// Check if Revenue - Cost == Profit for Tutor Billing row
			if ( abs(computedProfit - billedStudentProfit) ) > 1.0  {
				logMessage = "INFO: *** Validation Error: Billed Tutor Profit \(billedStudentProfit)  does not match Revenue - Cost \(computedProfit)"
				await AppLogger.shared.log(logMessage)
				validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			}
			
			billedTutorNum += 1
		}
		
		// Validate that the sum of the Tutors total revenue equals Student total revenue equals Location total revenue equals Billed Student revenue count equals Billed Tutor revenue Count
		if !CompareTotals(referenceDataTotal: tutorRevenue, billedDataTotal: studentRevenue) || !CompareTotals(referenceDataTotal: studentRevenue, billedDataTotal: locationRevenue) || !CompareTotals(referenceDataTotal: tutorRevenue, billedDataTotal: locationRevenue) || !CompareTotals(referenceDataTotal: locationRevenue, billedDataTotal: billedTutorTotalRevenue) || !CompareTotals(referenceDataTotal: billedTutorTotalRevenue, billedDataTotal: billedStudentTotalRevenue) {
			let formatter = NumberFormatter()
			formatter.numberStyle = .currency
			formatter.locale = Locale(identifier: "en_US")
			
			let tutorRevenueString: String = formatter.string(from: NSNumber(value: tutorRevenue)) ?? " "
			let studentRevenueString: String = formatter.string(from: NSNumber(value: studentRevenue)) ?? " "
			let locationRevenueString: String = formatter.string(from: NSNumber(value: locationRevenue)) ?? " "
			let billedTutorTotalRevenueString: String = formatter.string(from: NSNumber(value: billedTutorTotalRevenue)) ?? " "
			let billedStudentTotalRevenueString: String = formatter.string(from: NSNumber(value: billedStudentTotalRevenue)) ?? " "
			logMessage = "INFO: *** Validation Error: Tutor revenue " + tutorRevenueString + ", Student revenue" + studentRevenueString + ", Location revenue " + locationRevenueString + ", Billed Tutor revenue " + billedTutorTotalRevenueString + " and Billed Student revenue " + billedStudentTotalRevenueString + " do not match"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			
			// If total Student revenue in RefData does not equal total Student revenue in Billed Student list, find the difference
			if studentRevenue != billedStudentTotalRevenue {
				var studentNum = 0
				let studentCount = referenceData.students.studentsList.count
				while studentNum < studentCount {
					let studentName = referenceData.students.studentsList[studentNum].studentName
					let refStudentRevenue = referenceData.students.studentsList[studentNum].studentTotalRevenue
					let (studentFoundFlag, billedStudentNum) = billedStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
					if !studentFoundFlag {
						logMessage = "INFO: *** Validation Error: could not find Student \(studentName) in Billed Student month comparing Student revenue differences"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					} else {
						let billedStudentRevenue = billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledRevenue

						if !CompareTotals(referenceDataTotal: refStudentRevenue, billedDataTotal: billedStudentRevenue) {
							logMessage = "INFO: *** Validation Error: Billed Student revenue \(billedStudentRevenue) does not match Reference Data Student revenue \(refStudentRevenue) for \(studentName) "
							await AppLogger.shared.log(logMessage)
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
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
						logMessage = "INFO: *** Validation Error: could not find Tutor \(tutorName) in Billed Tutor month comparing Tutor revenue differences"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					} else {
						let billedTutorRevenue = billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledRevenue
						if !CompareTotals(referenceDataTotal: refTutorRevenue, billedDataTotal: billedTutorRevenue) {
							logMessage = "INFO: *** Validation Error: Billed Tutor revenue \(billedTutorRevenue) does not match Reference Data Tutor revenue \(refTutorRevenue) for \(tutorName) "
							await AppLogger.shared.log(logMessage)
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
						}
					}
					tutorNum += 1
				}
			}
		}
		
		// Validate that the Tutors total cost, Student total cost, billed Student total cost and billed Tutor Total Cost all match
		if !CompareTotals(referenceDataTotal: tutorCost, billedDataTotal: studentCost) || !CompareTotals(referenceDataTotal: studentCost, billedDataTotal: billedTutorTotalCost) || !CompareTotals(referenceDataTotal: billedTutorTotalCost, billedDataTotal: billedStudentTotalCost) {
			logMessage = "INFO: *** Validation Error: Tutor cost \(tutorCost), Student cost \(studentCost), Billed Tutor cost \(billedStudentTotalCost) and Billed Student total cost \(billedStudentTotalCost) do not match"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			
			// If total Student cost in RefData does not equal total Student cost in Billed Student list, find the difference
			if studentCost != billedStudentTotalCost {
				var studentNum = 0
				let studentCount = referenceData.students.studentsList.count
				while studentNum < studentCount {
					let studentName = referenceData.students.studentsList[studentNum].studentName
					let refStudentCost = referenceData.students.studentsList[studentNum].studentTotalCost
					let (studentFoundFlag, billedStudentNum) = billedStudentMonth.findBilledStudentByStudentName(billedStudentName: studentName)
					if !studentFoundFlag {
						logMessage = "INFO: *** Validation Error: could not find Student \(studentName) in Billed Student month comparing Student cost differences"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText:logMessage))
					} else {
						let billedStudentCost = billedStudentMonth.studentBillingRows[billedStudentNum].totalBilledCost

						if !CompareTotals(referenceDataTotal: refStudentCost, billedDataTotal: billedStudentCost) {
							logMessage = "INFO: *** Validation Error: Billed Student cost \(billedStudentCost) does not match Reference Data Student cost \(refStudentCost) for \(studentName) "
							await AppLogger.shared.log(logMessage)
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
						}
					}
					
					if (abs(referenceData.students.studentsList[studentNum].studentTotalRevenue - referenceData.students.studentsList[studentNum].studentTotalCost - referenceData.students.studentsList[studentNum].studentTotalProfit) > 1.0) {
						logMessage = "INFO: *** Validation Error: Reference Data Student profit \(referenceData.students.studentsList[studentNum].studentTotalProfit) does not match Revenue - Cost \(referenceData.students.studentsList[studentNum].studentTotalRevenue - referenceData.students.studentsList[studentNum].studentTotalCost) for Student \(studentName)  "
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
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
						logMessage = "INFO: *** Validation Error: could not find Tutor \(tutorName) in Billed Tutor month comparing Tutor cost differences"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					} else {
						let billedTutorCost = billedTutorMonth.tutorBillingRows[billedTutorNum].totalBilledCost

						if !CompareTotals(referenceDataTotal: refTutorCost, billedDataTotal: billedTutorCost) {
							logMessage = "INFO: *** Validation Error: Billed Tutor cost \(billedTutorCost) does not match Reference Data Tutor cost \(refTutorCost) for \(tutorName) "
							await AppLogger.shared.log(logMessage)
							validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
						}
					}
					if (abs (referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue - referenceData.tutors.tutorsList[tutorNum].tutorTotalCost - referenceData.tutors.tutorsList[tutorNum].tutorTotalProfit) > 1.0) {
						logMessage = "INFO: *** Validation Error: Reference Data Tutor profit \(referenceData.tutors.tutorsList[tutorNum].tutorTotalProfit) does not match Revenue - Cost \(referenceData.tutors.tutorsList[tutorNum].tutorTotalRevenue - referenceData.tutors.tutorsList[tutorNum].tutorTotalCost) for tutor \(tutorName)  "
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					}
					
					tutorNum += 1
				}
			}
		}
		
		// Validate that the Tutor session count, Student session count, Billed Tutor session count and the Billed Student session count all match
		if tutorSessions != studentSessions || studentSessions != billedStudentSessionCount || billedStudentSessionCount != billedTutorSessionCount {
			logMessage = "INFO: *** Validation Error: Tutor session count \(tutorSessions), Student session count \(studentSessions), Billed Tutor session count \(billedTutorSessionCount) and Billed Student Session count \(billedStudentSessionCount) do not match"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		if tutorStudentCount != assignedStudentCount + reassignedStudentCount {
			logMessage = "INFO: *** Validation Error: Tutor Student count \(tutorStudentCount) does not match assigned Student count \(assignedStudentCount) plus reassigned Student count \(reassignedStudentCount)-- could be due to reassignment"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		// Validate master reference spreadsheet file key matches the import file keys in each timesheet and timesheet template
		
		// Validate that the total number of Tutors in the previous month Billed Tutor List is equal to the number of active Tutors
		
		if billedTutorMonth.tutorBillingRows.count != totalTutors {
			logMessage = "INFO: *** Validation Error: Total Tutor count \(totalTutors) does not match number of Tutors in \(billedMonthName) Billed Tutor list \(billedTutorMonth.tutorBillingRows.count)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		}
		
		// Validate that the total number of Students in the previous month Billed Student List is equal to the number of active Students
		
		if billedStudentMonth.studentBillingRows.count != totalStudents {
			logMessage = "INFO: *** Validation Error: Total Student count \(totalStudents) does not match number of Students in \(billedMonthName) Billed Student list \(billedStudentMonth.studentBillingRows.count)"
			await AppLogger.shared.log(logMessage)
			validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
			// If more Students in Billed Student list, find missing Student
			if totalStudents < billedStudentMonth.studentBillingRows.count {
				var studentNum = 0
				var studentCount = billedStudentMonth.studentBillingRows.count
				while studentNum < studentCount {
					let studentName = billedStudentMonth.studentBillingRows[studentNum].studentName
					let (studentFoundFlag, billedStudentNum) = referenceData.students.findStudentByName(studentName: studentName)
					if !studentFoundFlag {
						logMessage = "INFO: Student \(studentName) is in Billed Student list but not Reference Data Students"
						await AppLogger.shared.log(logMessage)
						validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
					}
					
					studentNum += 1
				}
			}
		}
		logMessage = "INFO:       Validation Complete \n"
		await AppLogger.shared.log(logMessage)
		validationMessages.addMessageLine(windowLineText: WindowMessageLine(windowLineText: logMessage))
		
	}
	
	// This function compares a Reference Data total (e.g. revenue) against the Billed data to see if they are close and returns a boolean based on the result
	func CompareTotals(referenceDataTotal: Double, billedDataTotal: Double) -> Bool {
		if billedDataTotal == 0 {
			return true
		} else {
			if referenceDataTotal / billedDataTotal > 0.99 && referenceDataTotal / billedDataTotal < 1.01 {
				return true
			} else {
				return false
			}
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
	func backupSystem() async -> Bool {
		var logMessage: String
		
		var completionFlag: Bool = true
		var copyFileResult: Bool
		var copyFileID: String?
		
		var fileName: String
		var copyFileName: String = ""
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
		let backupDate = dateFormatter.string(from: Date())
		dateFormatter.dateFormat = "yyyy"
		let currentYear = dateFormatter.string(from: Date())
		
		logMessage = "INFO: ** Backing up system ** "
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .info)
		
		// Copy the Reference Data spreadsheet
		copyFileName = runMode.referenceDataFileName + " Backup " + backupDate
		
		do {
			(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: referenceDataFileID, newFileName: copyFileName)
			if copyFileResult {
				logMessage = "INFO: Reference Data spreadsheet backed up to file: \(copyFileName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				completionFlag = false
				logMessage = "ERROR: Reference Data not backed up"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			logMessage = "ERROR: Error backing up Reference Data spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the Tutor Details spreadsheet
		copyFileName = runMode.tutorDetailsFileName + " Backup " + backupDate
		
		do {
			
			(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: tutorDetailsFileID, newFileName: copyFileName)
			if copyFileResult {
				logMessage = "INFO: Tutor Details spreadsheet copied to file: \(copyFileName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				completionFlag = false
				logMessage = "ERROR: Tutor Details Data spreadsheet not backed up"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			logMessage = "ERROR: Error backing up Tutor Details spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the Tutor Billing spreadsheet
		copyFileName = tutorBillingFileNamePrefix + currentYear
		do {
			let (tutorFileFound, tutorBillingFileID) = try await getFileID(fileName: copyFileName)
			if tutorFileFound {
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: tutorBillingFileID, newFileName: copyFileName + " Backup " + backupDate)
				if copyFileResult {
					logMessage = "INFO: Billed Tutor spreadsheet copied to file: \(copyFileName + " Backup " + backupDate)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				} else {
					completionFlag = false
					logMessage = "ERROR: Tutor Billing spreadsheet \(copyFileName) not backed up"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				completionFlag = false
				logMessage = "INFO: Billed Tutor spreadsheet copied to file: \(copyFileName + " Backup " + backupDate)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			logMessage = "ERROR: Error backing up Billed Tutor spreadsheet: \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the Student Billing spreadsheet
		copyFileName = studentBillingFileNamePrefix + currentYear
		do {
			let (studentFileFound, studentBillingFileID) = try await getFileID(fileName: copyFileName)
			if studentFileFound {
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: studentBillingFileID, newFileName: copyFileName + " Backup " + backupDate)
				if copyFileResult {
					logMessage = "INFO: Billed Student spreadsheet copied to file: \(copyFileName + " Backup " + backupDate)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				}
			} else {
				completionFlag = false
				logMessage = "ERROR: Student Billing spreadsheet \(copyFileName) not backed up"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
			
			if completionFlag {
				logMessage = "INFO: ** Backup Complete **"
				print(logMessage + "\n")
				await AppLogger.shared.log(logMessage, level: .info, newLine: true)
			}
		} catch {
			logMessage = "ERROR: Error backing up Billed Student spreadsheet: \(copyFileName), \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		return(completionFlag)
	}
	
	// This function re-initializes the 4 key test files
	//    	delete the existing file
	//	copy the initialization version
	func resetTestFiles() async -> (Bool, String) {
		var logMessage: String
		var resetResult: Bool = true
		
		var copyFileResult: Bool
		var copyFileID: String?
		
		var fileName: String
		var copyFileName: String
		var deleteFileName: String
		var fileIDResult: Bool
		var deleteFileID: String
		var deleteResult: Bool
		var sourceFileName: String
		var sourceFileID: String
		
		logMessage = "INFO: ** Resetting Test Files ** "
		await AppLogger.shared.log(logMessage, level: .info, newLine: true)
		
		// Delete the test Reference Data spreadsheet
		deleteFileName = PgmConstants.testRefFileName
		do {
			(fileIDResult, deleteFileID) = try await getFileID(fileName: deleteFileName)
			deleteResult = try await deleteFile(fileID: deleteFileID)
			if deleteResult {
				logMessage = "INFO: \(deleteFileName) deleted"
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				logMessage = "ERROR: \(deleteFileName) not deleted"
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			resetResult = false
			logMessage = "ERROR: could not delete test Reference Data File: \(deleteFileName) resetting test files"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the initialization Reference Data spreadsheet
		sourceFileName = PgmConstants.initializationTestRefDataFileName
		copyFileName = deleteFileName
		
		do {
			(fileIDResult, sourceFileID) = try await getFileID(fileName: sourceFileName)
			if fileIDResult {
				
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: sourceFileID, newFileName: copyFileName)
				if copyFileResult {
					logMessage = "INFO: Reference Data initialization file copied to file: \(copyFileName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				} else {
					resetResult = false
					logMessage = "ERROR: Reference Data file not reset"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: Could not get File ID for Initialization Reference Data File \(sourceFileName)"
			}
		} catch {
			logMessage = "ERROR: Error resetting Reference Data spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Delete the test Tutor Details spreadsheet
		deleteFileName = PgmConstants.tutorDetailsTestFileName
		do {
			(fileIDResult, deleteFileID) = try await getFileID(fileName: deleteFileName)
			deleteResult = try await deleteFile(fileID: deleteFileID)
			if deleteResult {
				logMessage = "INFO: \(deleteFileName) deleted"
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				logMessage = "ERROR: \(deleteFileName) not deleted"
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			resetResult = false
			logMessage = "ERROR: could not delete test Tutor Details Data File: \(deleteFileName) resetting test files"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the initialization Tutor Details spreadsheet
		sourceFileName = PgmConstants.initializationTestDetailsFileName
		copyFileName = deleteFileName
		
		do {
			(fileIDResult, sourceFileID) = try await getFileID(fileName: sourceFileName)
			if fileIDResult {
				
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: sourceFileID, newFileName: copyFileName)
				if copyFileResult {
					logMessage = "INFO: Tutor Details initialization file copied to file: \(copyFileName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				} else {
					resetResult = false
					logMessage = "ERROR: Tutor Details file \(sourceFileName) not reset"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: Could not get File ID for Initialization Tutor Details File \(sourceFileName)"
			}
		} catch {
			logMessage = "ERROR: Error resetting Tutor Details spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Delete the first year Tutor Billing spreadsheet
		deleteFileName = PgmConstants.tutorBillingTestFileName1
		do {
			(fileIDResult, deleteFileID) = try await getFileID(fileName: deleteFileName)
			deleteResult = try await deleteFile(fileID: deleteFileID)
			if deleteResult {
				logMessage = "INFO: \(deleteFileName) deleted"
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				logMessage = "ERROR: \(deleteFileName) not deleted"
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			resetResult = false
			logMessage = "ERROR: could not delete test Tutor Billing File: \(deleteFileName) resetting test files"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the initialization Tutor Billing spreadsheet
		sourceFileName = PgmConstants.initializationTestTutorBillingFile1Name
		copyFileName = deleteFileName
		
		do {
			(fileIDResult, sourceFileID) = try await getFileID(fileName: sourceFileName)
			if fileIDResult {
				
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: sourceFileID, newFileName: copyFileName)
				if copyFileResult {
					logMessage = "INFO: Tutor Billing initialization file copied to file: \(copyFileName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				} else {
					resetResult = false
					logMessage = "ERROR: Tutor Billing file \(sourceFileName) not reset"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: Could not get File ID for Tutor Billing Data File \(sourceFileName)"
			}
		} catch {
			logMessage = "ERROR: Error resetting Tutor Billing spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Delete the second year Tutor Billing spreadsheet
		deleteFileName = PgmConstants.tutorBillingTestFileName2
		do {
			(fileIDResult, deleteFileID) = try await getFileID(fileName: deleteFileName)
			deleteResult = try await deleteFile(fileID: deleteFileID)
			if deleteResult {
				logMessage = "INFO: \(deleteFileName) deleted"
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				logMessage = "ERROR: \(deleteFileName) not deleted"
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			resetResult = false
			logMessage = "ERROR: could not delete test Tutor Billing File: \(deleteFileName) resetting test files"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the initialization Tutor Billing spreadsheet
		sourceFileName = PgmConstants.initializationTestTutorBillingFile2Name
		copyFileName = deleteFileName
		
		do {
			(fileIDResult, sourceFileID) = try await getFileID(fileName: sourceFileName)
			if fileIDResult {
				
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: sourceFileID, newFileName: copyFileName)
				if copyFileResult {
					logMessage = "INFO: Tutor Billing initialization file copied to file: \(copyFileName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				} else {
					resetResult = false
					logMessage = "ERROR: Tutor Billing Data file \(sourceFileName) not reset"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: Could not get File ID for Initialization Tutor Billing File \(sourceFileName)"
			}
		} catch {
			logMessage = "ERROR: Error resetting Tutor Billing spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Delete the first year Student Billing spreadsheet
		deleteFileName = PgmConstants.studentBillingTestFileName1
		do {
			(fileIDResult, deleteFileID) = try await getFileID(fileName: deleteFileName)
			deleteResult = try await deleteFile(fileID: deleteFileID)
			if deleteResult {
				logMessage = "INFO: \(deleteFileName) deleted"
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				logMessage = "ERROR: \(deleteFileName) not deleted"
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			resetResult = false
			logMessage = "ERROR: could not delete test Student Billing File: \(deleteFileName) resetting test files"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the initialization Student Billing spreadsheet
		sourceFileName = PgmConstants.initializationTestStudentBillingFile1Name
		copyFileName = deleteFileName
		
		do {
			(fileIDResult, sourceFileID) = try await getFileID(fileName: sourceFileName)
			if fileIDResult {
				
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: sourceFileID, newFileName: copyFileName)
				if copyFileResult {
					logMessage = "INFO: Student Billing initialization file copied to file: \(copyFileName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				} else {
					resetResult = false
					logMessage = "ERROR: Student Billing file \(sourceFileName) not reset"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: Could not get File ID for Initialization Student Billing File \(sourceFileName)"
			}
		} catch {
			logMessage = "ERROR: Error resetting Student Billing spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Delete the second year Student Billing spreadsheet
		deleteFileName = PgmConstants.studentBillingTestFileName2
		do {
			(fileIDResult, deleteFileID) = try await getFileID(fileName: deleteFileName)
			deleteResult = try await deleteFile(fileID: deleteFileID)
			if deleteResult {
				logMessage = "INFO: \(deleteFileName) deleted"
				await AppLogger.shared.log(logMessage, level: .info)
			} else {
				logMessage = "ERROR: \(deleteFileName) not deleted"
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			resetResult = false
			logMessage = "ERROR: could not delete test Student Billing File: \(deleteFileName) resetting test files"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		// Copy the initialization Student Billing spreadsheet
		sourceFileName = PgmConstants.initializationTestStudentBillingFile2Name
		copyFileName = deleteFileName
		
		do {
			(fileIDResult, sourceFileID) = try await getFileID(fileName: sourceFileName)
			if fileIDResult {
				
				(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: sourceFileID, newFileName: copyFileName)
				if copyFileResult {
					logMessage = "INFO: Student Billing initialization file copied to file: \(copyFileName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .info)
				} else {
					resetResult = false
					logMessage = "ERROR: Student Billing file \(sourceFileName) not reset"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: Could not get File ID for Initialization Student Billing File \(sourceFileName)"
			}
		} catch {
			logMessage = "ERROR: Error resetting Student Billing spreadsheet \(copyFileName), error: \(error.localizedDescription)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
	return (resetResult, logMessage)
	}
	
	// Copies a known template file (by File ID) to create a new file, then
	/// assigns the standard set of Google Drive "writer" permissions
	/// (Russell, WriteSeattle, Stephen, the service account) — plus an optional
	/// extra recipient (e.g. a Tutor's own email, for Timesheets).
	///
	/// - Parameters:
	///   - templateFileID: Drive File ID of the template to copy.
	///   - newFileName: name to give the newly created file.
	///   - extraEmailAddress: an additional email to grant "writer" access to,
	///     on top of the standard four (used by Timesheets for the Tutor's own
	///     email; omit for files that only need the standard recipients).
	///   - folderName: name of the Google Drive folder to create the new file in
	///     (the folder is created in My Drive if it doesn't exist). If omitted,
	///     Drive places the new file in the same folder as the template.
	///   - subfolderName: name of a subfolder inside `folderName` to create the
	///     new file in (created if it doesn't exist). Treated as an error if
	///     `folderName` isn't also given.
	/// - Returns: `success` (false if the folder lookup/creation, copy or
	///   permission step failed), `newFileID` (the Drive File ID of the new file, if created),
	///   and `logMessage` describing the outcome.
	@MainActor
	private func copyTemplateAndAssignPermissions(
		templateFileID: String,					// Template file to use to create the new file from
		newFileName: String,					// Name of the new file
		extraEmailAddress: String? = nil,			// An additional email address (usually the Tutor for their new Timesheet) to give Google Drive access permission to
		folderName: String? = nil,				// Name of Google Drive folder to place the new file
		subfolderName: String? = nil,				// Name of the Google Drive subfolder to place the new file
		sendNotificationFlag: Bool				// Whether to notify the people given access to the new file
	) async throws -> (success: Bool, newFileID: String?, logMessage: String) {

		var logMessage: String
		
		// Find (or create) the destination folder and subfolder, if one was specified
		var destinationFolderID: String? = nil
		if let folderName {
			let (folderFound, folderID) = try await getOrCreateFolderID(folderName: folderName)
			guard folderFound else {
				let logMessage = "ERROR: Could not find or create Google Drive folder: \(folderName) to create: \(newFileName)\n"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return (false, nil, logMessage)
			}
			destinationFolderID = folderID

			if let subfolderName {
				let (subfolderFound, subfolderID) = try await getOrCreateFolderID(folderName: subfolderName, parentFolderID: folderID)
				guard subfolderFound else {
					let logMessage = "ERROR: Could not find or create Google Drive subfolder: \(folderName)/\(subfolderName) to create: \(newFileName)\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
					return (false, nil, logMessage)
				}
				destinationFolderID = subfolderID
			}
		} else if let subfolderName {
			let logMessage = "ERROR: Subfolder \(subfolderName) specified without a parent folder to create: \(newFileName)\n"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return (false, nil, logMessage)
		}

		let (copyResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: templateFileID, newFileName: newFileName, parentFolderID: destinationFolderID)
		
		guard copyResult else {
			let logMessage = "ERROR: Could not copy template to create: \(newFileName)\n"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return (false, nil, logMessage)
		}
		
		guard let copyFileID else {
			let logMessage = "ERROR: Nil FileID from copyGoogleDriveFile when creating: \(newFileName)\n"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return (false, nil, logMessage)
		}
		
		logMessage = "INFO: File: \(newFileName) copied from template"
		print(logMessage)
		await AppLogger.shared.log(logMessage, level: .info)
		
		do {
			if let extraEmailAddress {
				try await addPermissionToFile(fileID: copyFileID, role: "writer", type: "user", emailAddress: extraEmailAddress, sendNotificationEmail: sendNotificationFlag)
			}
			try await addPermissionToFile(fileID: copyFileID, role: "writer", type: "user", emailAddress: PgmConstants.russellEmail, sendNotificationEmail: sendNotificationFlag)
			try await addPermissionToFile(fileID: copyFileID, role: "writer", type: "user", emailAddress: PgmConstants.writeSeattleEmail, sendNotificationEmail: sendNotificationFlag)
//			try await addPermissionToFile(fileID: copyFileID, role: "writer", type: "user", emailAddress: PgmConstants.stephenEmail, sendNotificationEmail: sendNotificationFlag)
//			try await addPermissionToFile(fileID: copyFileID, role: "writer", type: "user", emailAddress: PgmConstants.aiServiceAccountEmail, sendNotificationEmail: sendNotificationFlag)
			let logMessage = "INFO: Access permissions added to new file: \(newFileName)\n"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .info)
			return (true, copyFileID, logMessage)
		} catch {
			// NOTE: preserved from the original — a permission failure is
			// logged but does NOT flip `success` to false, and is logged at
			// .info level despite the "ERROR:" text. Flagging this in case it
			// wasn't intentional; see my note below.
			let logMessage = "ERROR: Could not add Google Drive permissions to \(newFileName)\n"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .info)
			return (true, copyFileID, logMessage)
		}
	}
	
	/// Creates a new spreadsheet by copying a named template file, but only if
	/// a file named `newFileName` doesn't already exist. Combines the
	/// "does it already exist" and "find the template" checks with
	/// `copyTemplateAndAssignPermissions` above.
	@MainActor
	private func createFileFromTemplate(
		newFileName: String,
		templateFileName: String,
		folderName: String
		) async throws -> (success: Bool, newFileID: String?, logMessage: String) {
		var sendNotificationFlag: Bool
		
		do {
			// Ensure the target file doesn't already exist
			let (fileFound, _) = try await getFileID(fileName: newFileName)
			if fileFound {
				let logMessage = "ERROR: \(newFileName) already exists\n"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return (false, nil, logMessage)
			}
			
			// Ensure the template file exists and get its FileID
			let (templateFound, templateFileID) = try await getFileID(fileName: templateFileName)
			guard templateFound else {
				let logMessage = "ERROR: Could not get File ID for Template File: \(templateFileName)\n"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return (false, nil, logMessage)
			}
			
			if runMode == .test {
				sendNotificationFlag = false
			} else {
				sendNotificationFlag = true
			}
			return try await copyTemplateAndAssignPermissions(templateFileID: templateFileID, newFileName: newFileName, folderName: folderName, sendNotificationFlag: sendNotificationFlag)
			
		} catch {
			let logMessage = "ERROR: could not get FileID generating: \(newFileName)\n"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return (false, nil, logMessage)
		}
	}
	
	// This function creates a new Timesheet for a specific Tutor for a specific year from a template
	// - check that the Timesheet doesn't already exist
	// - check that the timesheet template file does exist
	// - calls copyTemplateAndAssignPermissions()
	// - write the Tutor name in the new Timesheet
	// - put the TutorDetails FileID in the new Timesheet
	// - put the new Timesheet FileID in the Tutor Details sheet
	
	@MainActor func createTimesheetFile(templateFileName: String, timesheetYear: String, tutorName: String, tutorEmail: String, referenceData: ReferenceData) async throws -> (Bool, String?, String) {
		var logMessage = ""
		var newTimesheetFileID: String?
		var timesheetSuccess: Bool = true
		var googleDriveFolder: String
		
		let newTimesheetFileName = "Timesheet " + timesheetYear + " " + tutorName
		
		do {
			// Ensure the target file doesn't already exist
			let (fileFound, _) = try await getFileID(fileName: newTimesheetFileName)
			if fileFound {
				let logMessage = "ERROR: \(newTimesheetFileName) already exists\n"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return (false, nil, logMessage)
			}
			
			// Ensure the template file exists and get its FileID
			let (templateFound, templateFileID) = try await getFileID(fileName: templateFileName)
			guard templateFound else {
				let logMessage = "ERROR: Could not get File ID for Template File: \(templateFileName)\n"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				return (false, nil, logMessage)
			}
			do {
				var sendNotificationFlag: Bool
				if runMode == .test {
					sendNotificationFlag = false
				} else {
					sendNotificationFlag = true
				}
				// Copy the template file to create the new Timesheet file and assign permissions
				(timesheetSuccess, newTimesheetFileID, logMessage) =  try await copyTemplateAndAssignPermissions(templateFileID: templateFileID, newFileName: newTimesheetFileName, extraEmailAddress: tutorEmail, folderName: runMode.timesheetFolderLocation, subfolderName: timesheetYear, sendNotificationFlag: sendNotificationFlag)
				
				guard timesheetSuccess, let newTimesheetFileID else {
					// Failure already logged inside the helper above.
					return(false, nil,"ERROR: Could not create new Timesheet for tutor: \(tutorName)")
				}
				
				// Write the Tutor Name in the new Timesheet
				do {
					try await writeSheetCells(
						fileID: newTimesheetFileID,
						range: PgmConstants.timesheetTutorNameCell,
						values: [[tutorName]],
						logNote: "Tutor Name in new Timesheet")
						
					logMessage = "INFO: Tutor name: \(tutorName) written into Timesheet"
					await AppLogger.shared.log(logMessage, level: .info)
					
				} catch {
					logMessage += "ERROR: can not write Tutor Name into new Tutor Timesheet\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
					return(false, newTimesheetFileID, logMessage)
				}
				
				// The new Timesheet needs the FileID of the Tutor Details file in the refData sheet
				let updateValues = [[tutorDetailsFileID]]
				let range = PgmConstants.timesheetDetailsFileIDCell
				do {
					let writeResult = try await writeSheetCells(fileID: newTimesheetFileID, range: range, values: updateValues, logNote: "Tutor Details FileID in Timesheet RefData")
					print("INFO: Updating Tutor Details File ID in new Timesheet for \(tutorName)")
					if !writeResult {
						logMessage = "ERROR: Adding Tutor Details File ID to Timesheet RefData for \(tutorName)\n"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
						return(false, newTimesheetFileID, logMessage)
					} else {
						logMessage = "INFO: Added Tutor Details File ID to Timesheet RefData for \(tutorName)\n"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .info)
						timesheetSuccess = true
					}
				} catch {
					logMessage = "ERROR: Adding Tutor Details File ID to Timesheet RefData for \(tutorName)\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
					return(false, newTimesheetFileID, logMessage)
				}
				
				// Update the Timesheet FileID in the Tutor Details sheet for the Tutor
				let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
				if tutorFound {
					referenceData.tutors.tutorsList[tutorNum].timesheetFileID = newTimesheetFileID
					let saveResult = await referenceData.tutors.saveTutorData()
					if !saveResult {
						logMessage = "ERROR: Could not save Tutor data for Tutor \(tutorName) after updating Timesheet FileID"
						await AppLogger.shared.log(logMessage, level: .error)
					} else {
						logMessage = "INFO: Tutor: \(tutorName) Timesheet FileID updated in Tutor Details File"
						await AppLogger.shared.log(logMessage, level: .info)
					}
				} else {
					logMessage = "ERROR: Tutor: \(tutorName) not found updating Timesheet FileID in Tutor Details File"
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} catch {
				logMessage = "ERROR: Could not create new Timesheet or assign permissions for Tutor: \(tutorName)"
				await AppLogger.shared.log(logMessage, level: .error)
			}
			
		} catch {
			let logMessage = "ERROR: could not get FileID generating: \(newTimesheetFileName)\n"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return (false, nil, logMessage)
		}
		return(timesheetSuccess, newTimesheetFileID, logMessage)
	}
	
	// MARK: - Main function
	
	// This function generates the next year's spreadsheets (Tutor Billing, Student Billing) and a new Timesheet for each Tutor
	//
	@MainActor func generateNewYearFiles(referenceData: ReferenceData) async throws -> (Bool, String) {
		var generateResult: Bool = true
		var logMessage: String = ""
		
		guard let yearInt = Calendar.current.dateComponents([.year], from: Date()).year else {
			return (generateResult, logMessage)
		}
		
		let nextYear = String(yearInt + 1)
		
		// Tutor Billing — Production
		let (tutorBillingProdSuccess, _, tutorBillingProdLog) = try await createFileFromTemplate(
			newFileName: PgmConstants.tutorBillingProdFileNamePrefix + nextYear,
			templateFileName: PgmConstants.billedTutorTemplateFileName,
			folderName: PgmConstants.productionFileFolderName
		)
		if !tutorBillingProdSuccess { generateResult = false }
		logMessage += tutorBillingProdLog
		
		// Tutor Billing — Test
		let (tutorBillingTestSuccess, _, tutorBillingTestLog) = try await createFileFromTemplate(
			newFileName: PgmConstants.tutorBillingTestFileNamePrefix + nextYear,
			templateFileName: PgmConstants.billedTutorTemplateFileName,
			folderName: PgmConstants.testFileFolderName
		)
		if !tutorBillingTestSuccess { generateResult = false }
		logMessage += tutorBillingTestLog
		
		// Student Billing — Production
		let (studentBillingProdSuccess, _, studentBillingProdLog) = try await createFileFromTemplate(
			newFileName: PgmConstants.studentBillingProdFileNamePrefix + nextYear,
			templateFileName: PgmConstants.billedStudentTemplateFileName,
			folderName: PgmConstants.productionFileFolderName
			
		)
		if !studentBillingProdSuccess { generateResult = false }
		logMessage += studentBillingProdLog
		
		// Student Billing — Test
		let (studentBillingTestSuccess, _, studentBillingTestLog) = try await createFileFromTemplate(
			newFileName: PgmConstants.studentBillingTestFileNamePrefix + nextYear,
			templateFileName: PgmConstants.billedStudentTemplateFileName,
			folderName: PgmConstants.testFileFolderName
		)
		if !studentBillingTestSuccess { generateResult = false }
		logMessage += studentBillingTestLog
		
		// Create a Timesheet for each active Tutor for the year
		var currentYear: String
		if runMode == .prod {
			let formatter = DateFormatter()
			formatter.setLocalizedDateFormatFromTemplate("YYYY")
			currentYear = formatter.string(from: Date.now)
		} else {
			currentYear = "2027"
		}
		
		for tutor in referenceData.tutors.tutorsList
		where tutor.tutorStatus == .TutorUnassigned || tutor.tutorStatus == .TutorAssigned {
			let (addResult, newTimesheetFileID, logMessage) = try await createTimesheetFile(templateFileName: runMode.timesheetTemplateFileName, timesheetYear: currentYear, tutorName: tutor.tutorName, tutorEmail: tutor.tutorEmail, referenceData: referenceData)
			
		}
		
		return (generateResult, logMessage)
	}
	
	// This function updates the Timesheet FileIDs in the Tutor Details sheet for each Tutor
	@MainActor func updateTimesheetFileIDs(referenceData: ReferenceData) async -> (Bool, String) {
		var updateResult: Bool = true
		var logMessage: String = ""
		
		let (currentMonth, currentMonthYear) = getCurrentMonthYear()
		
		var tutorNum = 0
		let tutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < tutorCount {
			if referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorDeleted && referenceData.tutors.tutorsList[tutorNum].tutorStatus != .TutorSuspended {
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				let timesheetFileName = "Timesheet " + currentMonthYear + " " + tutorName
				do {
					let (getResult, timesheetFileID) = try await getFileID(fileName: timesheetFileName)
					if getResult {
						let range = tutorName + PgmConstants.tutorDataTimesheetFileIDRange
						let updateValues = [[timesheetFileID]]
						do {
							updateResult = try await writeSheetCells(fileID: tutorDetailsFileID, range: range, values: updateValues, logNote: "Timesheet FileID")
							print("INFO: Updating Timesheet File ID for \(tutorName) in Tutor Details spreadsheet")
						} catch {
							updateResult = false
							logMessage += "ERROR: Updating timesheet file ID for \(tutorName)\n"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					} else {
						logMessage += "ERROR: Getting timesheet file ID for \(tutorName) updating Timesheet File IDs, Tutor skipped\n"
						await AppLogger.shared.log(logMessage, level: .error)
					}
				} catch {
						updateResult = false
						logMessage += "ERROR: Getting file ID for \(timesheetFileName)\n"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
				}
			}
			
			tutorNum += 1
		}
		
		return(updateResult, logMessage)
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
		var logMessage: String
		
		// Get the fileID of the Billed Tutor spreadsheet for the year containing the month's Billed Tutor data
		do {
			(fileIdResult, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			// Read the data from the Billed Tutor spreadsheet for the month into a new TutorBillingMonth object
			if fileIdResult {
				let readResult = await tutorBillingMonth.getTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID, loadValidatedData: loadValidatedData)
				if !readResult {
					logMessage = "ERROR: Could not load Tutor Billing Data for \(monthName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: could not get FileID for file: \(tutorBillingFileName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			logMessage = "ERROR: Could not get FileID for file: \(tutorBillingFileName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
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
		var logMessage: String
		
		// Get the fileID of the Billed Student spreadsheet for the year containing the month's Billed Student data
		do {
			(fileIdResult, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
			// Read the data from the Billed Student spreadsheet for the month into a new StudentBillingMonth object
			if fileIdResult {
				let readResult = await studentBillingMonth.getStudentBillingMonth(monthName: monthName, studentBillingFileID: studentBillingFileID, loadValidatedData: loadValidatedData)
				if !readResult {
					logMessage = "ERROR: Could not load Student Billing Data for \(monthName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR: could not get FileID for file: \(studentBillingFileName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} catch {
			logMessage = "ERROR: Could not get FileID for file: \(studentBillingFileName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		return(studentBillingMonth)
	}
	

	
}
