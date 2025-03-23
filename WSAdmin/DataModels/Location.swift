//
//  location.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class Location: Identifiable {
	var locationKey: String
	var locationName: String
	var locationMonthRevenue: Float
	var locationTotalRevenue: Float
	var locationStudentCount: Int
	var locationStatus: String
	let id = UUID()
	
	init(locationKey: String, locationName: String, locationMonthRevenue: Float, locationTotalRevenue: Float, locationStudentCount: Int, locationStatus: String) {
		self.locationKey = locationKey
		self.locationName = locationName
		self.locationMonthRevenue = locationMonthRevenue
		self.locationTotalRevenue = locationTotalRevenue
		self.locationStudentCount = locationStudentCount
		self.locationStatus = locationStatus
	}
	
	func updateLocation(locationName: String) {
		self.locationName = locationName
	}
	
	func markDeleted() {
		locationStatus = "Deleted"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
//        serviceEndDate = dateFormatter.string(from: Date())
	}
	
	func markUndeleted() {
		locationStatus = "Active"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd"
//        serviceEndDate = dateFormatter.string(from: Date())
	}
	
	func increaseStudentCount() {
		self.locationStudentCount += 1
	}
	
	func decreaseStudentCount() {
		self.locationStudentCount -= 1
	}
	
	func resetBillingStats(monthRevenue: Float) {
		self.locationMonthRevenue -= monthRevenue
		self.locationTotalRevenue -= monthRevenue
	}
	
}
