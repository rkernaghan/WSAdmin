//
//  location.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

// The data and functions for an individual Location (city)
//
@Observable class Location: Identifiable {
	var locationKey: String				// Unique key for the Location
	var locationName: String			// Name of the Location
	var locationMonthRevenue: Double			// Total revenue for the Location (not used)
	var locationTotalRevenue: Double			// Total revenue for the Location since Location created (or system initiated)
	var locationStudentCount: Int			// Count of current Students from this Location\
	var locationStatus: String			// Status of the Location
	let id = UUID()
	
	init(locationKey: String, locationName: String, locationMonthRevenue: Double, locationTotalRevenue: Double, locationStudentCount: Int, locationStatus: String) {
		self.locationKey = locationKey
		self.locationName = locationName
		self.locationMonthRevenue = locationMonthRevenue
		self.locationTotalRevenue = locationTotalRevenue
		self.locationStudentCount = locationStudentCount
		self.locationStatus = locationStatus
	}
	
	// This function changes the Location Name attribute on a Location object
	func setLocationName(locationName: String) {
		self.locationName = locationName
	}
	
	// This function changes a Location's Status attribute to "Deleted" and sets the Location's End Date
	func markDeleted() {
		locationStatus = "Deleted"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
//        serviceEndDate = dateFormatter.string(from: Date())
	}
	
	// This function changes a Location's Status attribute to "Active"
	func markUndeleted() {
		locationStatus = "Active"
//		let dateFormatter = DateFormatter()
//		dateFormatter.dateFormat = "yyyy/MM/dd"
//        serviceEndDate = dateFormatter.string(from: Date())
	}
	
	// This function increases the count of Students at this Location (when a new Student is added)
	func increaseStudentCount() {
		self.locationStudentCount += 1
	}
	
	// This function decreases the count of Students at this Location (when Student is deleted)
	func decreaseStudentCount() {
		self.locationStudentCount -= 1
	}
	
	// This function reverses this month's billing data from the Location billing totals (when a Student
	// at this Location is being billed again this month to avoid double counting).
	func resetBillingStats(monthRevenue: Double) {
		self.locationMonthRevenue -= monthRevenue
		self.locationTotalRevenue -= monthRevenue
	}
	
}
