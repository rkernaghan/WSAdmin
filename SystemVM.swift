//
//  ValidateSystemVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-28.
//
import Foundation

@Observable class SystemVM {
	
	
	func validateSystem(referenceData: ReferenceData) async {
		print("Validating System - Stand By for Adventure!")

// Check if any Students assigned to more than one Tutor

		
// Validate that there is one Tutor Details sheet for each active (non-deleted) Tutor

		
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
			switch referenceData.students.studentsList[studentNum].studentStatus {
			case "Unassigned", "Assigned", "Suspended":
				activeStudents += 1
			case "Deleted":
				deletedStudents += 1
			default:
				print("Invalid Status for Student \(referenceData.students.studentsList[studentNum].studentName)")
			}
			totalStudents += 1
			studentNum += 1
		}
		print("Total Students \(totalStudents), Active Students \(activeStudents), Deleted Students \(deletedStudents)")

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
		print("Total Services \(totalServices), Active Services \(activeServices), Deleted Services \(deletedServices)")
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
				print("Invalid Location Status for Location \(referenceData.locations.locationsList[locationNum].locationName)")
			}
			locationStudents += referenceData.locations.locationsList[locationNum].locationStudentCount
			totalLocations += 1
			locationNum += 1
		}
		print("Total Locations \(totalLocations), Active Locations \(activeLocations), Deleted Locations \(deletedLocations)")
		
		if locationStudents != totalStudents {
			print("Validation Error: Counts of Location Students \(locationStudents) does not match actual count of Students in Reference Data Locations list of \(totalStudents)")
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
			switch referenceData.tutors.tutorsList[tutorNum].tutorStatus {
			case "Unassigned", "Assigned", "Suspended":
				activeTutors += 1
			case "Deleted":
				deletedTutors += 1
			default:
				print("Invalid Tutor Status for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
			}
			do {
				sheetNum = try await getSheetIdByName(spreadsheetId: tutorDetailsFileID, sheetName: referenceData.tutors.tutorsList[tutorNum].tutorName )
			} catch {
				print("Validation Error: could not get Tutor Details sheet ID for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
			}
			if sheetNum == nil {
				print("Validation Error: could not get Tutor Details sheet ID for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
			}
			totalTutors += 1
			tutorNum += 1
		}
		print("Total Tutors \(totalTutors), Active Tutors \(activeTutors), Deleted Tutors \(deletedTutors)")
		
		print("Total Tutors \(totalTutors), Active Tutors \(activeTutors), Deleted Tutors \(deletedTutors)")
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
		

// Validate that the Student names in the Master Reference worksheet match the tutor names in the Student Billing spreadsheet
		

// Validate that the sum of the Tutors total billing equals Student total billing equals City total billing


// Validate master reference spreadsheet file key matches the import file keys in each timesheet and timesheet template



	}
	
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
			let (tutorFileFound, tutorBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
			try await copyGoogleDriveFile(sourceFileId: tutorBillingFileID, newFileName: tutorBillingFileName + " Backup " + backupDate)
			print("Billed Tutor spreadsheet copied to file: \(tutorBillingFileName + " Backup " + backupDate)")
			
// Copy the Student Billing spreadsheet
			studentBillingFileName = studentBillingFileNamePrefix + currentYear
			let (studentFileFound, studentBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
			try await copyGoogleDriveFile(sourceFileId: studentBillingFileID, newFileName: studentBillingFileName + " Backup " + backupDate)
			print("Billed Student spreadsheet copied to file: \(studentBillingFileName + " Backup " + backupDate)")
		} catch {
			print("ERROR: Could not backup application files")
		}
		
	}
	
}
