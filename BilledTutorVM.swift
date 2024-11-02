//
//  BilledTutorVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-02.
//
import Foundation

@Observable class BilledTutorVM {
	
	func buildBilledTutorMonth(monthName: String, yearName: String) async -> TutorBillingMonth {
		var tutorBillingFileName = tutorBillingFileNamePrefix + yearName
		var result: Bool = true
		var tutorBillingFileID = ""
		
		let tutorBillingMonth = TutorBillingMonth()
		
		// Get the fileID of the previous month Billed Tutor spreadsheet for the year
		do {
			(result, tutorBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
		} catch {
			print("Could not get FileID for file: \(tutorBillingFileName)")
		}
		// Read the data from the Billed Tutor spreadsheet for the previous month
		await tutorBillingMonth.loadTutorBillingMonthAsync(monthName: monthName, tutorBillingFileID: tutorBillingFileID)
		
		return(tutorBillingMonth)
	}
	
}
