//
//  RefDataModel.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-02.
//

import Foundation

@Observable class RefDataVM  {
    
//
// This function loads the main reference data from the ReferenceData sheet.
// 1) Call Google Drive to search for for the Tutor's timesheet file name in order to get the file's Google File ID
// 2) If only a single file is retreived, call loadStudentServices to retrieve the Tutor's assigned Student list, Services list and Notes options as well as the Tutor service history for the month
//
  
	func loadReferenceData(referenceData: ReferenceData) async -> Bool{
		var completionResult: Bool = true
		
		let fetchCountsFlag = await referenceData.dataCounts.fetchDataCounts( referenceData: referenceData )
		if !fetchCountsFlag {
			completionResult = false
		}
		
		if referenceData.dataCounts.isDataCountsLoaded {
			let fetchTutorsResult = await referenceData.tutors.fetchTutorData( tutorCount: referenceData.dataCounts.totalTutors)
			let fetchStudentsResult = await referenceData.students.fetchStudentData( studentCount:  referenceData.dataCounts.totalStudents)
			let fetchLocationsResult = await referenceData.locations.fetchLocationData( locationCount: referenceData.dataCounts.totalLocations)
			let fetchServicesResult = await referenceData.services.fetchServiceData( serviceCount: referenceData.dataCounts.totalServices)
			
			if !fetchTutorsResult || !fetchStudentsResult || !fetchLocationsResult || !fetchServicesResult {
				completionResult = false
			}
			
		}
		return(completionResult)
	}
	
}
