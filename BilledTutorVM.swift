//
//  BilledTutorVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-02.
//
import Foundation

@Observable class BilledTutorVM {
//
//			NOT USED??
	
// This function creates a new Billed Tutor object for a month, reads in the data for that month and returns that new Billed Tutor object
//		monthName: the month to load the Billed Tutor data for
//		yearName: the year of the month to load the Billed Tutor data for
//
	func buildBilledTutorMonthxx(monthName: String, yearName: String) async -> TutorBillingMonth {
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
	
}
