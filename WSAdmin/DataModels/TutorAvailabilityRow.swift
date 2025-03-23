//
//  TutorAvailabilityRow.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2025-03-22.
//


import Foundation

// FinanceSummaryRow is a class to hold a financial summary for one month's billing. Used to hold data for display in the Finance Summary view.
//
class TutorAvailabilityRow: Identifiable {
	var tutorName: String
	var tutorAvailability: String
	var tutorStatus: String
	var tutorStudentCount: Int
	var mondayAvailability: String
	var mondayLocation: String
	var tuesdayAvailability: String
	var tuesdayLocation: String
	var wednesdayAvailability: String
	var wednesdayLocation: String
	var thursdayAvailability: String
	var thursdayLocation: String
	var fridayAvailability: String
	var fridayLocation: String
	var saturdayAvailability: String
	var saturdayLocation: String
	var sundayAvailability: String
	var sundayLocation: String
	let id = UUID()
	
	init(tutorName: String, tutorAvailability: String, tutorStatus: String, tutorStudentCount: Int, mondayAvailability: String, mondayLocation: String, tuesdayAvailability: String, tuesdayLocation: String, wednesdayAvailability: String, wednesdayLocation: String, thursdayAvailability: String, thursdayLocation: String, fridayAvailability: String, fridayLocation: String, saturdayAvailability: String, saturdayLocation: String, sundayAvailability: String, sundayLocation: String) {
		self.tutorName = tutorName
		self.tutorAvailability = tutorAvailability
		self.tutorStatus = tutorStatus
		self.tutorStudentCount = tutorStudentCount
		self.mondayAvailability = mondayAvailability
		self.mondayLocation = mondayLocation
		self.tuesdayAvailability = tuesdayAvailability
		self.tuesdayLocation = tuesdayLocation
		self.wednesdayAvailability = wednesdayAvailability
		self.wednesdayLocation = wednesdayLocation
		self.thursdayAvailability = thursdayAvailability
		self.thursdayLocation = thursdayLocation
		self.fridayAvailability = fridayAvailability
		self.fridayLocation = fridayLocation
		self.saturdayAvailability = saturdayAvailability
		self.saturdayLocation = saturdayLocation
		self.sundayAvailability = sundayAvailability
		self.sundayLocation = sundayLocation
	}
	
}
