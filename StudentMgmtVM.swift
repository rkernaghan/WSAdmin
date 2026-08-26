//
//  StudentMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

@MainActor
@Observable class StudentMgmtVM  {
    
	func addNewStudent(referenceData: ReferenceData, studentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactAddress1: String, contactAddress2: String, contactCity: String, contactState: String, contactZipCode: String, location: String) async -> (Bool, String) {
		var completionFlag: Bool = true
		var logMessage: String = ""
		
		logMessage = "INFO: Adding Student: \(studentName), ContactFirstName: \(contactFirstName), ContactLastName: \(contactLastName), ContactEmail: \(contactEmail), ContactPhone: \(contactPhone), ContactAddress1: \(contactAddress1), ContactAddress2: \(contactAddress2), ContactCity: \(contactCity), ContactState: \(contactState), contactZipCode: \(contactZipCode), Location: \(location)"
		await AppLogger.shared.log(logMessage, newLine: "Y")
		
		var result: Bool = true
		var studentBillingFileID: String = ""
		
		referenceData.students.addNewStudent(studentName: studentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactAddress1: contactAddress1, contactAddress2: contactAddress2, contactCity: contactCity, contactState: contactState, contactZipCode: contactZipCode, location: location, referenceData: referenceData)
		
		let saveStudentsResult = await referenceData.students.saveStudentData()
		if !saveStudentsResult {
			completionFlag = false
			logMessage = "ERROR: could not save Student Data to ReferenceData spreadsheet when adding new Student \(studentName)"
			await AppLogger.shared.log(logMessage)
		} else {
			referenceData.dataCounts.increaseTotalStudentCount()
			let saveCountsFlag = await referenceData.dataCounts.saveDataCounts()
			if !saveCountsFlag {
				completionFlag = false
				logMessage = "ERROR: could not save Data Counts to ReferenceData spreadsheet when adding new Student \(studentName)"
				await AppLogger.shared.log(logMessage)
			} else {
				
				let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: location)
				referenceData.locations.locationsList[locationNum].increaseStudentCount()
				let saveLocationsResult = await referenceData.locations.saveLocationData()
				if !saveLocationsResult {
					completionFlag = false
					logMessage = "ERROR: could not save Data Counts to ReferenceData spreadsheet when adding new Student \(studentName)"
					await AppLogger.shared.log(logMessage)
				} else {
					
					let (prevMonthName, billingYear) = getPrevMonthYear()
					let studentBillingFileName = studentBillingFileNamePrefix + billingYear
					
					let studentBillingMonth = StudentBillingMonth(monthName: prevMonthName)
					
					// Get the File ID of the Billed Student spreadsheet for the year
					do {
						(result, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
						if !result {
							completionFlag = false
							logMessage = "ERROR: Could not get fileID for file: \(studentBillingFileName) when adding new Student\(studentName)"
							await AppLogger.shared.log(logMessage)
						} else {
							// Read in the Billed Students for the previous month
							let getStudentBillingFlag = await studentBillingMonth.getStudentBillingMonth(monthName: prevMonthName, studentBillingFileID: studentBillingFileID, loadValidatedData: false)
							if !getStudentBillingFlag {
								completionFlag = false
								logMessage = "ERROR: Could not load Student Billing Month: \(studentBillingFileName) \(prevMonthName) when adding new Student \(studentName)"
								await AppLogger.shared.log(logMessage)
							} else {
								// Add the new Student to Billed Student list for the month
								let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByStudentName(billedStudentName: studentName)
								if billedStudentFound == false {
									studentBillingMonth.addNewBilledStudent(studentName: studentName)
								} else {
									logMessage = "ERROR: Student \(studentName) already in Billed Student Month for \(studentBillingFileName) \(prevMonthName)"
									await AppLogger.shared.log(logMessage, level: .error)
								}
								// Save the updated Billed Student list for the month
								let saveStudentBillingFlag = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: studentBillingFileID, billingMonth: prevMonthName, saveValidatedStudentData: false)
								if !saveStudentBillingFlag {
									completionFlag = false
									logMessage = "ERROR: Could not save Student Billing Month: \(studentBillingFileName) \(prevMonthName) when adding new Student \(studentName)"
									await AppLogger.shared.log(logMessage)
								} else {
									logMessage = "INFO: Student \(studentName) added to Billed Student Month for \(studentBillingFileName) \(prevMonthName)"
									await AppLogger.shared.log(logMessage)
								}
							}
						}
					} catch {
						completionFlag = false
						logMessage = "ERROR: Could not get fileID for file: \(studentBillingFileName) when adding new Student \(studentName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage)
					}
					
				}
			}
		}
		return(completionFlag, logMessage)
	}
    
	func updateStudent(referenceData: ReferenceData, studentKey: String, studentName: String, originalStudentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactAddress1: String, contactAddress2: String, contactCity: String, contactState: String, contactZipCode: String, location: String) async -> (Bool, String) {

		var completionFlag: Bool = true
		var logMessage: String = ""
		
		logMessage = "INFO: Updating Student: \(originalStudentName), New Name: \(studentName), ContactFirstName: \(contactFirstName), ContactLastName: \(contactLastName), ContactEmail: \(contactEmail), ContactPhone: \(contactPhone), ContactAddress1: \(contactAddress1), ContactAddress2: \(contactAddress2), ContactCity: \(contactCity), ContactState: \(contactState), contactZipCode: \(contactZipCode), Location: \(location)"
		await AppLogger.shared.log(logMessage, newLine: "Y")
		
		let (foundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
		let originalLocation = referenceData.students.studentsList[studentNum].studentLocation
		
		referenceData.students.studentsList[studentNum].studentName = studentName
		referenceData.students.studentsList[studentNum].studentContactFirstName = contactFirstName
		referenceData.students.studentsList[studentNum].studentContactLastName = contactLastName
		referenceData.students.studentsList[studentNum].studentContactEmail = contactEmail
		referenceData.students.studentsList[studentNum].studentContactPhone = contactPhone
		referenceData.students.studentsList[studentNum].studentContactAddress1 = contactAddress1
		referenceData.students.studentsList[studentNum].studentContactAddress2 = contactAddress2
		referenceData.students.studentsList[studentNum].studentContactCity = contactCity
		referenceData.students.studentsList[studentNum].studentContactState = contactState
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
				} else {
					logMessage = "ERROR: COuld not find Location \(referenceData.locations.locationsList[locationNum].locationName) to increase Location Count for Student \(studentName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage)
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
							if !completionFlag {
								logMessage = "ERROR: COuld not save Student \(studentName) in Tutor Student List for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage)
							}
						}
						tutorNum += 1
					}
					
					// Change the name in the Student Billing spreadsheet for the previous month and current month (in case this month already billed and Student in this month's Student Tutor sheet)
					let (prevMonthName, prevMonthYear) = getPrevMonthYear()
					let renamePrevResult = await self.renameStudentInBilledStudentMonth(originalStudentName: originalStudentName, newStudentName: studentName, monthName: prevMonthName, yearName: prevMonthYear)
					if !renamePrevResult {
						completionFlag = false
						logMessage = "ERROR: Error renaming Student \(studentName) in Billed Student Month \(prevMonthName)"
						await AppLogger.shared.log(logMessage, level: .error)
					} else {
						logMessage = "INFO: Student \(studentName) renamed in Billed Student Month \(prevMonthName)"
						await AppLogger.shared.log(logMessage)
					}
					
					let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
					let renameCurrentResult = await self.renameStudentInBilledStudentMonth(originalStudentName: originalStudentName, newStudentName: studentName, monthName: currentMonthName, yearName: currentMonthYear)
					// If Student not found in current Billed Student month, it may not be an error as the Student may not have been billed yet
				}
			} else {
				logMessage = "ERROR: Could not update Location count data when updating Student: \(studentName)"
				await AppLogger.shared.log(logMessage, level: .error)
			}
		} else {
			logMessage = "ERROR: Could not save Student data for Student: \(studentName)"
			await AppLogger.shared.log(logMessage, level: .error)
		}
		return(completionFlag, logMessage)
	}
    
	func renameStudentInBilledStudentMonth(originalStudentName: String, newStudentName: String, monthName: String, yearName: String) async -> Bool {
		var completionResult: Bool = true
		var logMessage: String
		
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
						logMessage = "WARNING: Billed Student \(originalStudentName) not found in Billed Student sheet for \(monthName) \(yearName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .warning)
						completionResult = false
					}
				}
			}
		} catch {
			logMessage = "ERROR: Could not get FileID for file: \(studentBillingFileName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			completionResult = false
		}
		return(completionResult)
	}
	
	
	func validateNewStudent(referenceData: ReferenceData, studentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactAddress1: String, contactAddress2: String, contactCity: String, contactState: String, contactZipCode: String, locationName: String) -> (Bool, String) {
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
			
			commaFlag = contactAddress1.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact Address1: \(contactAddress1) Contains a Comma\n"
			}
			
			commaFlag = contactAddress2.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact Address2: \(contactAddress2) Contains a Comma\n"
			}
			
			commaFlag = contactCity.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact City: \(contactCity) Contains a Comma\n"
			}
			
			commaFlag = contactState.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact State: \(contactState) Contains a Comma\n"
			}
			
//			let (locationFoundFlag, locationNum) = referenceData.locations.findLocationByName(locationName: contactCity)
//			if !locationFoundFlag {
//				validationResult = false
//				validationMessage = "Error: Contact City: \(contactCity) Not in Locations List\n"
//			}
			
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
	
	func validateUpdatedStudent(referenceData: ReferenceData, studentName: String, originalStudentName: String, contactFirstName: String, contactLastName: String, contactEmail: String, contactPhone: String, contactAddress1: String, contactAddress2: String, contactCity: String, contactState: String, contactZipCode: String, locationName: String) -> (Bool, String) {
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
			
			commaFlag = contactAddress1.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact Address1: \(contactAddress1) Contains a Comma\n"
			}
			
			commaFlag = contactAddress2.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact Address2: \(contactAddress2) Contains a Comma\n"
			}
			
			commaFlag = contactCity.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact City: \(contactCity) Contains a Comma\n"
			}
			
			commaFlag = contactState.contains(",")
			if commaFlag {
				validationResult = false
				validationMessage = "Error: Contact State: \(contactState) Contains a Comma\n"
			}
			
//			let (locationFoundFlag, locationNum) = referenceData.locations.findLocationByName(locationName: contactCity)
//			if !locationFoundFlag {
//				validationResult = false
//				validationMessage = "Error: Contact City: \(contactCity) Not in Locations List\n"
//			}
			
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
	func deleteStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		
		var deleteResult: Bool = true
		var logMessage: String = " "
		var result: Bool = true
		var studentBillingFileID: String = ""
		
		for objectID in studentIndex {
			if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				logMessage = "INFO: Deleting Student: \(referenceData.students.studentsList[index].studentName)"
				await AppLogger.shared.log(logMessage, newLine: "Y")
				print(logMessage)
				// Check that the Student is not assigned to a Tutor and is not already deleted
				if referenceData.students.studentsList[index].studentStatus != .StudentAssigned && referenceData.students.studentsList[index].studentStatus != .StudentDeleted {
					// Change the Student's Status to Deleted and save the updated Student List data
					let studentNum = index
					referenceData.students.studentsList[studentNum].markDeleted()
					deleteResult = await referenceData.students.saveStudentData()
					if !deleteResult {
						logMessage = "ERROR: Could not save Student Data when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					} else {
						// Decrease the system count of Active Students and the count of students at this student's Location
						referenceData.dataCounts.decreaseActiveStudentCount()
						// Decrease the counts of Students at the Location
						let (locationFound, locationNum) = referenceData.locations.findLocationByName(locationName: referenceData.students.studentsList[studentNum].studentLocation)
						if !locationFound {
							deleteResult = false
							logMessage = "Error: Could not find Location \(referenceData.students.studentsList[studentNum].studentLocation) when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						} else {
							referenceData.locations.locationsList[locationNum].decreaseStudentCount()
							// Save the updated Location List data
							let saveResult = await referenceData.locations.saveLocationData()
							if !saveResult {
								deleteResult = false
								logMessage = "ERROR: Could not save Locations Data when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
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
										logMessage = "ERROR: Could not get File ID for Student Billing FileName: \(studentBillingFileName)"
										print(logMessage)
										await AppLogger.shared.log(logMessage, level: .error)
									} else {
										// Read in the Billed Students for the previous month
										deleteResult = await studentBillingMonth.getStudentBillingMonth(monthName: prevMonthName, studentBillingFileID: studentBillingFileID, loadValidatedData: false)
										if !deleteResult {
											logMessage = "Error: could not load Student Billing Month for \(prevMonthName) when deleting Student"
											print(logMessage)
											await AppLogger.shared.log(logMessage, level: .error)
											
										} else {
											// Remove the Student from the Billed Student list for the month
											let studentName = referenceData.students.studentsList[studentNum].studentName
											let (billedStudentFound, billedStudentNum) = studentBillingMonth.findBilledStudentByStudentName(billedStudentName: studentName)
											if billedStudentFound == false {
												deleteResult = false
												logMessage = "ERROR: Could not find Student \(studentName) in the Billed Student List for month \(prevMonthName)"
												print(logMessage)
												await AppLogger.shared.log(logMessage, level: .error)
											}
											studentBillingMonth.deleteBilledStudent(billedStudentNum: billedStudentNum)
											// Save the updated Billed Student list for the month
											deleteResult = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: studentBillingFileID, billingMonth: prevMonthName, saveValidatedStudentData: false)
											if !deleteResult {
												logMessage = "ERROR: Could not save Student Billing Data when deleting Student \(referenceData.students.studentsList[studentNum].studentName)"
												print(logMessage)
												await AppLogger.shared.log(logMessage, level: .error)
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
					logMessage = "ERROR: Student \(referenceData.students.studentsList[index].studentName) csnnot be Deleted when status is \(referenceData.students.studentsList[index].studentStatus)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
					deleteResult = false
				}
			}
		}
		if deleteResult {
			deleteResult = await referenceData.dataCounts.saveDataCounts()
			if !deleteResult {
				logMessage = "ERROR: could not save Data Counts when deleting Student"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		}
		
		return(deleteResult, logMessage)
	}
	
	// This function changes a Student's Status from "Deleted" to "Active"
	func undeleteStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unDeleteResult: Bool = true
		var logMessage: String = " "
		var studentName: String = "unknown "
		
		for objectID in studentIndex {
			if let index = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				studentName = referenceData.students.studentsList[index].studentName
				logMessage = "INFO: Undeleting Student: \(studentName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				if referenceData.students.studentsList[index].studentStatus == .StudentDeleted {
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
							logMessage = "ERROR: could not save Location data when Undeleting Student"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					} else {
						logMessage = "ERROR: could not save Student data when Undeleting Student \(referenceData.students.studentsList[index].studentName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}
					
				} else {
					logMessage = "WARNING: Student \(referenceData.students.studentsList[index].studentName) cannot be Undeleted when Status is \(referenceData.students.studentsList[index].studentStatus)\n"
					print(logMessage)
					unDeleteResult = false
				}
			}
		}
		unDeleteResult = await referenceData.dataCounts.saveDataCounts()
		if !unDeleteResult {
			logMessage = "ERROR: Could not save Data Counts when Undeleting Student \(studentName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
		}
		
		return(unDeleteResult, logMessage)
	}
    
	// This function assigns a Student to a Tutor
	func assignStudent(studentNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String){
		var assignResult: Bool = true
		var logMessage: String = ""
		var studentName: String = "unknown"
		
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				studentName = referenceData.students.studentsList[studentNum].studentName
				logMessage = "INFO: Assigning Student: \(studentName) to Tutor: \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				// Check that the Student Status is "Unassigned"
				if referenceData.students.studentsList[studentNum].studentStatus == .StudentUnassigned {
//					let tutorKey = referenceData.students.studentsList[studentNum].studentTutorKey
					
					referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
					assignResult = await referenceData.students.saveStudentData()
					if !assignResult {
						logMessage = "ERROR: could not save Student Data when assigning Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) to Student: \(referenceData.students.studentsList[studentNum].studentName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					} else {
						// 
						let dateFormatter = DateFormatter()
						dateFormatter.dateFormat = "yyyy/MM/dd"
						let assignedDate = dateFormatter.string(from: Date())
						let client = referenceData.students.studentsList[studentNum].studentContactFirstName + " " + referenceData.students.studentsList[studentNum].studentContactLastName
						let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: studentName, clientName: client, clientEmail: referenceData.students.studentsList[studentNum].studentContactEmail, clientPhone: referenceData.students.studentsList[studentNum].studentContactPhone, assignedDate: assignedDate)
						assignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
						if !assignResult {
							logMessage = "ERROR: could not save Tutor Details data for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) when assigning Student \(referenceData.students.studentsList[studentNum].studentName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						} else {
							assignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
							if !assignResult {
								logMessage = "ERROR: Could not save Tutor Data when assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							}
						}
					}
				} else {
					assignResult = false
					logMessage = "WARNING: Student \(studentName) can not be assigned when status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
				}
			}
		}
	
		return(assignResult, logMessage)
	}
	
	// The Reassign function allows a Student to be assigned to more than one Tutor to allow billing to be completed for the original Tutor.  This function assigns a Student to a Tutor in the
	// Reference data without unassigning the Student from the original Tutor in the original Tutor's Tutor Details sheet.
	func reassignStudent(studentNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String){
		var reassignResult: Bool = true
		var logMessage: String = ""
		var studentName: String = "unknown"
		
		for objectID in tutorIndex {
			if let newTutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				studentName = referenceData.students.studentsList[studentNum].studentName
				logMessage = "INFO: Reassigning Student: \(studentName) to Tutor: \(referenceData.tutors.tutorsList[newTutorNum].tutorName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				if referenceData.students.studentsList[studentNum].studentStatus == .StudentAssigned {
					let (originalTutorFoud, originalTutorNum) = referenceData.tutors.findTutorByKey(tutorKey: referenceData.students.studentsList[studentNum].studentCurrentTutorKey)
					if newTutorNum != originalTutorNum {
						// Get current Tutor name and key
						let tutorKey = referenceData.students.studentsList[studentNum].studentCurrentTutorKey
						let tutorName = referenceData.students.studentsList[studentNum].studentCurrentTutorName
						// Set the current Tutor as the previous Tutor in the Reference data
						referenceData.students.studentsList[studentNum].setPreviousTutor( tutorKey: tutorKey, tutorName: tutorName)
						// Assign the Student to the new Tutor
						referenceData.students.studentsList[studentNum].assignTutor(tutorNum: newTutorNum, referenceData: referenceData)
						referenceData.students.studentsList[studentNum].studentStatus = .StudentReassigned
						reassignResult = await referenceData.students.saveStudentData()
						if reassignResult {
							referenceData.students.studentsList[studentNum].studentStatus = .StudentReassigned
							let dateFormatter = DateFormatter()
							dateFormatter.dateFormat = "yyyy/MM/dd"
							let assignedDate = dateFormatter.string(from: Date())
							let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: studentName, clientName: referenceData.students.studentsList[studentNum].studentContactFirstName + " " + referenceData.students.studentsList[studentNum].studentContactLastName, clientEmail: referenceData.students.studentsList[studentNum].studentContactEmail, clientPhone: referenceData.students.studentsList[studentNum].studentContactPhone, assignedDate: assignedDate)
							let unassignResult = await referenceData.tutors.tutorsList[newTutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
							if unassignResult {
								reassignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
								if !reassignResult {
									logMessage = "ERROR: could not save Tutor data when reassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .error)
								}
							} else {
								reassignResult = false
								logMessage = "ERROR: could not add Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor Students list for Tutor \(tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							}
						} else {
							logMessage = "ERROR: could not save Student Data when reassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					} else {
						reassignResult = false
						logMessage = "WARNING: Student \(studentName) can not be reassigned to same Tutor \n"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .warning)
					}
				} else {
					reassignResult = false
					logMessage = "WARNING: Student \(studentName) can not be reassigned when status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
				}
			}
		}
		
		return(reassignResult, logMessage)
	}
    
	// Unassign a Student by changing Student Status to Unassigned, removing Tutor from Student record, removing Student from Tutor's details sheet and decreasing Tutor's assigned Tutor count in Ref data and Tutor Details.
	// If a Student was Reassigned to a different Tutor, meaning the Student has 2 Tutors assigned during the transition, the Student will be assigned to more than one Tutor and the Tutor to be unassigned from
	// must be selected
	func unassignStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String){
		var unassignResult: Bool = true
		var logMessage: String = ""
		var studentName: String = "unknown"
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				studentName = referenceData.students.studentsList[studentNum].studentName
				logMessage = "INFO: Unassigning Student: \(studentName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				if referenceData.students.studentsList[studentNum].studentStatus == .StudentAssigned  {
					let tutorKey = referenceData.students.studentsList[studentNum].studentCurrentTutorKey
					let tutorName = referenceData.students.studentsList[studentNum].studentCurrentTutorName

					referenceData.students.studentsList[studentNum].unassignTutor()
					unassignResult = await referenceData.students.saveStudentData()
					if unassignResult {
						let (foundFlag, tutorNum) = referenceData.tutors.findTutorByKey(tutorKey: tutorKey)
						if foundFlag {
							unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey)
							if unassignResult {
								unassignResult = await referenceData.tutors.saveTutorData()                    // decreased Student count
								if !unassignResult {
									logMessage = "Error: could not save Tutor Data when unassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .error)
								}
							} else  {
								logMessage = "ERROR: could not remove Tutor Student when unassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							}
						} else {
							unassignResult = false
							logMessage = "ERROR: could not find Tutor \(tutorName) in Tutors list when unassigning Student \(referenceData.students.studentsList[studentNum].studentName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					} else {
						unassignResult = false
						logMessage = "ERROR: could not save Student Data when unassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}
				} else {
					unassignResult = false
					logMessage = "WARNING: Student \(studentName) can not be Unassigned when status is not Assigned\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
				}
			}
		}
		return(unassignResult, logMessage)
	}

	// Removes the link of the Student to the original Tutor after a Student has been Reassigned to a new Tutor.
	func unreassignStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String){
		var unreassignResult: Bool = true
		var logMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				let studentName = referenceData.students.studentsList[studentNum].studentName
				logMessage = "INFO: Unreassigning Student: \(studentName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				if referenceData.students.studentsList[studentNum].studentStatus == .StudentReassigned  {
					// Get the Tutor key and name of the Tutor originally assigned to Student before the Reassignment
					let tutorKey = referenceData.students.studentsList[studentNum].studentPreviousTutorKey
					let tutorName = referenceData.students.studentsList[studentNum].studentPreviousTutorName
					
					let (foundFlag, tutorNum) = referenceData.tutors.findTutorByKey(tutorKey: tutorKey)
					if foundFlag {
						// Remove the Student from the Tutor Details file of the original Tutor
						unreassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey)
						if unreassignResult {
							unreassignResult = await referenceData.tutors.saveTutorData()                    // decreased Student count
							// Change the Student Status to Assigned from Reassigned and save Student data
							referenceData.students.studentsList[studentNum].studentStatus = .StudentAssigned
							unreassignResult = await referenceData.students.saveStudentData()
						} else  {
							logMessage = "ERROR: could not remove Tutor Student when Unreassigning Student \(referenceData.students.studentsList[studentNum].studentName) from Tutor \(tutorName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					} else {
						unreassignResult = false
						logMessage = "ERROR: could not find Tutor \(tutorName) in Tutors list when Unreassigning Student \(referenceData.students.studentsList[studentNum].studentName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}

				} else {
					unreassignResult = false
					logMessage = "WARNING: Student \(studentName) can not be Unreassigned when status is not Reassigned\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			}
		}
		return(unreassignResult, logMessage)
	}
	
	
	func unassignTutorStudent(tutorStudentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var unassignResult: Bool = true
		var logMessage: String = " "
		
		for objectID in tutorStudentIndex {
			if let tutorStudentNum = referenceData.tutors.tutorsList[tutorNum].tutorStudents.firstIndex(where: {$0.id == objectID} ) {
				
				let studentKey = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentKey
				let studentName = referenceData.tutors.tutorsList[tutorNum].tutorStudents[tutorStudentNum].studentName
				
				logMessage = "INFO: Unassigning Tutor Student: \(studentName) from Tutor: \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				let (studentFoundFlag, studentNum) = referenceData.students.findStudentByKey(studentKey: studentKey)
				
				referenceData.students.studentsList[studentNum].unassignTutor()
				unassignResult = await referenceData.students.saveStudentData()
				if unassignResult {
					
					unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorStudent(studentKey: studentKey)
					if unassignResult {
						unassignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
						if !unassignResult {
							logMessage = "ERROR: Could not save Tutor data when unassigning Student \(studentName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						} else {
							logMessage = "INFO: \(studentName) unassigned from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName); Tutor data saved."
							print(logMessage)
							await AppLogger.shared.log(logMessage)
						}
					} else {
						logMessage = "ERROR: Could not remove Student \(studentName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) Tutor Details sheet"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}
				} else {
					logMessage = "ERROR: Could not save Student data when unassigning Student \(studentName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			}
			
		}
		return(unassignResult, logMessage)
	}
	
	
	func suspendStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var suspendResult: Bool = true
		var logMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				
				logMessage = "INFO: Suspending Student: \(referenceData.students.studentsList[studentNum].studentName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				if referenceData.students.studentsList[studentNum].studentStatus == .StudentUnassigned {
					referenceData.students.studentsList[studentNum].suspendStudent()
					suspendResult = await referenceData.students.saveStudentData()
					if !suspendResult {
						logMessage = "ERROR: could not save Student data when suspending Student: \(referenceData.students.studentsList[studentNum].studentName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}
				} else {
					suspendResult = false
					logMessage += "WARNING: Student \(referenceData.students.studentsList[studentNum].studentName) can not be Suspended when Status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
				}
			}
		}
		return(suspendResult, logMessage)
	}
	
	func unsuspendStudent(studentIndex: Set<Student.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unsuspendResult: Bool = true
		var logMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				
				logMessage = "INFO: Unsuspending Student: \(referenceData.students.studentsList[studentNum].studentName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, newLine: "Y")
				
				if referenceData.students.studentsList[studentNum].studentStatus == .StudentSuspended {
					referenceData.students.studentsList[studentNum].unsuspendStudent()
					unsuspendResult = await referenceData.students.saveStudentData()
					if !unsuspendResult {
						logMessage = "ERROR: could not save Student data when unsuspending Student: \(referenceData.students.studentsList[studentNum].studentName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
						
					}
				} else {
					unsuspendResult = false
					logMessage += "WARNING: Student \(referenceData.students.studentsList[studentNum].studentName) not Suspended as Status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
					
				}
			}
		}
		return(unsuspendResult, logMessage)
	}
}
