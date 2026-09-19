//
//  TutorMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import SwiftUI
import GoogleSignIn


@MainActor
@Observable class TutorMgmtVM  {
    
	// Adds a new Tutor to the system.  Consists of the following steps:
	// - increase Total Tutor count and save counts
	// - create the new Tutor object and save Tutors list
	// - create a Timesheet for the new Tutor
	// - create a new sheet for the Tutor in Tutor Details spreadsheet
	// - add the Tutor to the Tutor Billing Summary for the current month
	// - add the Base Services to the Tutor (except for specialists)
	//
	func addNewTutor(referenceData: ReferenceData, tutorName: String, tutorEmail: String, tutorPhone: String, maxStudents: Int, tutorType: TutorTypeOption) async throws -> (Bool, String) {
	    var addResult: Bool = true
	    var logMessage: String = ""
	    var newTimesheetFileID: String = ""
		
		logMessage = "INFO: Adding Tutor Name: \(tutorName), contactEmail: \(tutorEmail), contactPhone: \(tutorPhone), maxStudents: \(maxStudents), tutorType: \(String(describing: tutorType))"
		await AppLogger.shared.log(logMessage, newLine: true)
	   
		referenceData.dataCounts.increaseTotalTutorCount()
	    addResult = await referenceData.dataCounts.saveDataCounts()
	    if !addResult {
		    logMessage = "ERROR: could not save Data Counts when adding new Tutor \(tutorName)"
		    await AppLogger.shared.log(logMessage, level: .error)
	    } else {
		    let newTutorKey = PgmConstants.tutorKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestTutorKey)
		    let dateFormatter = DateFormatter()
		    dateFormatter.dateFormat = "yyyy/MM/dd"
		    let startDate = dateFormatter.string(from: Date())
		    //       let maxStudentsInt = Int(maxStudents) ?? 0
		    
		    let newTutor = Tutor(tutorKey: newTutorKey, tutorName: tutorName, tutorEmail: tutorEmail, tutorPhone: tutorPhone, tutorType: tutorType, tutorStatus: .TutorUnassigned, tutorStartDate: startDate, tutorEndDate: " ", tutorMaxStudents: maxStudents, tutorStudentCount: 0, tutorServiceCount: 0, tutorTotalSessions: 0, tutorTotalCost: 0.0, tutorTotalRevenue: 0.0, tutorTotalProfit: 0.0, timesheetFileID: "")
		    referenceData.tutors.addTutor(newTutor: newTutor)
		    
		    // Create a new Timesheet for the Tutor
		    (addResult, newTimesheetFileID) = try await copyNewTimesheet(tutorName: tutorName, tutorEmail: tutorEmail)
		    if !addResult {
			    logMessage = "ERROR: Could not create Timesheet for Tutor \(tutorName)"
			    await AppLogger.shared.log(logMessage, level: .error)
		    } else {
			    // add the TimesheetFileID to the new Tutor object
			    let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
			    referenceData.tutors.tutorsList[tutorNum].timesheetFileID = newTimesheetFileID
			    
			    // Create a new Tutor Details sheet for the new Tutor
			    addResult = await createNewDetailsSheet(tutorName: tutorName, tutorKey: newTutorKey, newTimesheetFileID: newTimesheetFileID)
			    if !addResult {
				    logMessage = "ERROR: could not create Tutor Details sheet for new Tutor \(tutorName)"
				    await AppLogger.shared.log(logMessage, level: .error)
			    } else {
			    
				    // Add the new Tutor to the Billed Tutor list for the previous month so there is data to copy to current month when updating billing stats
				    let (prevMonthName, prevMonthYear) = getPrevMonthYear()
				    addResult = await self.addTutorToBilledTutorMonth(tutorName: tutorName, monthName: prevMonthName, yearName: prevMonthYear)
				    if !addResult {
					    logMessage = "ERROR: Could not add Tutor \(tutorName) to Billed Tutor spreadsheet for \(prevMonthName)"
					    await AppLogger.shared.log(logMessage, level: .error)
				    } else {
					    
					    // Assign all active Base Services to new "Regular" Tutors (not Specialists)
					    var serviceNum = 0
					    if tutorType != .SpecialistTutor {
						    
						    let serviceCount = referenceData.services.servicesList.count
						    while serviceNum < serviceCount && addResult {
							    if referenceData.services.servicesList[serviceNum].serviceType == .Base && referenceData.services.servicesList[serviceNum].serviceStatus != .ServiceDeleted {
								    let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName,  billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1, cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
								    addResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
								    if !addResult {
									    logMessage = "ERROR: Could not save Tutor Details sheet adding Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(tutorName)"
									    await AppLogger.shared.log(logMessage, level: .error)
								    }
								    referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
							    }
							    serviceNum += 1
						    }
						    
					    }
					    addResult = await referenceData.tutors.saveTutorData()
					    if !addResult {
						    logMessage = "ERROR: Could not save Tutor data for Tutor \(tutorName)"
						    await AppLogger.shared.log(logMessage, level: .error)
					    } else {
						    addResult = await referenceData.services.saveServiceData()
						    if !addResult {
							    logMessage = "ERROR: Could not save Services data for Tutor \(tutorName)"
							    await AppLogger.shared.log(logMessage, level: .error)
						    }
					    }
					    
				    }
			    }
		    }
	    }
	    return(addResult, logMessage)
    }
  
    func addTutorToBilledTutorMonth(tutorName: String, monthName: String, yearName: String) async -> Bool {
            var addResult: Bool = false
            var tutorBillingFileID: String = ""
            
            let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
       
	    let tutorBillingMonth = TutorBillingMonth(monthName: monthName)
           
	    // Get the fileID of the Billed Tutor spreadsheet for the year
            do {
                    (addResult, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
		    // Read the data from the Billed Tutor spreadsheet for the previous month
		    addResult = await tutorBillingMonth.getTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID, loadValidatedData: false)
		    if addResult {
			    // Add new the Tutor to Billed Tutor list for the month
			    let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
			    if !billedTutorFound {
				    tutorBillingMonth.addNewBilledTutor(tutorName: tutorName)
				    // Save the updated Billed Tutor list for the month
				    addResult = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName, saveValidatedTutorData: false)
			    } else {
				    let message = "ERROR: Tutor \(tutorName) already exists in Billed Tutor month \(monthName)"
				    print(message)
				    await AppLogger.shared.log(message, level: .error)
				    addResult = false
			    }
		    }
            } catch {
                    let message = "ERROR: Could not get FileID for file: \(tutorBillingFileName)"
		    print(message)
		    await AppLogger.shared.log(message, level: .error)
		    addResult = false
            }

	    return(addResult)
    }

	// This function updates an existing Tutor.  If the Tutor name changes, the following related changes are required:
	//	- rename Tutor Details sheet
	// 	- update Tutor name in Tutor Billing sheet for previous month
	//	- update the Tutor name in the Student Billing sheet for Students assigned to the Tutor
	//	- update the Timesheet name for the Tutor
	func updateTutor(tutorNum: Int, referenceData: ReferenceData, tutorName: String, originalTutorName: String, contactEmail: String, contactPhone: String, maxStudents: Int, tutorType: TutorTypeOption) async -> (Bool, String) {
		var updateResult: Bool = true
		var logMessage: String = ""
		
		var tutorSheetID: Int = 0
		
		logMessage = "INFO: Updating Tutor Name: \(tutorName), Original Name: \(originalTutorName), contactEmail: \(contactEmail), contactPhone: \(contactPhone), maxStudents: \(maxStudents), tutorType: \(String(describing: tutorType))"
		await AppLogger.shared.log(logMessage, newLine: true)
		
		// Check if Tutor name has changed with this update
		if originalTutorName != tutorName {
			
			// Change the name in the Tutor Billing spreadsheet for the previous month and current month (in case this month already billed and Tutor in this month's Billed Tutor sheet)
			let (prevMonthName, prevMonthYear) = getPrevMonthYear()
			updateResult = await self.renameTutorInBilledTutorMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: prevMonthName, yearName: prevMonthYear)
			if !updateResult {
				logMessage = "ERROR: Could not rename Tutor \(originalTutorName) in Billed Tutor data for \(prevMonthName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			} else {
				let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
				// Don't check result as Tutor may not be in current Billed Tutor list of current month if not yet Billed
				updateResult = await self.renameTutorInBilledTutorMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: currentMonthName, yearName: currentMonthYear)
				
				// Change the Tutor Name in the Billed Students lists for the previous and current months for any Students assigned to this Tutor
				// Don't check result as Tutor may not be assigned to any Tutors and therefore won't be in Billed Student list
				updateResult = await self.renameTutorInBilledStudentMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: prevMonthName, yearName: prevMonthYear)
				updateResult = await self.renameTutorInBilledStudentMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: currentMonthName, yearName: currentMonthYear)
				
				// Change the sheet name of the Tutor Details sheet and the name in the tutor's sheet
				// First get the sheet ID in the spreadsheet
				do {
					if let sheetID = try await getSheetIdByName(spreadsheetID: tutorDetailsFileID, sheetName: originalTutorName) {
						tutorSheetID = sheetID
						
						// Then rename the Tutor's sheet in the Tutor Details spreadsheet and change the Tutor name in the Timesheet
						let range = originalTutorName + PgmConstants.tutorDataTutorNameCell
						do {
							updateResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: [[tutorName]], logNote: "Tutor name in renamed Tutor Details sheet")
							if !updateResult {
								logMessage = "ERROR: Could not save new Tutor name in Tutor Details sheet for \(tutorName)"
								print(logMessage)
								await AppLogger.shared.log(logMessage, level: .error)
							} else {
								do {
									updateResult = try await renameSheetInSpreadsheet(spreadsheetID: tutorDetailsFileID, sheetId: tutorSheetID, newSheetName: tutorName)
									if !updateResult {
										logMessage = "ERROR: Could not rename Tutor sheet in Tutor Details spreadsheet"
										print(logMessage)
										await AppLogger.shared.log(logMessage, level: .error)
									} else {
										logMessage = "INFO: Tutor Details sheet renamed successfully for Tutor \(tutorName)"
										print(logMessage)
										await AppLogger.shared.log(logMessage)
										
										// Change the name of the Tutor's timesheet and the Tutor name within the Timesheet RefData sheet
										let formatter = DateFormatter()
										formatter.setLocalizedDateFormatFromTemplate("YYYY")
										let currentYear = formatter.string(from: Date.now)
										let newTutorTimesheetName = "Timesheet " + currentYear + " " + tutorName
										let currentTimesheetName = "Timesheet " + currentYear + " " + originalTutorName
										
										do {
											let (fileIDResult, tutorTimesheetFileID) = try await getFileID(fileName: currentTimesheetName)
											if fileIDResult {
												let range = PgmConstants.timesheetTutorNameCell
												updateResult = try await writeSheetCells(fileID: tutorTimesheetFileID, range:range, values: [[tutorName]], logNote: "Tutor name in Timesheet")
												if !updateResult {
													logMessage = "ERROR: Could not save update Tutor name in Tutor Timesheet for \(tutorName)"
													print(logMessage)
													await AppLogger.shared.log(logMessage, level: .error)
												} else {
													updateResult = try await renameGoogleDriveFile(fileID: tutorTimesheetFileID, newName: newTutorTimesheetName)
													if !updateResult {
														logMessage = "ERROR: Could not rename Tutor Timesheet for Tutor \(tutorName)"
														print(logMessage)
														await AppLogger.shared.log(logMessage, level: .error)
													} else {
														logMessage = "INFO: Timesheet renamed successfully for Tutor \(tutorName)"
														print(logMessage)
														await AppLogger.shared.log(logMessage)
														
														// Change the Tutor name for any Students the updated Tutor is assigned to
														var tutorFound: Bool = false
														var studentNum = 0
														let studentCount = referenceData.students.studentsList.count
														while studentNum < studentCount {
															if referenceData.students.studentsList[studentNum].studentCurrentTutorName == originalTutorName {
																tutorFound = true
																referenceData.students.studentsList[studentNum].studentCurrentTutorName = tutorName
															}
															studentNum += 1
														}
														
														if tutorFound {
															updateResult = await referenceData.students.saveStudentData()
															if !updateResult {
																logMessage = "ERROR: Could not save Student data renaming Tutor \(tutorName)"
																print(logMessage)
																await AppLogger.shared.log(logMessage, level: .error)
															}
														}
														if updateResult {
															// Change the name in the Tutors list in the Reference Data sheet and save it
															referenceData.tutors.tutorsList[tutorNum].updateTutor(tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
															updateResult = await referenceData.tutors.saveTutorData()
															if !updateResult {
																logMessage = "ERROR: Could not save Tutor data when updaing Tutor \(tutorName)"
																print(logMessage)
																await AppLogger.shared.log(logMessage, level: .error)
															}
														}
													}
												}
											}
										} catch {
											updateResult = false
											logMessage = "ERROR: Could not get File ID for Tutor Timesheet \(currentTimesheetName)"
											print(logMessage)
											await AppLogger.shared.log(logMessage, level: .error)
										}
									}
								} catch {
									
									updateResult = false
									logMessage = "ERROR: Could not rename Tutor Details sheet for Tutor \(tutorName)"
									print(logMessage)
									await AppLogger.shared.log(logMessage, level: .error)
								}
							}
						} catch {
							logMessage = "ERROR: Could not write Tutor name to Tutor Details sheet for Tutor"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						}
					} else {
						updateResult = false
						logMessage = "ERROR: Tutor Details Sheet with name \(originalTutorName) not found updating Tutor"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}
				} catch {
					updateResult = false
					logMessage = "ERROR: Tutor Details Sheet with name \(originalTutorName) not found updating Tutor"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .error)
				}
			}
		} else {
			// Not updating Tutor Name
			referenceData.tutors.tutorsList[tutorNum].tutorMaxStudents = maxStudents
			referenceData.tutors.tutorsList[tutorNum].tutorEmail = contactEmail
			referenceData.tutors.tutorsList[tutorNum].tutorPhone = contactPhone
			referenceData.tutors.tutorsList[tutorNum].tutorType = tutorType
			updateResult = await referenceData.tutors.saveTutorData()
			if !updateResult {
				logMessage = "ERROR: Could not save Tutor data when updaing Tutor \(tutorName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
			}
		}
		
		return(updateResult, logMessage)
		
	}

	func renameTutorInBilledTutorMonth(originalTutorName: String, newTutorName: String, monthName: String, yearName: String) async -> Bool {
		var renameResult: Bool = false
		var logMessage: String
		var tutorBillingFileID: String = ""
		
		let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
		
		let tutorBillingMonth = TutorBillingMonth(monthName: monthName)
		
		// Get the fileID of the Billed Tutor spreadsheet for the year
		do {
			(renameResult, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			if renameResult {
				// Read the data from the Billed Tutor spreadsheet for the previous month
				renameResult = await tutorBillingMonth.getTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID, loadValidatedData: false)
				if renameResult {
					// Add new the Tutor to Billed Tutor list for the month
					let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: originalTutorName)
					if billedTutorFound {
						tutorBillingMonth.tutorBillingRows[billedTutorNum].tutorName = newTutorName
						// Save the updated Billed Tutor list for the month
						renameResult = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName, saveValidatedTutorData: false)
					} else {
						logMessage = "WARNING: Billed Tutor \(originalTutorName) not found in Billed Tutor sheet for \(monthName) \(yearName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .warning)
						renameResult = false
					}
				}
			}
		} catch {
			logMessage = "ERROR: Could not get FileID for file: \(tutorBillingFileName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			renameResult = false
		}
		
		return(renameResult)
	}
	
	// looks for each instance of a Tutor Name in a Student Billed month (assigned to a Tutor) and renames the Tutor for that Student
	func renameTutorInBilledStudentMonth(originalTutorName: String, newTutorName: String, monthName: String, yearName: String) async -> Bool {
		var renameResult: Bool = false
		var logMessage: String
		var studentBillingFileID: String = ""
		
		let studentBillingFileName = studentBillingFileNamePrefix + yearName
		
		let studentBillingMonth = StudentBillingMonth(monthName: monthName)
		
		// Get the fileID of the Billed Tutor spreadsheet for the year
		do {
			(renameResult, studentBillingFileID) = try await getFileID(fileName: studentBillingFileName)
			if renameResult {
				// Read the data from the Billed Tutor spreadsheet for the previous month
				renameResult = await studentBillingMonth.getStudentBillingMonth(monthName: monthName, studentBillingFileID: studentBillingFileID, loadValidatedData: false)
				if renameResult {
					
					var billedStudentNum = 0
					let billedStudentCount = studentBillingMonth.studentBillingRows.count
					while billedStudentNum < billedStudentCount {
						let studentTutorName = studentBillingMonth.studentBillingRows[billedStudentNum].tutorName
						if studentTutorName == originalTutorName {
							studentBillingMonth.studentBillingRows[billedStudentNum].tutorName = newTutorName
						}
						billedStudentNum += 1
					}
					renameResult = await studentBillingMonth.saveStudentBillingMonth(studentBillingFileID: studentBillingFileID, billingMonth: monthName, saveValidatedStudentData: false)
					
				}
			} else {
				logMessage = "ERROR: Could not get FileID for file: \(studentBillingFileName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage, level: .error)
				renameResult = false
			}
		} catch {
			logMessage = "ERROR: Could not get FileID for file: \(studentBillingFileName)"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			renameResult = false
		}
		
		return(renameResult)
	}
	
	func validateNewTutor(tutorName: String, tutorEmail: String, tutorPhone: String, tutorMaxStudents: Int, referenceData: ReferenceData)->(Bool, String) {
		var validationResult = true
		var validationMessage = " "
            
		let commaFlag = tutorName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Validation Error: Tutor Name: \(tutorName) Contains a Comma\n"
		}
		
		let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
		if tutorFoundFlag {
			validationResult = false
			validationMessage += "Validation Error: Tutor Name \(tutorName) Already Exists\n"
		}
            
		let validEmailFlag = isValidEmail(tutorEmail)
		if !validEmailFlag {
			validationResult = false
			validationMessage += "Validation Error: Tutor Email \(tutorEmail) is Not Valid\n"
		}
            
		let validPhoneFlag = isValidPhone(tutorPhone)
		if !validPhoneFlag {
			validationResult = false
			validationMessage += "Validation Error: Phone Number \(tutorPhone) Is Not Valid\n"
		}
            
		return(validationResult, validationMessage)
        }

	func validateUpdatedTutor(originalTutorName: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorMaxStudents: Int, referenceData: ReferenceData) -> (Bool, String) {
		var validationResult = true
		var validationMessage = " "
            
		let commaFlag = tutorName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Validation Error: Tutor Name: \(tutorName) Contains a Comma\n"
		}
		
		let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
		if tutorFoundFlag && originalTutorName != tutorName {                   // Check if renaming Tutor to an existing Tutor name
			validationResult = false
			validationMessage += "Validation Error: Tutor name: \(tutorName) already exists\n"
		}
            
		let validEmailFlag = isValidEmail(tutorEmail)
		if !validEmailFlag {
			validationResult = false
			validationMessage += "Validation Error: Email \(tutorEmail) is Not Valid\n"
		}
	    
		let validPhoneFlag = isValidPhone(tutorPhone)
		if !validPhoneFlag {
			validationResult = false
			validationMessage += "Validation Error: Phone Number \(tutorPhone) Is Not Valid\n"
		}
            
		return(validationResult, validationMessage)
        }
    
	func isValidEmail(_ email: String) -> Bool {
		let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
		let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
		return emailPredicate.evaluate(with: email)
	}
    
	func isValidPhone(_ phone: String)-> Bool {
		let phoneRegex = "(\\([0-9]{3}\\) |[0-9]{3}-)[0-9]{3}-[0-9]{4}"
		let phonePredicate = NSPredicate(format: "SELF MATCHES[c] %@", phoneRegex)
		return phonePredicate.evaluate(with: phone)
	}
    
	func deleteTutor(indexes: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var deleteResult = true
		var deleteMessage = " "
		var tutorBillingFileID: String = ""
		var result: Bool = true
		var tutorSheetID: Int
		
		for objectID in indexes {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount == 0 {
					deleteMessage = "INFO: Deleting Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					print(deleteMessage)
					await AppLogger.shared.log(deleteMessage, level: .error, newLine: true)
					
					referenceData.tutors.tutorsList[tutorNum].markDeleted()
					deleteResult = await referenceData.tutors.saveTutorData()
					if !deleteResult {
						deleteMessage = "ERROR: Could not save Tutor data deleting Tutor"
						print(deleteMessage)
						await AppLogger.shared.log(deleteMessage, level: .error)
					} else {
						//Unassign all the Services assigned to the Tutor
						
						var tutorServiceNum = 0
						let tutorServiceCount = referenceData.tutors.tutorsList[tutorNum].tutorServiceCount
						while tutorServiceNum < tutorServiceCount {
							let serviceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
							let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: serviceKey)
							if serviceFound {
								referenceData.services.servicesList[serviceNum].decreaseServiceUseCount()
							}
							tutorServiceNum += 1
						}
						referenceData.tutors.tutorsList[tutorNum].tutorServiceCount = 0
						
						deleteResult = await referenceData.services.saveServiceData()
						if !deleteResult {
							deleteMessage = "ERROR: Could not save Services Data when deleting Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							print(deleteMessage)
							await AppLogger.shared.log(deleteMessage, level: .error)
						} else {
							referenceData.dataCounts.decreaseActiveTutorCount()
							// Remove Tutor from Billed Tutor list for the previous month
							let (prevMonthName, billingYear) = getPrevMonthYear()
							let tutorBillingFileName = tutorBillingFileNamePrefix + billingYear
							
							let tutorBillingMonth = TutorBillingMonth(monthName: prevMonthName)
							
							// Get the File ID of the Billed Tutor spreadsheet for the year
							do {
								(result, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
								if !result {
									deleteResult = false
									deleteMessage = "ERROR: Could not get File ID for Tutor Billing File \(tutorBillingFileName)"
									print(deleteMessage)
									await AppLogger.shared.log(deleteMessage, level: .error)
								} else {
									// Read in the Billed Tutors for the previous month
									deleteResult = await tutorBillingMonth.getTutorBillingMonth(monthName: prevMonthName, tutorBillingFileID: tutorBillingFileID, loadValidatedData: false)
									if !deleteResult {
										deleteMessage = "ERROR: Could not load Tutor Billing data for \(prevMonthName)"
										print(deleteMessage)
										await AppLogger.shared.log(deleteMessage, level: .error)
									} else {
										// Mark Tutor as deleted in the to Billed Tutor list for the month
										let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
										let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
										if billedTutorFound == false {
											deleteResult = false
											deleteMessage = "ERROR: Could not find Tutor \(tutorName) in Billed Tutor list for month \(prevMonthName)"
											print(deleteMessage)
											await AppLogger.shared.log(deleteMessage, level: .error)
										} else {
											// Save the updated Billed Tutor list for the month
											tutorBillingMonth.deleteBilledTutor(billedTutorNum: billedTutorNum)
											deleteResult = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: prevMonthName, saveValidatedTutorData: false)
											if !deleteResult {
												deleteMessage = "ERROR: Could not save Tutor Billing data for \(prevMonthName)"
												print(deleteMessage)
												await AppLogger.shared.log(deleteMessage, level: .error)
											} else {
												
												// Delete the Tutor Details sheet for the Tutor
												do {
													if let sheetID = try await getSheetIdByName(spreadsheetID: tutorDetailsFileID, sheetName: tutorName) {
														tutorSheetID = sheetID
														let deleteFileData = try await deleteSheet(spreadsheetID: tutorDetailsFileID, sheetID: tutorSheetID)
														if deleteFileData == nil {
															deleteMessage = "ERROR: Could not delete Tutor Details sheet for \(tutorName)"
															print(deleteMessage)
															await AppLogger.shared.log(deleteMessage, level: .error)
														} else {
															await AppLogger.shared.log("INFO: Tutor: \(tutorName) is deleted", level: .info)
														}
													} else {
														deleteResult = false
														deleteMessage = "ERROR: Could not get Sheet ID for Tutor \(tutorName) in Tutor Details spreadsheet"
														print(deleteMessage)
														await AppLogger.shared.log(deleteMessage, level: .error)
													}
												} catch {
													deleteResult = false
													deleteMessage = "ERROR: could not get Sheet ID for Tutor \(tutorName) in Tutor Details spreadsheet to delete Tutors details sheet"
													print(deleteMessage)
													await AppLogger.shared.log(deleteMessage, level: .error)
												}
											}
										}
									}
								}
							} catch {
								deleteResult = false
								deleteMessage = "ERROR: Could not get File ID for Billed Tutor File: \(tutorBillingFileName)"
								print(deleteMessage)
								await AppLogger.shared.log(deleteMessage, level: .error)
							}
						}
					}
				} else {
					deleteMessage = "Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					print(deleteMessage)
					await AppLogger.shared.log(deleteMessage, level: .error)
					deleteResult = false
				}
			}
		}
		if deleteResult {
			deleteResult = await referenceData.dataCounts.saveDataCounts()
			if !deleteResult {
				deleteMessage = "ERROR: Could not save Data Counts deleting Tutor "
				print(deleteMessage)
				await AppLogger.shared.log(deleteMessage, level: .error)
			}
		}
		
		return(deleteResult, deleteMessage)
	}
        
    
	func assignStudent(studentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var assignResult: Bool = true
		var logMessage: String = ""

		// Must have the Tutor's existing Students/Services loaded before any
		// addNewTutorStudent call below, otherwise it would save an in-memory
		// tutorStudents array missing everyone loaded from the sheet, wiping
		// out the Tutor's other assigned Students. tutorNum is fixed for the
		// whole loop, so this only needs to happen once, up front.
		guard await referenceData.ensureTutorDetailsLoaded(tutorID: referenceData.tutors.tutorsList[tutorNum].id) else {
			logMessage = "ERROR: could not load Tutor Details for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) before assigning Students"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return (false, logMessage)
		}

		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				logMessage = "INFO: Assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				await AppLogger.shared.log(logMessage)
				print(logMessage)
				
				// Check that the Student Status is "Unassigned"
				if referenceData.students.studentsList[studentNum].studentStatus == .StudentUnassigned {
					referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
					
					assignResult = await referenceData.students.saveStudentData()
					if assignResult {
						let dateFormatter = DateFormatter()
						dateFormatter.dateFormat = "yyyy/MM/dd"
						let assignedDate = dateFormatter.string(from: Date())
						let client = referenceData.students.studentsList[studentNum].studentContactFirstName + " " + referenceData.students.studentsList[studentNum].studentContactLastName
						
						let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: referenceData.students.studentsList[studentNum].studentName, clientName: client, clientEmail: referenceData.students.studentsList[studentNum].studentContactEmail, clientPhone: referenceData.students.studentsList[studentNum].studentContactPhone, assignedDate: assignedDate)
						assignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
						if assignResult {
							assignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
							if !assignResult {
								logMessage = "ERROR: could not save Tutor data assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								await AppLogger.shared.log(logMessage,level: .error)
								print(logMessage)
							} else {
								await AppLogger.shared.log("INFO: Student \(referenceData.students.studentsList[studentNum].studentName) assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
								print(logMessage)
							}
						} else {
							logMessage = "ERROR: could not save Tutor Details assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							await AppLogger.shared.log(logMessage,level: .error)
							print(logMessage)
						}
					} else {
						logMessage = "ERROR: could not save Student data assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage,level: .error)
						print(logMessage)
					}
				} else {
					assignResult = false
					logMessage = "WARNING: Student \(referenceData.students.studentsList[studentNum].studentName) can not be assigned when status is \(referenceData.students.studentsList[studentNum].studentStatus)\n"
					print(logMessage)
					await AppLogger.shared.log(logMessage, level: .warning)
				}
			}
		}
		return(assignResult, logMessage)
	}
	
	// Assigns a specific Tutor a set of one or more Services
	func assignService(serviceIndex: Set<Service.ID>, tutorNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var assignResult: Bool = true
		var logMessage: String = ""
		
		// Must have the Tutor's existing Students/Services loaded before assigning Service
		// processing below, otherwise it would save an in-memory
		// tutorService array missing everyone loaded from the sheet, wiping
		// out the Tutor's other assigned Services. tutorNum is fixed for the
		// whole loop, so this only needs to happen once, up front.
		guard await referenceData.ensureTutorDetailsLoaded(tutorID: referenceData.tutors.tutorsList[tutorNum].id) else {
			logMessage = "ERROR: could not load Tutor Details for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) before assigning Service"
			print(logMessage)
			await AppLogger.shared.log(logMessage, level: .error)
			return (false, logMessage)
		}
		
		for objectID in serviceIndex {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
			print(referenceData.services.servicesList[serviceNum].serviceTimesheetName)
		
				logMessage = "INFO: Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				await AppLogger.shared.log(logMessage)
				
				let (tutorServiceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByName(serviceName: referenceData.services.servicesList[serviceNum].serviceTimesheetName)
				if !tutorServiceFound {
					let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName, billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1,  cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
					assignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
					if assignResult {
						assignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
						if assignResult {
							referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
							assignResult = await referenceData.services.saveServiceData()
							if !assignResult {
								logMessage = "ERROR: Could not save Services data assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							} else {
								await AppLogger.shared.log("INFO: Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
								print(logMessage)
							}
						} else {
							logMessage = "ERROR: Could not save Tutors data assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							await AppLogger.shared.log(logMessage,level: .error)
							print(logMessage)
						}
					} else {
						logMessage = "ERROR: Could not save Tutor Details data when adding  Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage,level: .error)
						print(logMessage)
					}
				} else {
					logMessage = "WARNING: Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) already assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					print(logMessage)
					await AppLogger.shared.log(logMessage,level: .warning)
				}
			}
		}
		return(assignResult, logMessage)
	}
	
	// Assigns a specific Service to a set of one or more Tutors
	func assignTutorServiceSet(serviceNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var assignResult: Bool = true
		var logMessage: String = ""
		
		logMessage = "INFO: Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to one or more Tutors"
		await AppLogger.shared.log(logMessage)
		print(logMessage)
 
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				print(referenceData.tutors.tutorsList[tutorNum].tutorName)
				await AppLogger.shared.log("INFO: Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")

				// Must load before findTutorServiceByKey below, not just before
				// addNewTutorService: an unloaded tutorServices array would make
				// the "already assigned" check below report a false negative,
				// and addNewTutorService would then save an in-memory
				// tutorServices array missing everyone loaded from the sheet.
				guard await referenceData.ensureTutorDetailsLoaded(tutorID: objectID) else {
					assignResult = false
					logMessage = "ERROR: could not load Tutor Details for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) before assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
					await AppLogger.shared.log(logMessage, level: .error)
					continue
				}

				let (tutorServiceFound, _) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey)
				if !tutorServiceFound {
					
					let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName, billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1,  cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
					assignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
					if assignResult {
						assignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
						if assignResult {
							referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
							assignResult = await referenceData.services.saveServiceData()
							if !assignResult {
								logMessage = "ERROR: Could not save Service data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								await AppLogger.shared.log(logMessage,level: .error)
							} else {
								logMessage = "INFO: Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								await AppLogger.shared.log(logMessage)
							}
								
						} else {
							logMessage = "ERROR: Could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							await AppLogger.shared.log(logMessage,level: .error)
						}
					} else {
						logMessage = "ERROR: Could not save Tutor Details for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage,level: .error)
					}
				} else {
					assignResult = false
					logMessage = "WARNING: Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) already assigned Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
					await AppLogger.shared.log(logMessage,level: .warning)
				}
			}
		}
		return(assignResult, logMessage)
	}
    
	func unassignTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var unassignResult: Bool = true
		var logMessage: String = " "
		
		logMessage = "INFO: Unssigning one or more Services from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
		print(logMessage)
		await AppLogger.shared.log(logMessage)
		
		let serviceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
		let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: serviceKey )
		if serviceFound {
			logMessage = "INFO: Unssigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
			await AppLogger.shared.log(logMessage)
			
			referenceData.services.servicesList[serviceNum].decreaseServiceUseCount()
			unassignResult = await referenceData.services.saveServiceData()
			if unassignResult {
				unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorService(serviceKey: serviceKey)
				if !unassignResult {
					logMessage = "ERROR: could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					await AppLogger.shared.log(logMessage,level: .error)
				} else {
					unassignResult = await referenceData.tutors.saveTutorData()      // decreased Service count for Tutor
					if !unassignResult {
						logMessage = "ERROR could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage,level: .error)
					} else {
						await AppLogger.shared.log("INFO: Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) unassigned from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
					}
				}
			} else {
				logMessage = "ERROR: could not save Service data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				await AppLogger.shared.log(logMessage,level: .error)
			}
		} else {
			unassignResult = false
			logMessage = "ERROR: Tutor Service \(referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName) not Found for tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
			await AppLogger.shared.log(logMessage,level: .error)
		}
		return(unassignResult, logMessage)
	}
    
	func unassignTutorServiceSet(tutorNum: Int, tutorServiceIndex: Set<TutorService.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unassignResult: Bool = true
		var logMessage: String = " "
		
		for objectID in tutorServiceIndex {
			if let tutorServiceNum = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
				
				
				let serviceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
				let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: serviceKey )
				
				logMessage = "INFO: Unassigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				print(logMessage)
				await AppLogger.shared.log(logMessage)
				
				if serviceFound {
					referenceData.services.servicesList[serviceNum].decreaseServiceUseCount()
					unassignResult = await referenceData.services.saveServiceData()
					if unassignResult {
						unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorService(serviceKey: serviceKey)
						if !unassignResult {
							logMessage = "ERROR: could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							await AppLogger.shared.log(logMessage,level: .error)
						} else {
							unassignResult = await referenceData.tutors.saveTutorData()      // decreased Service count for Tutor
							if !unassignResult {
								logMessage = "ERROR: could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
								await AppLogger.shared.log(logMessage,level: .error)
							} else {
								await AppLogger.shared.log("INFO: Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
							}
						}
					} else {
						logMessage = "ERROR: could not save Service data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage,level: .error)
					}
				} else {
					unassignResult = false
					logMessage = "ERROR: Tutor Service \(referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName) not Found for tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					await AppLogger.shared.log(logMessage,level: .error)
				}
			}
		}
		return(unassignResult, logMessage)
	}
	
	
	func updateTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData, timesheetName: String, invoiceName: String, billingType: BillingTypeOption, cost1: Double, cost2: Double, cost3: Double, price1: Double, price2: Double, price3: Double) async -> (Bool, String) {
		
		var updateResult: Bool = true
		var logMessage: String = ""
		
		updateResult = await referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
		if !updateResult {
			logMessage = "ERROR: Could not save Tutor Service \(timesheetName) for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) "
			await AppLogger.shared.log(logMessage,level: .error)
		} else {
			await AppLogger.shared.log("INFO: Tutor Service \(timesheetName) updated for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName), timesheetName: \(timesheetName), invoiceName: \(invoiceName), billingType: \(String(describing: billingType)), cost1: \(cost1), cost2: \(cost2), cost3: \(cost3), price1: \(price1), price2: \(price2), price3: \(price3) ")
		}
		
		return(updateResult, logMessage)
	}
	
	func suspendTutor(tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var suspendResult: Bool = true
		var logMessage: String = ""
		
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus == .TutorUnassigned {
					referenceData.tutors.tutorsList[tutorNum].suspendTutor()
					suspendResult = await referenceData.tutors.saveTutorData()
					if !suspendResult {
						logMessage = "ERROR: Cannot save Tutors Data when suspending Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage,level: .error)
					} else {
						await AppLogger.shared.log("INFO: Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) suspended")
					}
				} else {
					suspendResult = false
					logMessage += "ERROR: Cannot Suspend Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) because Status is \(referenceData.tutors.tutorsList[tutorNum].tutorStatus) \n"
					await AppLogger.shared.log(logMessage,level: .error)
				}
			}
		}
		return(suspendResult, logMessage)
	}
	
	func unsuspendTutor(tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unsuspendResult: Bool = true
		var logMessage: String = ""
		
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus == .TutorSuspended {
					referenceData.tutors.tutorsList[tutorNum].unsuspendTutor()
					unsuspendResult = await referenceData.tutors.saveTutorData()
					if !unsuspendResult {
						logMessage = "ERROR: could not save Tutor Data when unsuspending Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						await AppLogger.shared.log(logMessage,level: .error)
					} else {
						await AppLogger.shared.log("INFO: Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) unsuspended")
					}
				} else {
					unsuspendResult = false
					logMessage += "WARNING: Cannot Unsuspend Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) because Status is not Suspended \n"
					await AppLogger.shared.log(logMessage,level: .warning)
				}
			}
		}
		return(unsuspendResult, logMessage)
	}
    
   // Creates a new Timesheet for a Tutor by copying the template Timesheet
	func copyNewTimesheet(tutorName: String, tutorEmail: String) async throws -> (Bool, String) {
		var copyFileResult: Bool
		var copyFileID: String?
		var logMessage: String

		var newTimesheetFileID: String = ""
		var copiedFileData = [String : Any]()
        
		logMessage = "INFO: Copying New Timesheet for \(tutorName)"
		await AppLogger.shared.log(logMessage)
      
		let formatter = DateFormatter()
		formatter.setLocalizedDateFormatFromTemplate("YYYY")
		let currentYear = formatter.string(from: Date.now)
		let newTimesheetName  = "Timesheet " + currentYear + " " + tutorName
		do {
			(copyFileResult, copyFileID) = try await copyGoogleDriveFile(sourceFileId: timesheetTemplateFileID, newFileName: newTimesheetName)
			if copyFileResult {
				
				if let copyFileID = copyFileID {
					// The new Timesheet needs the FileID of the Tutor Details file in the refData sheet
					let updateValues = [[tutorDetailsFileID]]
					let range = PgmConstants.timesheetDetailsFileIDCell
					do {
						copyFileResult = try await writeSheetCells(fileID: copyFileID, range: range, values: updateValues, logNote: "Tutor Details FileID in Timesheet RefData")
						print("INFO: Updating Tutor Details File ID in new Timesheet for \(tutorName)")
						if !copyFileResult {
							logMessage = "ERROR: Adding Tutor Details File ID to Timesheet RefData for \(tutorName)\n"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
						} else {
							logMessage = "INFO: Added Tutor Details File ID to Timesheet RefData for \(tutorName)\n"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .info)
						}
					} catch {
						copyFileResult = false
						logMessage = "ERROR: Adding Tutor Details File ID to Timesheet RefData for \(tutorName)\n"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
					}
			
					newTimesheetFileID = copyFileID
					
					do {
						var sendNotificationFlag: Bool
						if runMode == .test {
							sendNotificationFlag = false
						} else {
							sendNotificationFlag = true
						}
						
						var copyFileData = try await addPermissionToFile(fileID: newTimesheetFileID, role: "writer", type: "user", emailAddress: tutorEmail, sendNotificationEmail: sendNotificationFlag)
						if let copyFileData = copyFileData {
							try await addPermissionToFile(fileID: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.russellEmail, sendNotificationEmail: sendNotificationFlag)
							try await addPermissionToFile(fileID: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.stephenEmail, sendNotificationEmail: sendNotificationFlag)
							try await addPermissionToFile(fileID: newTimesheetFileID, role: "writer", type: "user", emailAddress: PgmConstants.writeSeattleEmail, sendNotificationEmail: sendNotificationFlag)
							
							let range = PgmConstants.timesheetTutorNameCell
							do {
								copyFileResult = try await writeSheetCells(fileID: newTimesheetFileID, range:range, values: [[tutorName]], logNote: "Timesheet Tutor Name")
							} catch {
								print("ERROR: can not write Tutor Name into new Tutor Timesheet")
								await AppLogger.shared.log("ERROR: can not write Tutor Name into new Tutor Timesheet", level: .error)
								copyFileResult = false
							}
						} else {
							await AppLogger.shared.log("ERROR: Can not grant Tutor \(tutorName) write access to Timesheet", level: .error)
							copyFileResult = false
						}
						// Grant new Tutor ability to access the Tutor Details spreadsheet so that their Timesheet can pull the Students and Services assigned to them
						copyFileData = try await addPermissionToFile(fileID: tutorDetailsFileID, role: "reader", type: "user", emailAddress: tutorEmail, sendNotificationEmail: false)
						if let copyFileData = copyFileData {
							logMessage = "INFO: Granted Tutor \(tutorName) read access to Tutor Details File Name"
							print(logMessage)
							await AppLogger.shared.log(logMessage)
						} else {
							logMessage = "ERROR: Can not grant Tutor \(tutorName) read access to Tutor Details spreadsheet"
							print(logMessage)
							await AppLogger.shared.log(logMessage, level: .error)
							copyFileResult = false
						}
					} catch {
						logMessage = "Could not add access permission to new Timesheet for Tutor: \(tutorName)"
						print(logMessage)
						await AppLogger.shared.log(logMessage, level: .error)
						copyFileResult = false
					}
					
				} else {
					copyFileResult = false
					logMessage = "ERROR: No valid string found for the key 'name'"
					await AppLogger.shared.log(logMessage, level: .error)
				}
			} else {
				logMessage = "ERROR:  Could not copy Timesheet for Tutor: \(tutorName)"
				await AppLogger.shared.log(logMessage, level: .error)
				copyFileResult = false
			}
		} catch {
			logMessage = "ERROR:  Could not copy Timesheet for Tutor: \(tutorName)"
			await AppLogger.shared.log(logMessage, level: .error)
			copyFileResult = false
		}

		return(copyFileResult, newTimesheetFileID)
	}
         
	
	func createNewDetailsSheet(tutorName: String, tutorKey: String, newTimesheetFileID: String) async -> Bool {
		var createResult: Bool = true
		var createMsg: String
	    
		var updateValues = [[String]]()
		
		do {
			let newSheetData = try await createNewSheetInSpreadsheet(spreadsheetID: tutorDetailsFileID, sheetTitle: tutorName)
			if let newSheetData = newSheetData {
				var range = tutorName + PgmConstants.tutorHeader1Range
				updateValues = PgmConstants.tutorHeader1Array
				do {
					createResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues, logNote: "Tutor Details header 1")
					if createResult {
						range = tutorName + PgmConstants.tutorHeader2Range
						updateValues = PgmConstants.tutorHeader2Array
						do {
							createResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues, logNote: "Tutor Details header 2")
							if createResult {
								range = tutorName + PgmConstants.tutorHeader3Range
								updateValues = [[tutorKey, tutorName], ["Timesheet FileID", newTimesheetFileID]]
								do {
									createResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues, logNote: "Tutor Details Timesheet FileID")
								} catch {
									createMsg = "ERROR: Failed to save Tutor Details Header 3 data for tutor \(tutorName):\(error.localizedDescription)"
									print(createMsg)
									await AppLogger.shared.log(createMsg, level: .error)
									createResult = false
								}
							}
						} catch {
							createMsg = "ERROR: Failed to save Tutor Details Header 2 data for Tutor \(tutorName):\(error.localizedDescription)"
							print(createMsg)
							await AppLogger.shared.log(createMsg, level: .error)
							createResult = false
						}
					}
				} catch {
					createMsg = "ERROR: Failed to save Tutor Details Header 1 data for Tutor \(tutorName):\(error.localizedDescription)"
					print(createMsg)
					await AppLogger.shared.log(createMsg, level: .error)
					createResult = false
				}
			} else {
				createMsg = "ERROR: could not create new Tutor Details sheet for tutor \(tutorName)"
				await AppLogger.shared.log(createMsg, level: .error)
				createResult = false
			}
		} catch {
			createMsg = "ERROR: could not create new Tutor Details sheet for tutor \(tutorName)"
			print(createMsg)
			await AppLogger.shared.log(createMsg, level: .error)
			createResult = false
		}
		return(createResult)
	}
 
    
	func printTutor(indexes: Set<Tutor.ID>, referenceData: ReferenceData) {
		print("Printing Tutor")
		
		for objectID in indexes {
			if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				print("Tutor Name: \(referenceData.tutors.tutorsList[idx].tutorName)")
				print("Tutor Student Count: \(referenceData.tutors.tutorsList[idx].tutorStudentCount)")
				var studentNum = 0
				while studentNum < referenceData.tutors.tutorsList[idx].tutorStudentCount {
					print("Tutor Student: \(referenceData.tutors.tutorsList[idx].tutorStudents[studentNum].studentName)")
					studentNum += 1
				}
				print("Tutor Service Count: \(referenceData.tutors.tutorsList[idx].tutorServiceCount)")
				var serviceNum = 0
				while serviceNum < referenceData.tutors.tutorsList[idx].tutorServiceCount {
					print("Tutor Service: \(referenceData.tutors.tutorsList[idx].tutorServices[serviceNum].timesheetServiceName)")
					serviceNum += 1
				}
			}
		}
	}
    
	func buildServiceCostArray(serviceNum: Int, referenceData: ReferenceData) -> TutorServiceCostList {
		let tutorServiceCostList = TutorServiceCostList()
		
		let serviceKey = referenceData.services.servicesList[serviceNum].serviceKey
		var tutorNum = 0
		while tutorNum < referenceData.tutors.tutorsList.count {
			let (serviceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: serviceKey)
			if serviceFound {
				let tutorKey = referenceData.tutors.tutorsList[tutorNum].tutorKey
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				let cost1 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost1
				let cost2 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost2
				let cost3 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost3
				let price1 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price1
				let price2 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price2
				let price3 = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price3
				
				let newTutorServiceCost = TutorServiceCost(tutorKey: tutorKey, tutorName: tutorName, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
				tutorServiceCostList.addTutorServiceCost(newTutorServiceCost: newTutorServiceCost, referenceData: referenceData)
			}
			tutorNum += 1
		}
		return(tutorServiceCostList)
	}
	
	func buildTutorAvailabilityArray(referenceData: ReferenceData) async -> [TutorAvailabilityRow] {
		
		var tutorAvailabilityArray = [TutorAvailabilityRow]()
		
		var result: Bool = false
		var timesheetFileID: String = ""
		
		let yearInt = Calendar.current.dateComponents([.year], from: Date()).year
		let timesheetYear = String(yearInt!)
		
		// Loop through all Tutors selecting those that are Assigned or Unassigned (ignore Suspended and Deleted Tutors)
		var tutorNum = 0
		while tutorNum < referenceData.tutors.tutorsList.count {
			if referenceData.tutors.tutorsList[tutorNum].tutorStatus == .TutorAssigned || referenceData.tutors.tutorsList[tutorNum].tutorStatus == .TutorUnassigned {
				let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
				let tutorStatus = referenceData.tutors.tutorsList[tutorNum].tutorStatus
				let tutorStudentCount = referenceData.tutors.tutorsList[tutorNum].tutorStudentCount
				
				// Get fileid of the Availability sheet of the Tutors Timesheet spreadsheet
				
				let fileName = "Timesheet " + timesheetYear + " " + tutorName
				do {
					(result, timesheetFileID) = try await getFileID(fileName: fileName)
					if result {
						let tutorAvailabilityRow = try await buildTutorAvailabilityRow(tutorName: tutorName, timesheetFileID: timesheetFileID, tutorStatus: tutorStatus, tutorStudentCount: tutorStudentCount)
						tutorAvailabilityArray.append(tutorAvailabilityRow)
					}
				} catch {
					print("Error: could not get timesheet fileID for \(fileName)")
					await AppLogger.shared.log("ERROR: could not get timesheet fileID for \(fileName)", level: .error)
				}
				
			}
			tutorNum += 1
		}
		
		return(tutorAvailabilityArray)
	}
    
}
