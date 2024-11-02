//
//  BilledStudentVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-02.
//
import Foundation

@Observable class BilledStudentVM {
	
	func buildBilledStudentMonth(monthName: String, yearName: String) async -> StudentBillingMonth {
		var studentBillingFileName = studentBillingFileNamePrefix + yearName
		var result: Bool = true
		var studentBillingFileID = ""
		
		let studentBillingMonth = StudentBillingMonth()
		
		// Get the fileID of the previous month Billed Student spreadsheet for the year
		do {
			(result, studentBillingFileID) = try await getFileIDAsync(fileName: studentBillingFileName)
		} catch {
			print("Could not get FileID for file: \(studentBillingFileName)")
		}
		// Read the data from the Billed Student spreadsheet for the previous month
		await studentBillingMonth.loadStudentBillingMonthAsync(monthName: monthName, studentBillingFileID: studentBillingFileID)
		
		return(studentBillingMonth)
	}
	
}

