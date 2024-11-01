//
//  ValidateSystemVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-28.
//
import Foundation

class SystemVM {
	
	
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
			
			
		}
		
// Check that the number of Services in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalServices = 0
		var activeServices = 0
		var deletedServices = 0
		
		var serviceNum = 0
		let serviceCount = referenceData.services.servicesList.count
		while studentNum < studentCount {
			
			
		}

		
// Check that the number of Locations in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalLocations = 0
		var activeLocations = 0
		var deletedLocations = 0
		
		var locationNum = 0
		let locationCount = referenceData.locations.locationsList.count
		while locationNum < locationCount {
			
			
		}

		
// Check that the number of Tutors in the Reference Data list (Total/Active/Deleted) matches the counts in the Reference Data
		var totalTutors = 0
		var activeTutors = 0
		var deletedTutors = 0
		
		var tutorNum = 0
		let tutorCount = referenceData.tutors.tutorsList.count
		while tutorNum < tutorCount {
			
			
		}


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
