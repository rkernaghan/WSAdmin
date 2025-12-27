//
//  StudentMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@Observable class StudentMgmtVM  {
    
	func addNewStudent(referenceData: ReferenceData, studentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactZipCode: String, location: String) async -> (Bool, String) {
		var completionFlag: Bool = true
		var completionMessage: String = ""
		
		var result: Bool = true
		var studentBillingFileID: String = ""
		
		referenceData.students.addNewStudent(studentName: studentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactZipCode: contactZipCode, location: location, referenceData: referenceData)
		
		let saveStudentsResult = await referenceData.students.saveStudentData()
		if !saveStudentsResult {
			completionFlag = false
			completionMessage = "Critical Error: could not save Student Data to ReferenceData spreadsheet when adding new Student"
		} else {
			referenceData.dataCounts.increaseTotalStudentCount()
			let saveCountsFlag = await referenceData.dataCounts.saveDataCounts()
			if !saveCountsFlag {
				completionFlag = false
				completionMessage = "Critical Error: could not save Data Counts to ReferenceData spreadsheet when adding new Student"
			} else {
				
				let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: location)
				referenceData.locations.locationsList[locationNum].increaseStudentCount()
				let saveLocationsResult = await referenceData.locations.saveLocationData()
				if !saveLocationsResult {
					completionFlag = false
					completionMessage = "Critical Error: could not save Data Counts to ReferenceData spreadsheet when adding new Student"
				} else {
					
					let (prevMonthName, billingYear) = getPrevMonthYear()
					let studentBillingFileName = studentBillingFileNamePrefix + billingYear
					
					let studentBillingMonth = StudentBillingMonth(monthName: prevMonthName)
					
					// Get the File ID of the Billed Student spreadsheet for the year
					do {
						(result, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
						if !result {
							completionFlag = false
							completionMessage = "Error: Could not get fileID for file: \(studentBillingFileName) when adding new Student"
						} else {
							// Read in the Billed Students for the previous month
							let getStudentBillingFlag = await studentBillingMonth.getStudentBillingMonth(monthName: prevMonthName, studentBillingFileID: studentBillingFileID, loadValidatedData: false)
							if !getStudentBillingFlag {
								completionFlag = false
								completionMessage = "Error: Could not load Student Billing Month: \(studentBillingFileName) when adding new Student"
							} else {
								// Add the new Student to Billed Student list for the month
								let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByStudentName(billedStudentName: studentName)
								if billedStudentFound == false {
									studentBillingMonth.addNewBilledStudent(studentName: studentName)
								}
								// Save the updated Billed Student list for the month
								let saveStudentBillingFlag = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: studentBillingFileID, billingMonth: prevMonthName, saveValidatedStudentData: false)
								if !saveStudentBillingFlag {
									completionFlag = false
									completionMessage = "Error: Could not save Student Billing Month: \(studentBillingFileName) when adding new Student"
								}
							}
						}
					} catch {
						completionFlag = false
						completionMessage = "Error: Could not get fileID for file: \(studentBillingFileName) when adding new Student"
						print("Error: Could not get fileID for file: \(studentBillingFileName)")
					}
					
				}
			}
		}
		return(completionFlag, completionMessage)
	}
    
	func updateStudent(referenceData: ReferenceData, studentKey: String, studentName: String, originalStudentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactZipCode: String, location: String) async -> (Bool, String) {

		var completionFlag: Bool = true
		var completionMessage: String = ""
		
		let (foundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
		let originalLocation = referenceData.students.studentsList[studentNum].studentLocation
		
		referenceData.students.studentsList[studentNum].studentName = studentName
		referenceData.students.studentsList[studentNum].studentContactFirstName = contactFirstName
		referenceData.students.studentsList[studentNum].studentContactLastName = contactLastName
		referenceData.students.studentsList[studentNum].studentContactEmail = contactEmail
		referenceData.students.studentsList[studentNum].studentContactPhone = contactPhone
		referenceData.students.studentsList[studentNum].studentContactZipCode = contactZipCode
		referenceData.students.studentsList[studentNum].studentLocation = location
		
		completionFlag = await referenceData.students.saveStudentData()
		if completionFlag {
			
			// Update the Locations count of Students at each Location if the Student's Location was changed in the update
			if location != originalLocation {
				let (originalLocationFound, originalLocationNum) = referenceData.locations.findLocationByName(locationName: originalLocation)
				referenceData.locations.locationsList[originalLocationNum].decreaseStudentCount()
				let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: location)
				if locationFound {
					referenceData.locations.locationsList[locationNum].increaseStudentCount()
				}
				completionFlag = await referenceData.locations.saveLocationData()
				
			}
			if completionFlag {
				if studentName != originalStudentName {
					// Change the Student Name in any Tutors that Students is assigned to (in case Student assigned to more than one in a month)
					var tutorNum = 0
					while tutorNum < referenceData.tutors.tutorsList.count && completionFlag {
						let (tutorStudentFound, tutorStudentNum) = referenceData.tutors.tutorsList[tutorNum].findTutorStudentByKey(studentKey: studentKey)
						if tutorStudentFound {
							referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentName = studentName
							referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientName = contactFirstName + " " + contactLastName
							referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientEmail = contactEmail
							referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].clientPhone = contactPhone
							completionFlag = await referenceData.tutors.tutorsList[tutorNum].saveTutorStudentData(tutorName: referenceData.tutors.tutorsList[tutorNum].tutorName)
							
						}
						tutorNum += 1
					}
					
					// Change the name in the Student Billing spreadsheet for the previous month and current month (in case this month already billed and Student in this month's Student Tutor sheet)
					let (prevMonthName, prevMonthYear) = getPrevMonthYear()
					let renamePrevResult = await self.renameStudentInBilledStudentMonth(originalStudentName: originalStudentName, newStudentName: studentName, monthName: prevMonthName, yearName: prevMonthYear)
					if !renamePrevResult {
						completionFlag = false
						completionMessage = "Error renaming Student in Billed Student Month"
					}
					let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
					let renameCurrentResult = await self.renameStudentInBilledStudentMonth(originalStudentName: originalStudentName, newStudentName: studentName, monthName: currentMonthName, yearName: currentMonthYear)
					// If Student not found in current Billed Student month, it may not be an error as the Student may not have been billed yet
				}
			} else {
				completionMessage = "Error: Could not update Location count data when updating Student: \(studentName)"
			}
		} else {
			completionMessage = "Error: Could not save Student data for Student: \(studentName)"
		}
		return(completionFlag, completionMessage)
	}
    
	func renameStudentInBilledStudentMonth(originalStudentName: String, newStudentName: String, monthName: String, yearName: String) async -> Bool {
		var completionResult: Bool = true
		
		var result: Bool = false
		var studentBillingFileID: String = ""
		
		let studentBillingFileName = studentBillingFileNamePrefix + yearName
		
		let studentBillingMonth = StudentBillingMonth(monthName: monthName)
		
		// Get the fileID of the Billed Student spreadsheet for the year
		do {
			(result, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
			if !result {
				completionResult = false
			} else {
				// Read the data from the Billed Student spreadsheet for the previous month
				completionResult = await studentBillingMonth.getStudentBillingMonth(monthName: monthName, studentBillingFileID: studentBillingFileID, loadValidatedData: false)
				if completionResult {
					// Add new the Student to Billed Student list for the month
					let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByStudentName(billedStudentName: originalStudentName)
					if billedStudentFound {
						studentBillingMonth.studentBillingRows[billedStudentNum].studentName = newStudentName
						// Save the updated Billed Student list for the month
						completionResult = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: studentBillingFileID, billingMonth: monthName, saveValidatedStudentData: false)
					} else {
						print("WARNING: Billed Student \(originalStudentName) not found in Billed Student sheet for \(monthName) \(yearName)")
						completionResult = false
					}
				}
			}
		} catch {
			print("Could not get FileID for file: \(studentBillingFileName)")
			completionResult = false
		}
		return(completionResult)
	}
	
	
	func validateNewStudent(referenceData: ReferenceData, studentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactZipCode: String, locationName: String) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		if studentName == "" || studentName == " " {
			validationResult = false
			validationMessage = "Student Name cannot be blank\n"
		} else {
			
			if contactFirstName == "" || contactFirstName == " " {
				validationResult = false
				validationMessage = "Contact First Name cannot be blank\n"
			}
			
			if contactLastName == "" || contactLastName == " " {
				validationResult = false
				validationMessage = "Contact Last Name cannot be blank\n"
			}
			
			let (studentFoundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
			if studentFoundFlag {
				validationResult = false
				validationMessage = "Student Name \(studentName) Already Exists\n"
			}
			
			var commaFlag = studentName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Student Name: \(studentName) Contains a Comma\n"
			}
			
			commaFlag = contactFirstName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact Fist Name: \(contactFirstName) Contains a Comma\n"
			}
			
			commaFlag = contactLastName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact Fist Name: \(contactLastName) Contains a Comma\n"
			}
			
			let validEmailFlag = isValidEmail(contactEmail)
			if !validEmailFlag {
				validationResult = false
				validationMessage += " Error: Email \(contactEmail) is Not Valid\n"
			}
			
			let validPhoneFlag = isValidPhone(contactPhone)
			if !validPhoneFlag {
				validationResult = false
				validationMessage += "Error: Phone Number \(contactPhone) Is Not Valid\n"
			}
			
			if locationName == " " || locationName == "" {
				validationResult = false
				validationMessage += "Error: No Location selected\n"
			}
		}
		
		return(validationResult, validationMessage)
	}
	
	func validateUpdatedStudent(referenceData: ReferenceData, studentName: String, originalStudentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactZipCode: String, locationName: String) -> (Bool, String) {
		var validationResult: Bool = true
		var validationMessage: String = " "
		
		if studentName == "" || studentName == " " {
			validationResult = false
			validationMessage = "Student Name cannot be blank\n"
		} else {
			
			if contactFirstName == "" || contactFirstName == " " {
				validationResult = false
				validationMessage = "Contact First Name cannot be blank\n"
			}
			
			if contactLastName == "" || contactLastName == " " {
				validationResult = false
				validationMessage = "Contact Lastt Name cannot be blank\n"
			}
			
			let (studentFoundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
			if studentFoundFlag && originalStudentName != studentName {
				validationResult = false
				validationMessage = "Error: New Student name \(studentName) already exists\n"
			}
			
			var commaFlag = studentName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Student Name: \(studentName) Contains a Comma\n"
			}
			
			commaFlag = contactFirstName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Guadian First Name: \(contactFirstName) Contains a Comma\n"
			}
			
			commaFlag = contactLastName.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Guadian Last Name: \(contactLastName) Contains a Comma\n"
			}
			
			let validEmailFlag = isValidEmail(contactEmail)
			if !validEmailFlag {
				validationResult = false
				validationMessage += " Error: Email \(contactEmail) is Not Valid\n"
			}
			
			let validPhoneFlag = isValidPhone(contactPhone)
			if !validPhoneFlag {
				validationResult = false
				validationMessage += "Error: Phone Number \(contactPhone) Is Not Valid\n"
			}
		}
		
		return(validationResult, validationMessage)
	}
    
	// This function checks if the  email address associated with a Student is valid
	func isValidEmail(_ email: String) -> Bool {
		let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
		let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
		return emailPredicate.evaluate(with: email)
	}
	
	// This funciton checks if the phone number associated with a Student is valid
	func isValidPhone(_ phone: String)-> Bool {
		let phoneRegex = "(\\([0-9]{3}\\) |[0-9]{3}-)[0-9]{3}-[0-9]{4}"
		let phonePredicate = NSPredicate(format: "SELF MATCHES[c] %@", phoneRegex)
		return phonePredicate.evaluate(with: phone)
	}
    
	// This function changes a Student's Status to "Deleted"
	func deleteStudent(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		
		var deleteResult: Bool = true
		var deleteMessage: String = " "
		var result: Bool = true
		var studentBillingFileID: String = ""
		
		for objectID in indexes {
			if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				// Check that the Student is not assigned to a Tutor and is not already deleted
				if referenceData.students.studentsList[index].studentStatus != "Assigned" && referenceData.students.studentsList[index].studentStatus != "Deleted" {
					// Change the Student's Status to Deleted and save the updated Student List data
					let studentNum = index
					referenceData.students.studentsList[studentNum].markDeleted()
					deleteResult = await referenceData.students.saveStudentData()
					if !deleteResult {
						deleteMessage = "Error: Could not save Student Data when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
					} else {
						// Decrease the system count of Active Students and the count of students at this student's Location
						referenceData.dataCounts.decreaseActiveStudentCount()
						// Decrease the counts of Students at the Location
						let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
						if !locationFound {
							deleteResult = false
							deleteMessage = "Error: Could not find Location \(referenceData.students.studentsList[studentNum].studentLocation) when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
						} else {
							referenceData.locations.locationsList[locationNum].decreaseStudentCount()
							// Save the updated Location List data
							let saveResult = await referenceData.locations.saveLocationData()
							if !saveResult {
								print("Error: could not save Locations Data when deleting Student \(referenceData.students.studentsList[studentNum].studentName)")
								deleteResult = false
								deleteMessage = "Critical Error: Could not save Locations Data when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
							} else {
								// Mark Student deleted in the Billed Student list for previous month
								let (prevMonthName, billingYear) = getPrevMonthYear()
								let studentBillingFileName = studentBillingFileNamePrefix + billingYear
								
								let studentBillingMonth = StudentBillingMonth(monthName: prevMonthName)
								
								// Get the File ID of the Billed Student spreadsheet for the year
								do {
									(result, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
									if !result {
										deleteResult = false
										deleteMessage = "Error: Could not get File ID for Student Billing FileName: \(studentBillingFileName)"
									} else {
										// Read in the Billed Students for the previous month
										deleteResult = await studentBillingMonth.getStudentBillingMonth(monthName: prevMonthName, studentBillingFileID: studentBillingFileID, loadValidatedData: false)
										if !deleteResult {
											deleteMessage = "Error: could not load Student Billing Month for \(prevMonthName) when deleting Student"
										} else {
											// Remove the Student from the Billed Student list for the month
											let studentName = referenceData.students.studentsList[studentNum].studentName
											let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByStudentName(billedStudentName: studentName)
											if billedStudentFound == false {
												deleteResult = false
												deleteMessage = "Critical Error: Could not find Student \(studentName) in the Billed Student List for month \(prevMonthName)"
											}
											studentBillingMonth.deleteBilledStudent(billedStudentNum: billedStudentNum)
											// Save the updated Billed Student list for the month
											deleteResult = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: studentBillingFileID, billingMonth: prevMonthName, saveValidatedStudentData: false)
											if !deleteResult {
												deleteMessage = "Error: Could not save Student Billing Data when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
											}
										}
									}
								} catch {
									deleteResult = false
								}
							}
						}
					}
					
				} else {
					deleteMessage = "Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)"
					print("Error: Student \(referenceData.students.studentsList[index].studentName) cannot be Deleted when Status is \(referenceData.students.studentsList[index].studentStatus)\n")
					deleteResult = false
				}
			}
		}
		if deleteResult {
			deleteResult = await referenceData.dataCounts.saveDataCounts()
			if !deleteResult {
				deleteMessage = "Error: could not save Data Counts when deleting Student "
			}
		}
		
		return(deleteResult, deleteMessage)
	}
	
	// This function changes a Student's Status from "Deleted" to "Active"
	func undeleteStudent(indexes: Set<Service.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unDeleteResult: Bool = true
		var unDeleteMessage: String = " "
		
		print("undeleting Student")
		
		for objectID in indexes {
			if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.students.studentsList[index].studentStatus == "Deleted" {
					let studentNum = index
					// Change the Student's Status to "Active" and save the Student List data
					referenceData.students.studentsList[studentNum].markUndeleted()
					unDeleteResult = await referenceData.students.saveStudentData()
					if unDeleteResult {
						referenceData.dataCounts.increaseActiveStudentCount()
						let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
						referenceData.locations.locationsList[locationNum].increaseStudentCount()
						unDeleteResult = await referenceData.locations.saveLocationData()
						if !unDeleteResult {
							unDeleteMessage = "Error: could not save Location data when Undeleting Student"
						}
					} else {
						unDeleteMessage = "Error: could not save Student data when Undeleting Student \(referenceData.students.studentsList[index].studentName)"
					}
					
				} else {
					unDeleteMessage = "Error: Student \(referenceData.students.studentsList[index].studentName) Status is \(referenceData.students.studentsList[index].studentStatus)\n"
					print("Error: Student \(referenceData.students.studentsList[index].studentName) status is \(referenceData.students.studentsList[index].studentStatus)")
					unDeleteResult = false
				}
			}
		}
		unDeleteResult = await referenceData.dataCounts.saveDataCounts()
		if !unDeleteResult {
			unDeleteMessage = "Error: Could not save Data Counts when Undeleting Student"
		}
		
		return(unDeleteResult, unDeleteMessage)
	}
    
	// This function assigns a Student to a Tutor
	func assignStudent(studentNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String){
		var assignResult: Bool = true
		var assignMessage: String = ""
		
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				let studentName = referenceData.students.studentsList[studentNum].studentName
				// Check that the Student Status is "Unassigned"
				if referenceData.students.studentsList[studentNum].studentStatus == "Unassigned" {
//					let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
					
					referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
					assignResult = await referenceData.students.saveStudentData()
					if !assignResult {
						assignMessage = "Error: could not save Student Data when assigning Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) to Student: \(referenceData.students.studentsList[studentNum].studentName)"
					} else {
						// 
						let dateFormatter = DateFormatter()
						dateFormatter.dateFormat = "yyyy/MM/dd"
						let assignedDate = dateFormatter.string(from: Date())
						let client = referenceData.students.studentsList[studentNum].studentContactFirstName + " " + referenceData.students.studentsList[studentNum].studentContactLastName
						let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: studentName, clientName: client, clientEmail: referenceData.students.studentsList[studentNum].studentContactEmail, clientPhone: referenceData.students.studentsList[studentNum].studentContactPhone, assignedDate: assignedDate)
						assignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
						if !assignResult {
							assignMessage = "Error: could not save Tutor Details data for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) when assigning Student \(referenceData.students.studentsList[studentNum].studentName)"
						} else {
							assignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
							if !assignResult {
								assignMessage = "Error: Could not save Tutor Data when assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							}
						}
					}
				} else {
					assignResult = false
					assignMessage = "Student \(studentName) can not be assigned when status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
				}
			}
		}
	
		return(assignResult, assignMessage)
	}

	func reassignStudent(studentNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String){
		var reassignResult: Bool = true
		var reassignMessage: String = ""
		
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				let studentName = referenceData.students.studentsList[studentNum].studentName
				if referenceData.students.studentsList[studentNum].studentStatus == "Assigned" {
					let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
					let tutorName = referenceData.students.studentsList[studentNum].studentTutorName
					
					referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
					reassignResult = await referenceData.students.saveStudentData()
					if reassignResult {
						let dateFormatter = DateFormatter()
						dateFormatter.dateFormat = "yyyy/MM/dd"
						let assignedDate = dateFormatter.string(from: Date())
						let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: studentName, clientName: referenceData.students.studentsList[studentNum].studentContactFirstName, clientEmail: referenceData.students.studentsList[studentNum].studentContactEmail, clientPhone: referenceData.students.studentsList[studentNum].studentContactPhone, assignedDate: assignedDate)
						let unassignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
						if unassignResult {
							reassignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
							if !reassignResult {
								reassignMessage = "Error: could not save Tutor data when reassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
							}
						} else {
							reassignMessage = "Error: could not add Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor Students list for Tutor \(tutorName)"
						}
					} else {
						reassignMessage = "Error: could not save Student Data when reassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
					}
						
				} else {
					reassignResult = false
					reassignMessage = "Student \(studentName) can not be reassigned when status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
				}
			}
		}
		
		return(reassignResult, reassignMessage)
	}
    
	func unassignStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String){
		var unassignResult: Bool = true
		var unassignMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				let studentName = referenceData.students.studentsList[studentNum].studentName
				
				if referenceData.students.studentsList[studentNum].studentStatus == "Assigned"  {
					let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
					let tutorName = referenceData.students.studentsList[studentNum].studentTutorName
					
					referenceData.students.studentsList[studentNum].unassignTutor()
					unassignResult = await referenceData.students.saveStudentData()
					if unassignResult {
						let (foundFlag, tutorNum) = referenceData.tutors.findTutorByKey(tutorKey: tutorKey)
						if foundFlag {
							unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey)
							if unassignResult {
								unassignResult = await referenceData.tutors.saveTutorData()                    // decreased Student count
							} else  {
								unassignMessage = "Error: could not remove Tutor Student when unassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
							}
						} else {
							unassignResult = false
							unassignMessage = "Error: could not find Tutor \(tutorName) in Tutors list when unassigning Student \(referenceData.students.studentsList[studentNum].studentName)"
						}
					} else {
						unassignMessage = "Error: could not save Student Data when unassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
					}
				} else {
					unassignResult = false
					unassignMessage = "Student \(studentName) can not be Unassigned when status is not Assigned\n"
				}
			}
		}
		return(unassignResult, unassignMessage)
	}
    
	func unassignTutorStudent(tutorStudentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var unassignResult: Bool = true
		var unassignMessage: String = " "
		
		for objectID in tutorStudentIndex {
			if let tutorStudentNum = referenceData.tutors.tutorsList[tutorNum].tutorStudents.firstIndex(where: {$0.id == objectID} ) {
				
				let studentKey = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentKey
				let studentName = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentName
				
				let (studentFoundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
				
				referenceData.students.studentsList[studentNum].unassignTutor()
				unassignResult = await referenceData.students.saveStudentData()
				if unassignResult {
					
					unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: studentKey)
					if unassignResult {
						unassignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
						if unassignResult {
							unassignMessage = "Error: Could not save Tutor data when unassigning Student \(studentName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						}
					} else {
						unassignMessage = "Error: Could not remove Student \(studentName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) Tutor Details sheet"
					}
				} else {
					unassignMessage = "Error: Could not save Student data when unassigning Student \(studentName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				}
			}
			
		}
		return(unassignResult, unassignMessage)
	}
	
	func suspendStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var suspendResult: Bool = true
		var suspendMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.students.studentsList[studentNum].studentStatus == "Unassigned" {
					referenceData.students.studentsList[studentNum].suspendStudent()
					suspendResult = await referenceData.students.saveStudentData()
					if !suspendResult {
						suspendMessage = "Error: could not save Student data when suspending Student \(referenceData.students.studentsList[studentNum].studentName)"
					}
				} else {
					suspendResult = false
					suspendMessage += "Student \(referenceData.students.studentsList[studentNum].studentName) can not be Suspended when Status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
				}
			}
		}
		return(suspendResult, suspendMessage)
	}
	
	func unsuspendStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unsuspendResult: Bool = true
		var unsuspendMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.students.studentsList[studentNum].studentStatus == "Suspended" {
					referenceData.students.studentsList[studentNum].unsuspendStudent()
					unsuspendResult = await referenceData.students.saveStudentData()
					if !unsuspendResult {
						unsuspendMessage = "Error: could not save Student data when unsuspending Student \(referenceData.students.studentsList[studentNum].studentName)"
					}
				} else {
					unsuspendResult = false
					unsuspendMessage += "Student \(referenceData.students.studentsList[studentNum].studentName) not Suspended as Status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
					
				}
			}
		}
		return(unsuspendResult, unsuspendMessage)
	}
}
