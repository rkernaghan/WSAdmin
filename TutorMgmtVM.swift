//
//  TutorMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import SwiftUI
import GoogleSignIn



@Observable class TutorMgmtVM  {
    
    
    func addNewTutor(referenceData: ReferenceData, tutorName: String, tutorEmail: String, tutorPhone: String, maxStudents: Int) async -> (Bool, String) {
	    var addResult: Bool = true
	    var addMessage: String = ""
	    
 //           var tutorBillingFileID: String = ""
            
	    referenceData.dataCounts.increaseTotalTutorCount()
	    addResult = await referenceData.dataCounts.saveDataCounts()
	    if !addResult {
		    addMessage = "Error: could not save Data Counts when adding new Tutor"
	    } else {
		    let newTutorKey = PgmConstants.tutorKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestTutorKey)
		    let dateFormatter = DateFormatter()
		    dateFormatter.dateFormat = "yyyy/MM/dd"
		    let startDate = dateFormatter.string(from: Date())
		    //       let maxStudentsInt = Int(maxStudents) ?? 0
		    
		    let newTutor = Tutor(tutorKey: newTutorKey, tutorName: tutorName, tutorEmail: tutorEmail, tutorPhone: tutorPhone, tutorStatus: "Unassigned", tutorStartDate: startDate, tutorEndDate: " ", tutorMaxStudents: maxStudents, tutorStudentCount: 0, tutorServiceCount: 0, tutorTotalSessions: 0, tutorTotalCost: 0.0, tutorTotalRevenue: 0.0, tutorTotalProfit: 0.0)
		    referenceData.tutors.loadTutor(newTutor: newTutor)
		    
		    // Create a new Tutor Details sheet for the new Tutor
		    addResult = await createNewDetailsSheet(tutorName: tutorName, tutorKey: newTutorKey)
		    if !addResult {
			    addMessage = "Error: could not create Tutor Details sheet for new Tutor \(tutorName)"
		    } else {
			    // Create a new Timesheet for the Tutor
			    addResult = await copyNewTimesheet(tutorName: tutorName, tutorEmail: tutorEmail)
			    if !addResult {
				    addMessage = "Critical Error: Could not create Timesheet for Tutor \(tutorName)"
			    } else {
				    // Add the new Tutor to the Billed Tutor list for the previous month
				    let (prevMonthName, prevMonthYear) = getPrevMonthYear()
				    addResult = await self.addTutorToBilledTutorMonth(tutorName: tutorName, monthName: prevMonthName, yearName: prevMonthYear)
				    if !addResult {
					    addMessage = "Critical Error: Could not add Tutor \(tutorName) to Billed Tutor spreadsheet for \(prevMonthName)"
				    } else {
					    
					    // Assign all Base Services to new Tutor
					    let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
					    var serviceNum = 0
					    let serviceCount = referenceData.services.servicesList.count
					    while serviceNum < serviceCount && addResult {
						    if referenceData.services.servicesList[serviceNum].serviceType == .Base {
							    let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName,  billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1, cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
							    addResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
							    if !addResult {
								    addMessage = "Critical Error: Could not save Tutor Details sheet adding Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(tutorName)"
							    }
							    referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
						    }
						    serviceNum += 1
					    }
					    addResult = await referenceData.tutors.saveTutorData()
					    if !addResult {
						    addMessage = "Critical Error: Could not save Tutor data adding Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(tutorName)"
					    } else {
						    addResult = await referenceData.services.saveServiceData()
						    if !addResult {
							    addMessage = "Critical Error: Could not save Services data adding Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(tutorName)"
						    }
					    }
				    }
			    }
		    }
	    }
	    return(addResult, addMessage)
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
		    addResult = await tutorBillingMonth.loadTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID)
		    if addResult {
			    // Add new the Tutor to Billed Tutor list for the month
			    let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
			    if !billedTutorFound {
				    tutorBillingMonth.addNewBilledTutor(tutorName: tutorName)
				    // Save the updated Billed Tutor list for the month
				    addResult = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName)
			    } else {
				    addResult = false
			    }
		    }
            } catch {
                    print("Could not get FileID for file: \(tutorBillingFileName)")
		    addResult = false
            }

	    return(addResult)
    }

	func updateTutor(tutorNum: Int, referenceData: ReferenceData, tutorName: String, originalTutorName: String, contactEmail: String, contactPhone: String, maxStudents: Int) async -> (Bool, String) {
		var updateResult: Bool = true
		var updateMessage: String = ""
		
		var tutorSheetID: Int = 0
		// Check if Tutor name has changed with this update
		if originalTutorName != tutorName {
			
			// Change the name in the Tutor Billing spreadsheet for the previous month and current month (in case this month already billed and Tutor in this month's Billed Tutor sheet)
			let (prevMonthName, prevMonthYear) = getPrevMonthYear()
			updateResult = await self.renameTutorInBilledTutorMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: prevMonthName, yearName: prevMonthYear)
			if !updateResult {
				updateMessage = "Critical Error: Could not rename Tutor \(originalTutorName) in Billed Tutor data for \(prevMonthName)"
			} else {
				let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
				// Don't check result as Tutor may not be in current Billed Tutor list of current month not yet Billed
				updateResult = await self.renameTutorInBilledTutorMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: currentMonthName, yearName: currentMonthYear)
				
				// Change the sheet name of the Tutor Details sheet and the name in the tutor's sheet
				// First get the sheet ID in the spreadsheet
				do {
					if let sheetID = try await getSheetIdByName(spreadsheetId: tutorDetailsFileID, sheetName: originalTutorName) {
						tutorSheetID = sheetID
						
						// Then rename the Tutor's sheet in the Tutor Details spreadsheet and change the Tutor name in the Timesheet
						let range = originalTutorName + PgmConstants.tutorDataTutorNameCell
						do {
							updateResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: [[tutorName]])
							if !updateResult {
								updateMessage = "Critical Error: Could not save new Tutor name in Tutor Details sheet for \(tutorName)"
							} else {
								do {
									updateResult = try await renameSheetInSpreadsheet(spreadsheetId: tutorDetailsFileID, sheetId: tutorSheetID, newSheetName: tutorName)
									if !updateResult {
										updateMessage = "Critical Error: Could not rename Tutor sheet in Tutor Details spreadsheet"
									} else {
										print("Tutor Details sheet renamed successfully!")
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
												updateResult = try await writeSheetCells(fileID: tutorTimesheetFileID, range:range, values: [[tutorName]])
												if !updateResult {
													updateMessage = "Critical Error: Could not save update Tutor name in Tutor Timesheet for \(tutorName)"
												} else {
													updateResult = try await renameGoogleDriveFile(fileId: tutorTimesheetFileID, newName: newTutorTimesheetName)
													if !updateResult {
														updateMessage = "Critical Error: Could not rename Tutor Timesheet for Tutor \(tutorName)"
													} else {
														print("Timesheet renamed successfully!")
														
														// Change the Tutor name for any Students the updated Tutor is assigned to
														var tutorFound: Bool = false
														var studentNum = 0
														let studentCount = referenceData.students.studentsList.count
														while studentNum < studentCount {
															if referenceData.students.studentsList[studentNum].studentTutorName == originalTutorName {
																tutorFound = true
																referenceData.students.studentsList[studentNum].studentTutorName = tutorName
															}
															studentNum += 1
														}
														
														if tutorFound {
															updateResult = await referenceData.students.saveStudentData()
															if !updateResult {
																updateMessage = "Critical Error: Could not save Student data renaming Tutor \(tutorName)"
															}
														}
														if updateResult {
															// Change the name in the Tutors list in the Reference Data sheet and save it
															referenceData.tutors.tutorsList[tutorNum].updateTutor(tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
															updateResult = await referenceData.tutors.saveTutorData()
															if !updateResult {
																updateMessage = "Critical Error: Could not save Tutor data when updaing Tutor \(tutorName)"
															}
														}
													}
												}
											}
										} catch {
											print("Error renaming Tutor Details sheet - Error: \(error)")
											updateResult = false
											updateMessage = "Critical Error: Could not get File ID for Tutor Timesheet \(currentTimesheetName)"
										}
									}
								} catch {
									print("Error renaming Timesheet - Error: \(error)")
									updateResult = false
									updateMessage = "Critical Error: Could not rename Tutor Details sheet for Tutor \(tutorName)"
								}
							}
						} catch {
							print("ERROR: Could not write Tutor name to Tutor Details sheet for Tutor")
						}
					} else {
						print("Tutor Details Sheet with name \(originalTutorName) not found.")
						updateResult = false
						updateMessage = "Critical Error: Tutor Details Sheet with name \(originalTutorName) not found updating Tutor"
					}
				} catch {
					print("Error retrieving Tutor Details sheet ID - Error: \(error)")
					updateResult = false
					updateMessage = "Critical Error: Tutor Details Sheet with name \(originalTutorName) not found updating Tutor"
				}
			}
		} else {
			// Not updating Tutor Name
			referenceData.tutors.tutorsList[tutorNum].tutorMaxStudents = maxStudents
			referenceData.tutors.tutorsList[tutorNum].tutorEmail = contactEmail
			referenceData.tutors.tutorsList[tutorNum].tutorPhone = contactPhone
			updateResult = await referenceData.tutors.saveTutorData()
			if !updateResult {
				updateMessage = "Critical Error: Could not save Tutor data when updaing Tutor \(tutorName)"
			}
		}
		
		return(updateResult, updateMessage)
		
	}

	func renameTutorInBilledTutorMonth(originalTutorName: String, newTutorName: String, monthName: String, yearName: String) async -> Bool {
		var renameResult: Bool = false
		var tutorBillingFileID: String = ""
		
		let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
		
		let tutorBillingMonth = TutorBillingMonth(monthName: monthName)
		
		// Get the fileID of the Billed Tutor spreadsheet for the year
		do {
			(renameResult, tutorBillingFileID) = try await getFileID(fileName: tutorBillingFileName)
			if renameResult {
				// Read the data from the Billed Tutor spreadsheet for the previous month
				renameResult = await tutorBillingMonth.loadTutorBillingMonth(monthName: monthName, tutorBillingFileID: tutorBillingFileID)
				if renameResult {
					// Add new the Tutor to Billed Tutor list for the month
					let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: originalTutorName)
					if billedTutorFound {
						tutorBillingMonth.tutorBillingRows[billedTutorNum].tutorName = newTutorName
						// Save the updated Billed Tutor list for the month
						renameResult = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName)
					} else {
						print("WARNING: Billed Tutor \(originalTutorName) not found in Billed Tutor sheet for \(monthName) \(yearName)")
						renameResult = false
					}
				}
			}
		} catch {
			print("Could not get FileID for file: \(tutorBillingFileName)")
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
			validationMessage = "Error: Tutor Name: \(tutorName) Contains a Comma\n"
		}
		
		let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
		if tutorFoundFlag {
			validationResult = false
			validationMessage += "Error: Tutor Name \(tutorName) Already Exists\n"
		}
            
		let validEmailFlag = isValidEmail(tutorEmail)
		if !validEmailFlag {
			validationResult = false
			validationMessage += " Error: Tutor Email \(tutorEmail) is Not Valid\n"
		}
            
		let validPhoneFlag = isValidPhone(tutorPhone)
		if !validPhoneFlag {
			validationResult = false
			validationMessage += "Error: Phone Number \(tutorPhone) Is Not Valid\n"
		}
            
		return(validationResult, validationMessage)
        }

	func validateUpdatedTutor(originalTutorName: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorMaxStudents: Int, referenceData: ReferenceData) -> (Bool, String) {
		var validationResult = true
		var validationMessage = " "
            
		let commaFlag = tutorName.contains(",")
		if commaFlag {
			validationResult = false
			validationMessage = "Error: Tutor Name: \(tutorName) Contains a Comma\n"
		}
		
		let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
		if tutorFoundFlag && originalTutorName != tutorName {                   // Check if renaming Tutor to an existing Tutor name
			validationResult = false
			validationMessage += "Error: Tutor name: \(tutorName) already exists\n"
		}
            
		let validEmailFlag = isValidEmail(tutorEmail)
		if !validEmailFlag {
			validationResult = false
			validationMessage += " Error: Email \(tutorEmail) is Not Valid\n"
		}
	    
		let validPhoneFlag = isValidPhone(tutorPhone)
		if !validPhoneFlag {
			validationResult = false
			validationMessage += "Error: Phone Number \(tutorPhone) Is Not Valid\n"
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
					print("Deleting Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
					referenceData.tutors.tutorsList[tutorNum].markDeleted()
					deleteResult = await referenceData.tutors.saveTutorData()
					if !deleteResult {
						deleteMessage = "Critical Error: Could not save Tutor data deleting Tutor"
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
							deleteMessage = "Critical Error: Could not save Services Data when deleting Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
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
									deleteMessage = "Critical Error: Could not get File ID for Tutor Billing File \(tutorBillingFileName)"
								} else {
									// Read in the Billed Tutors for the previous month
									deleteResult = await tutorBillingMonth.loadTutorBillingMonth(monthName: prevMonthName, tutorBillingFileID: tutorBillingFileID)
									if !deleteResult {
										deleteMessage = "Critical Error: Could not load Tutor Billing data for \(prevMonthName)"
									} else {
										// Remove the Tutor to Billed Tutor list for the month
										let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
										let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
										if billedTutorFound != false {
											tutorBillingMonth.deleteBilledTutor(billedTutorNum: billedTutorNum)
										}
										// Save the updated Billed Tutor list for the month
										deleteResult = await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: prevMonthName)
										if !deleteResult {
											deleteMessage = "Critical Error: Could not save Tutor Billing data for \(prevMonthName)"
										} else {
											
											// Delete the Tutor Details sheet for the Tutor
											do {
												if let sheetID = try await getSheetIdByName(spreadsheetId: tutorDetailsFileID, sheetName: tutorName) {
													tutorSheetID = sheetID
													let deleteFileData = try await deleteSheet(spreadsheetId: tutorDetailsFileID, sheetId: tutorSheetID)
													if deleteFileData == nil {
														deleteMessage = "Critical Error: Could not delete Tutor Details sheet for \(tutorName)"
													}
												} else {
													deleteResult = false
													deleteMessage = "Critical Error: Could not get Sheet ID for Tutor \(tutorName) in Tutor Details spreadsheet"
												}
											} catch {
												print("Error: could not get Sheet ID for Tutor \(tutorName) in Tutor Details spreadsheet to delete Tutors details sheet")
												deleteResult = false
												deleteMessage = "Error: could not get Sheet ID for Tutor \(tutorName) in Tutor Details spreadsheet to delete Tutors details sheet"
											}
										}
									}
								}
							} catch {
								print("ERROR: Could not get File ID for Billed Tutor File: \(tutorBillingFileName)")
								deleteResult = false
								deleteMessage = "ERROR: Could not get File ID for Billed Tutor File: \(tutorBillingFileName)"
							}
						}
					}
				} else {
					deleteMessage = "Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					print("Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
					deleteResult = false
				}
			}
		}
		if deleteResult {
			deleteResult = await referenceData.dataCounts.saveDataCounts()
			if !deleteResult {
				deleteMessage = "Critical Error: Could not save Data Counts deleting Tutor "
			}
		}
		
		return(deleteResult, deleteMessage)
	}
        
    
	func assignStudent(studentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var assignResult: Bool = true
		var assignMessage: String = ""
		
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				print("Assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
				let studentNum1 = studentNum
				print(studentNum, studentNum1)
                
				referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
				
				assignResult = await referenceData.students.saveStudentData()
				if assignResult {
					let dateFormatter = DateFormatter()
					dateFormatter.dateFormat = "yyyy/MM/dd"
					let assignedDate = dateFormatter.string(from: Date())
					
					let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: referenceData.students.studentsList[studentNum].studentName, clientName: referenceData.students.studentsList[studentNum].studentGuardian, clientEmail: referenceData.students.studentsList[studentNum].studentEmail, clientPhone: referenceData.students.studentsList[studentNum].studentPhone, assignedDate: assignedDate)
					assignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
					if assignResult {
						assignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
						if !assignResult {
							assignMessage = "Critical Error: could not save Tutor data assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						}
					} else {
						assignMessage = "Critical Error: could not save Tutor Details assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					}
				} else {
					assignMessage = "Critical Error: could not save Student data assigning Student \(referenceData.students.studentsList[studentNum].studentName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				}
			}
		}
		return(assignResult, assignMessage)
	}

	func assignService(serviceIndex: Set<Tutor.ID>, tutorNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var assignResult: Bool = true
		var assignMessage: String = ""
		
		for objectID in serviceIndex {
			if let serviceNum = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
			print(referenceData.services.servicesList[serviceNum].serviceTimesheetName)
		
				print("Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
				//               referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
				//               referenceData.students.saveStudentData()
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
								assignMessage = "Critical Error: Could not save Services data assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							}
						} else {
							assignMessage = "Critical Error: Could not save Tutors data assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						}
					} else {
						assignMessage = "Critical Error: Could not save Tutor Details data when adding  Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					}
				} else {
					print("Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) already assigned to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
				}
			}
		}
		return(assignResult, assignMessage)
	}
	
	func assignTutorServiceSet(serviceNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var assignResult: Bool = true
		var assignMessage: String = ""
		
		print("Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor")
 
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				print(referenceData.tutors.tutorsList[tutorNum].tutorName)
				let (tutorServiceFound, _) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByKey(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey)
				if !tutorServiceFound {
					//               referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
					//               referenceData.students.saveStudentData()
					
					let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName, billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1,  cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
					assignResult = await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
					if assignResult {
						assignResult = await referenceData.tutors.saveTutorData()                    // increased Student count
						if assignResult {
							referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
							assignResult = await referenceData.services.saveServiceData()
							if !assignResult {
								assignMessage = "Critical Error: Could not save Service data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							}
						} else {
							assignMessage = "Critical Error: Could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						}
					} else {
						assignMessage = "Critical Error: Could not save Tutor Details for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					}
				} else {
					assignResult = false
					assignMessage = "Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) already assigned Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName)"
				}
			}
		}
		return(assignResult, assignMessage)
	}
    
	func unassignTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var unassignResult: Bool = true
		var unassignMsg: String = " "
		
		print("Unssigning Service from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
		
		let serviceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
		let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: serviceKey )
		if serviceFound {
			referenceData.services.servicesList[serviceNum].decreaseServiceUseCount()
			unassignResult = await referenceData.services.saveServiceData()
			if unassignResult {
				unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorService(serviceKey: serviceKey)
				if !unassignResult {
					unassignMsg = "Critical Error: could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				} else {
					unassignResult = await referenceData.tutors.saveTutorData()      // decreased Service count for Tutor
					if !unassignResult {
						unassignMsg = "Critical Error: could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					}
				}
			} else {
				unassignMsg = "Critical Error: could not save Service data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
			}
		} else {
			unassignResult = false
			unassignMsg = "Tutor Service \(referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName) not Found for tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
		}
		return(unassignResult, unassignMsg)
	}
    
	func unassignTutorServiceSet(tutorNum: Int, tutorServiceIndex: Set<TutorService.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unassignResult: Bool = true
		var unassignMsg: String = " "
		
		for objectID in tutorServiceIndex {
			if let tutorServiceNum = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
				print("Unassigning Service from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
				
				let serviceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
				let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: serviceKey )
				if serviceFound {
					referenceData.services.servicesList[serviceNum].decreaseServiceUseCount()
					unassignResult = await referenceData.services.saveServiceData()
					if unassignResult {
						unassignResult = await referenceData.tutors.tutorsList[tutorNum].removeTutorService(serviceKey: serviceKey)
						if !unassignResult {
							unassignMsg = "Critical Error: could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
						} else {
							unassignResult = await referenceData.tutors.saveTutorData()      // decreased Service count for Tutor
							if !unassignResult {
								unassignMsg = "Critical Error: could not save Tutor data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
							}
						}
					} else {
						unassignMsg = "Critical Error: could not save Service data when assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					}
				} else {
					unassignResult = false
					unassignMsg = "Tutor Service \(referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName) not Found for tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
				}
			}
		}
		return(unassignResult, unassignMsg)
	}
	func updateTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData, timesheetName: String, invoiceName: String, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) async -> (Bool, String) {
		
		var updateResult: Bool = true
		var updateMessage: String = ""
		
		updateResult = await referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
		if !updateResult {
			updateMessage = "Critical Error: Could not save Tutor Service \(timesheetName) for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) "
		}
		return(updateResult, updateMessage)
	}
	
	func suspendTutor(tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var suspendResult: Bool = true
		var suspendMessage: String = ""
		
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus == "Unassigned" {
					referenceData.tutors.tutorsList[tutorNum].suspendTutor()
					suspendResult = await referenceData.tutors.saveTutorData()
					if !suspendResult {
						suspendMessage = "Critical Error: Cannot save Tutors Data when suspending Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					}
				} else {
					suspendResult = false
					suspendMessage += "Cannot Suspend Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) because Status is \(referenceData.tutors.tutorsList[tutorNum].tutorStatus) \n"
				}
			}
		}
		return(suspendResult, suspendMessage)
	}
	
	func unsuspendTutor(tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unsuspendResult: Bool = true
		var unsuspendMessage: String = ""
		
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus == "Suspended" {
					referenceData.tutors.tutorsList[tutorNum].unsuspendTutor()
					unsuspendResult = await referenceData.tutors.saveTutorData()
					if !unsuspendResult {
						unsuspendMessage = "Critical Error: could not save Tutor Data when unsuspending Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					}
				} else {
					unsuspendResult = false
					unsuspendMessage += "Cannot Unsuspend Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName) because Status is not Suspended \n"
				}
			}
		}
		return(unsuspendResult, unsuspendMessage)
	}
    
   
	func copyNewTimesheet(tutorName: String, tutorEmail: String) async -> Bool {
		var copyResult: Bool = true

		var newTimesheetFileID: String = ""
		var copiedFileData = [String : Any]()
        
		print("Copying New Timesheet for \(tutorName)")
      
		let formatter = DateFormatter()
		formatter.setLocalizedDateFormatFromTemplate("YYYY")
		let currentYear = formatter.string(from: Date.now)
		let newTimesheetName  = "Timesheet " + currentYear + " " + tutorName
		do {
			if let copiedFileData = try await copyGoogleDriveFile(sourceFileId: timesheetTemplateFileID, newFileName: newTimesheetName) {

				if let fileID = copiedFileData["id"] as? String {
					newTimesheetFileID = fileID
					
					do {
						var copyFileData = try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: tutorEmail)
						if let copyFileData = copyFileData {
							let range = PgmConstants.timesheetTutorNameCell
							do {
								copyResult = try await writeSheetCells(fileID: newTimesheetFileID, range:range, values: [[tutorName]])
							} catch {
								print("ERROR: can not write Tutor Name into new Tutor Timesheet")
								copyResult = false
							}
						} else {
							copyResult = false
						}
						
						copyFileData = try await addPermissionToFile(fileId: tutorDetailsFileID, role: "reader", type: "user", emailAddress: tutorEmail)
						if let copyFileData = copyFileData {
							print("Granted Tutor \(tutorName) read access to Tutor Details File Name")
						} else {
							print("Error: Can not grant Tutor read access to Tutor Details spreadsheet")
							copyResult = false
						}
					} catch {
						print("Could not add access permission to new Timesheet for Tutor: \(tutorName)")
						copyResult = false
					}
				} else {
					copyResult = false
					print("No valid string found for the key 'name'")
				}
			} else {
				copyResult = false
			}
		} catch {
			print("Critical Error:  Could not create Timesheet for Tutor: \(tutorName)")
			copyResult = false
		}

		return(copyResult)
	}
         
	func createNewDetailsSheet(tutorName: String, tutorKey: String) async -> Bool {
		var createResult: Bool = true
	    
		var updateValues = [[String]]()
		
		do {
			let newSheetData = try await createNewSheetInSpreadsheet(spreadsheetId: tutorDetailsFileID, sheetTitle: tutorName)
			if let newSheetData = newSheetData {
				var range = tutorName + PgmConstants.tutorHeader1Range
				updateValues = PgmConstants.tutorHeader1Array
				do {
					createResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues)
					if createResult {
						range = tutorName + PgmConstants.tutorHeader2Range
						updateValues = PgmConstants.tutorHeader2Array
						do {
							createResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues)
							if createResult {
								range = tutorName + PgmConstants.tutorHeader3Range
								updateValues = [[tutorKey, tutorName]]
								do {
									createResult = try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues)
								} catch {
									print("Failed to save Tutor Details Header 3 data for tutor \(tutorName):\(error.localizedDescription)")
									createResult = false
								}
							}
						} catch {
							print("Failed to save Tutor Details Header 2 data for Tutor \(tutorName):\(error.localizedDescription)")
							createResult = false
						}
					}
				} catch {
					print("Failed to save Tutor Details Header 1 data for Tutor \(tutorName):\(error.localizedDescription)")
					createResult = false
				}
			} else {
				createResult = false
			}
		} catch {
			print("ERROR: could not create new Tutor Details sheet for tutor \(tutorName)")
			createResult = false
		}
		return(createResult)
	}
 
    
	func printTutor(indexes: Set<Service.ID>, referenceData: ReferenceData) {
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
    
}
