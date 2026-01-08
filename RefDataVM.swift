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
		
		// Read in the counts of Tutors, Students, Locations and Services from the Reference Data file in order to know how many rows of each to read in
		// If the read succeeds, read in the Tutors, Students, Locations and Services 
		let fetchCountsFlag = await referenceData.dataCounts.fetchDataCounts( referenceData: referenceData )
		if !fetchCountsFlag {
			completionResult = false
		} else {
			if referenceData.dataCounts.isDataCountsLoaded {
				
				let fetchTutorsResult = await referenceData.tutors.fetchTutorData( tutorCount: referenceData.dataCounts.totalTutors)
				
				let fetchStudentsResult = await referenceData.students.fetchStudentData( studentCount:  referenceData.dataCounts.totalStudents)
				
				let fetchLocationsResult = await referenceData.locations.fetchLocationData( locationCount: referenceData.dataCounts.totalLocations)
				
				let fetchServicesResult = await referenceData.services.fetchServiceData( serviceCount: referenceData.dataCounts.totalServices)
				
				let buildResult = buildTutorStudentBilledDate(referenceData: referenceData)
				
				if !fetchTutorsResult || !fetchStudentsResult || !fetchLocationsResult || !fetchServicesResult {
					completionResult = false
				}
			}
			
		}
		return(completionResult)
	}
	
}

func buildTutorStudentBilledDate(referenceData: ReferenceData) -> Bool {
	var buildResult: Bool = true
	
	var tutorNum = 0
	while tutorNum < referenceData.tutors.tutorsList.count {
		
		var studentNum = 0
		while studentNum < referenceData.tutors.tutorsList[tutorNum].tutorStudents.count {
			
			let studentKey = referenceData.tutors.tutorsList[tutorNum].tutorStudents[studentNum].studentKey
			
			let (studentFound, studentIndex) = referenceData.students.findStudentByKey(studentKey: studentKey)
			
			if studentFound {
				referenceData.tutors.tutorsList[tutorNum].tutorStudents[studentNum].lastBilledDate = referenceData.students.studentsList[studentIndex].studentLastBilledDate
			}
			
			studentNum += 1
		}
		
		tutorNum += 1
	}
	
	return (buildResult)
	
}

