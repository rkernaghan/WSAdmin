//
//  TutorMgmtVM.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher


@Observable class TutorMgmtVM  {
    
    
    func addNewTutor(referenceData: ReferenceData, tutorName: String, tutorEmail: String, tutorPhone: String, maxStudents: Int) async {
            var result: Bool = true
            var tutorBillingFileID: String = ""
            
	    await referenceData.dataCounts.increaseTotalTutorCount()
	    await referenceData.dataCounts.saveDataCounts()
	    
            let newTutorKey = PgmConstants.tutorKeyPrefix + String(format: "%04d", referenceData.dataCounts.highestTutorKey)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDate = dateFormatter.string(from: Date())
            //       let maxStudentsInt = Int(maxStudents) ?? 0
            
            let newTutor = Tutor(tutorKey: newTutorKey, tutorName: tutorName, tutorEmail: tutorEmail, tutorPhone: tutorPhone, tutorStatus: "Unassigned", tutorStartDate: startDate, tutorEndDate: " ", tutorMaxStudents: maxStudents, tutorStudentCount: 0, tutorServiceCount: 0, tutorTotalSessions: 0, tutorTotalCost: 0.0, tutorTotalRevenue: 0.0, tutorTotalProfit: 0.0)
            referenceData.tutors.loadTutor(newTutor: newTutor)
            await referenceData.tutors.saveTutorData()
            
// Create a new Tutor Details sheet for the new Tutor
            await createNewDetailsSheet(tutorName: tutorName, tutorKey: newTutorKey)
// Create a new Timesheet for the Tutor
	    await copyNewTimesheet(tutorName: tutorName, tutorEmail: tutorEmail)
// Add the new Tutor to the Billed Tutor list for the previous month
            let (prevMonthName, prevMonthYear) = getPrevMonthYear()
            await self.addTutorToBilledTutorMonth(tutorName: tutorName, monthName: prevMonthName, yearName: prevMonthYear)
	    
// Assign all Base Services to new Tutor
	    let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
	    var serviceNum = 0
	    let serviceCount = referenceData.services.servicesList.count
	    while serviceNum < serviceCount {
		    if referenceData.services.servicesList[serviceNum].serviceType == .Base {
			    let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName,  billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1, cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
			    await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
		    }
		    serviceNum += 1
	    }
	    
        
    }
  
    func addTutorToBilledTutorMonth(tutorName: String, monthName: String, yearName: String) async {
            var result: Bool = false
            var tutorBillingFileID: String = ""
            
            let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
       
            let tutorBillingMonth = TutorBillingMonth()
           
    // Get the fileID of the Billed Tutor spreadsheet for the year
            do {
                    (result, tutorBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
            } catch {
                    print("Could not get FileID for file: \(tutorBillingFileName)")
            }
    // Read the data from the Billed Tutor spreadsheet for the previous month
            await tutorBillingMonth.loadTutorBillingMonthAsync(monthName: monthName, tutorBillingFileID: tutorBillingFileID)
    // Add new the Tutor to Billed Tutor list for the month
            let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
            if !billedTutorFound {
                    tutorBillingMonth.addNewBilledTutor(tutorName: tutorName)
    // Save the updated Billed Tutor list for the month
                    await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName)
            }
    }

    func renameTutorInBilledTutorMonth(originalTutorName: String, newTutorName: String, monthName: String, yearName: String) async {
            var result: Bool = false
            var tutorBillingFileID: String = ""
            
            let tutorBillingFileName = tutorBillingFileNamePrefix + yearName
       
            let tutorBillingMonth = TutorBillingMonth()
           
    // Get the fileID of the Billed Tutor spreadsheet for the year
            do {
                    (result, tutorBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
            } catch {
                    print("Could not get FileID for file: \(tutorBillingFileName)")
            }
    // Read the data from the Billed Tutor spreadsheet for the previous month
            await tutorBillingMonth.loadTutorBillingMonthAsync(monthName: monthName, tutorBillingFileID: tutorBillingFileID)
    // Add new the Tutor to Billed Tutor list for the month
            let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: originalTutorName)
            if billedTutorFound {
                    tutorBillingMonth.tutorBillingRows[billedTutorNum].tutorName = newTutorName
    // Save the updated Billed Tutor list for the month
                    await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: monthName)
            } else {
                    print("WARNING: Billed Tutor \(originalTutorName) not found in Billed Tutor sheet for \(monthName) \(yearName)")
            }
    }
    
    func updateTutor(tutorNum: Int, referenceData: ReferenceData, tutorName: String, originalTutorName: String, contactEmail: String, contactPhone: String, maxStudents: Int) async {
            var tutorSheetID: Int = 0
// Check if Tutor name has changed with this update
            if originalTutorName != tutorName {
 
// Change the name in the Tutor Billing spreadsheet for the previous month and current month (in case this month already billed and Tutor in this month's Billed Tutor sheet)
                    let (prevMonthName, prevMonthYear) = getPrevMonthYear()
                    await self.renameTutorInBilledTutorMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: prevMonthName, yearName: prevMonthYear)
                    let (currentMonthName, currentMonthYear) = getCurrentMonthYear()
                    await self.renameTutorInBilledTutorMonth(originalTutorName: originalTutorName, newTutorName: tutorName, monthName: currentMonthName, yearName: currentMonthYear)
            
// Change the sheet name of the Tutor Details sheet and the name in the tutor's sheet
// First get the sheet ID in the spreadsheet
                    do {
                            if let sheetID = try await getSheetIdByName(spreadsheetId: tutorDetailsFileID, sheetName: originalTutorName) {
                                    print("Found sheet ID: \(sheetID)")
                                    tutorSheetID = sheetID
                            } else {
                                    print("Tutor Details Sheet with name \(originalTutorName) not found.")
                            }
                    } catch {
                            print("Error retrieving Tutor Details sheet ID - Error: \(error)")
                    }
// Then rename the Tutor's sheet in the Tutor Details spreadsheet and change the Tutor name in the Timesheet
		    let range = originalTutorName + PgmConstants.tutorDataTutorNameCell
		    do {
			    try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: [[tutorName]])
		    } catch {
			    print("ERROR: Could not write Tutor name to Tutor Details sheet for Tutor")
		    }
		    
		    do {
                            try await renameSheetInSpreadsheet(spreadsheetId: tutorDetailsFileID, sheetId: tutorSheetID, newSheetName: tutorName)
                            print("Tutor Details sheet renamed successfully!")
                    } catch {
                            print("Error renaming Tutor Details sheet - Error: \(error)")
                    }
		    
// Change the name of the Tutor's timesheet and the Tutor name within the Timesheet RefData sheet
                    let formatter = DateFormatter()
                    formatter.setLocalizedDateFormatFromTemplate("YYYY")
                    let currentYear = formatter.string(from: Date.now)
                    let newTutorTimesheetName = "Timesheet " + currentYear + " " + tutorName
                    let currentTimesheetName = "Timesheet " + currentYear + " " + originalTutorName
                    
                    do {
                            let (_, tutorTimesheetFileID) = try await getFileIDAsync(fileName: currentTimesheetName)
                            let range = PgmConstants.timesheetTutorNameCell
			    try await writeSheetCells(fileID: tutorTimesheetFileID, range:range, values: [[tutorName]])
                            try await renameGoogleDriveFile(fileId: tutorTimesheetFileID, newName: newTutorTimesheetName)
                            print("Timesheet renamed successfully!")
                    } catch {
                            print("Error renaming Timesheet - Error: \(error)")
                    }
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
			    await referenceData.students.saveStudentData()
		    }
            }
// Change the name in the Tutors list in the Reference Data sheet and save it
            referenceData.tutors.tutorsList[tutorNum].updateTutor(tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
            let saveResult = await referenceData.tutors.saveTutorData()

        }
    
	func validateNewTutor(tutorName: String, tutorEmail: String, tutorPhone: String, tutorMaxStudents: Int, referenceData: ReferenceData)->(Bool, String) {
		var validationResult = true
		var validationMessage = " "
            
		let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
		if tutorFoundFlag {
			validationResult = false
			validationMessage += "Error: Tutor Name \(tutorName) Already Exists"
		}
            
		let validEmailFlag = isValidEmail(tutorEmail)
		if !validEmailFlag {
			validationResult = false
			validationMessage += " Error: Tutor Email \(tutorEmail) is Not Valid"
		}
            
		let validPhoneFlag = isValidPhone(tutorPhone)
		if !validPhoneFlag {
			validationResult = false
			validationMessage += "Error: Phone Number \(tutorPhone) Is Not Valid"
		}
            
		return(validationResult, validationMessage)
        }

	func validateUpdatedTutor(originalTutorName: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorMaxStudents: Int, referenceData: ReferenceData) -> (Bool, String) {
		var validationResult = true
		var validationMessage = " "
            
		let (tutorFoundFlag, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
		if tutorFoundFlag && originalTutorName != tutorName {                   // Check if renaming Tutor to an existing Tutor name
			validationResult = false
			validationMessage += "Error: Tutor name: \(tutorName) already exists"
		}
            
		let validEmailFlag = isValidEmail(tutorEmail)
		if !validEmailFlag {
			validationResult = false
			validationMessage += " Error: Email \(tutorEmail) is Not Valid"
		}
	    
		let validPhoneFlag = isValidPhone(tutorPhone)
		if !validPhoneFlag {
			validationResult = false
			validationMessage += "Error: Phone Number \(tutorPhone) Is Not Valid"
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
		
		print("Deleting Tutor")
		
		for objectID in indexes {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.tutors.tutorsList[tutorNum].tutorStudentCount == 0 {
					referenceData.tutors.tutorsList[tutorNum].markDeleted()
					await referenceData.tutors.saveTutorData()
					await referenceData.dataCounts.decreaseActiveStudentCount()
// Remove Tutor from Billed Tutor list for the previous month
					let (prevMonthName, billingYear) = getPrevMonthYear()
					let tutorBillingFileName = tutorBillingFileNamePrefix + billingYear
                    
					let tutorBillingMonth = TutorBillingMonth()
                    
// Get the File ID of the Billed Tutor spreadsheet for the year
					do {
						let (result, tutorBillingFileID) = try await getFileIDAsync(fileName: tutorBillingFileName)
					} catch {
						print("ERROR: Could not get File ID for Billed Tutor File: \(tutorBillingFileName)")
					}
// Read in the Billed Tutors for the previous month
					await tutorBillingMonth.loadTutorBillingMonthAsync(monthName: prevMonthName, tutorBillingFileID: tutorBillingFileID)
// Add the new Tutor to Billed Tutor list for the month
					let tutorName = referenceData.tutors.tutorsList[tutorNum].tutorName
					let (billedTutorFound, billedTutorNum) = tutorBillingMonth.findBilledTutorByName(billedTutorName: tutorName)
					if billedTutorFound != false {
						tutorBillingMonth.deleteBilledTutor(billedTutorNum: billedTutorNum)
					}
// Save the updated Billed Tutor list for the month
					await tutorBillingMonth.saveTutorBillingData(tutorBillingFileID: tutorBillingFileID, billingMonth: "Sept")
					
				} else {
					deleteMessage = "Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
					print("Error: \(referenceData.tutors.tutorsList[tutorNum].tutorStudentCount) Students still assigned to \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
					deleteResult = false
                    
				}
			}
		}
		return(deleteResult, deleteMessage)
	}
        
	func unDeleteTutor(indexes: Set<Tutor.ID>, referenceData: ReferenceData) async -> (Bool, String) {
		var unDeleteResult = true
		var unDeleteMessage = " "
		print("UnDeleting Tutor")
        
		for objectID in indexes {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				if referenceData.tutors.tutorsList[tutorNum].tutorStatus == "Deleted" {
					referenceData.tutors.tutorsList[tutorNum].markUnDeleted()
					await referenceData.tutors.saveTutorData()
					await referenceData.dataCounts.increaseActiveTutorCount()
				} else {
					unDeleteMessage = "Error: \(referenceData.tutors.tutorsList[tutorNum].tutorName) Can not be undeleted as status is \(referenceData.tutors.tutorsList[tutorNum].tutorStatus)"
					print("Error: \(referenceData.tutors.tutorsList[tutorNum].tutorName) Can not be undeleted as status is \(referenceData.tutors.tutorsList[tutorNum].tutorStatus)")
					unDeleteResult = false
				}
			}
		}
		return(unDeleteResult, unDeleteMessage)
	}
    
	func assignStudent(studentIndex: Set<Student.ID>, tutorNum: Int, referenceData: ReferenceData) async {
		print("Assigning Student to Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)")
 
		for objectID in studentIndex {
			if let studentNum = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				print(referenceData.students.studentsList[studentNum].studentName)
				let studentNum1 = studentNum
				print(studentNum, studentNum1)
                
				referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
				
				await referenceData.students.saveStudentData()
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd"
				let assignedDate = dateFormatter.string(from: Date())
				
				let newTutorStudent = TutorStudent(studentKey: referenceData.students.studentsList[studentNum].studentKey, studentName: referenceData.students.studentsList[studentNum].studentName, clientName: referenceData.students.studentsList[studentNum].studentGuardian, clientEmail: referenceData.students.studentsList[studentNum].studentEmail, clientPhone: referenceData.students.studentsList[studentNum].studentPhone, assignedDate: assignedDate)
				await referenceData.tutors.tutorsList[tutorNum].addNewTutorStudent(newTutorStudent: newTutorStudent)
				await referenceData.tutors.saveTutorData()                    // increased Student count
			}
		}
	}

	func assignTutorService(serviceNum: Int, tutorIndex: Set<Tutor.ID>, referenceData: ReferenceData) async {
        
		print("Assigning Service \(referenceData.services.servicesList[serviceNum].serviceTimesheetName) to Tutor")
 
		for objectID in tutorIndex {
			if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
				print(referenceData.tutors.tutorsList[tutorNum].tutorName)
				
		 //               referenceData.students.studentsList[studentNum].assignTutor(tutorNum: tutorNum, referenceData: referenceData)
		 //               referenceData.students.saveStudentData()
				
				let newTutorService = TutorService(serviceKey: referenceData.services.servicesList[serviceNum].serviceKey, timesheetName: referenceData.services.servicesList[serviceNum].serviceTimesheetName, invoiceName: referenceData.services.servicesList[serviceNum].serviceInvoiceName, billingType: referenceData.services.servicesList[serviceNum].serviceBillingType, cost1: referenceData.services.servicesList[serviceNum].serviceCost1,  cost2: referenceData.services.servicesList[serviceNum].serviceCost2, cost3: referenceData.services.servicesList[serviceNum].serviceCost3, price1: referenceData.services.servicesList[serviceNum].servicePrice1, price2: referenceData.services.servicesList[serviceNum].servicePrice2, price3: referenceData.services.servicesList[serviceNum].servicePrice3)
				await referenceData.tutors.tutorsList[tutorNum].addNewTutorService(newTutorService: newTutorService)
				await referenceData.tutors.saveTutorData()                    // increased Student count
				referenceData.services.servicesList[serviceNum].increaseServiceUseCount()
				await referenceData.services.saveServiceData()
			}
		}
	}
    
	func unassignTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData) async -> (Bool, String) {
		var unassignResult: Bool = true
		var unassignMsg: String = " "
        
			let serviceKey = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].serviceKey
			let (serviceFound, serviceNum) = referenceData.services.findServiceByKey(serviceKey: serviceKey )
			if serviceFound {
				referenceData.services.servicesList[serviceNum].decreaseServiceUseCount()
				await referenceData.services.saveServiceData()
				await referenceData.tutors.tutorsList[tutorNum].removeTutorService(serviceKey: serviceKey)
			} else {
				unassignResult = false
				unassignMsg = "Tutor Service \(referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName) not Found for tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)"
			}
		return(unassignResult, unassignMsg)
	}
    
	func updateTutorService(tutorNum: Int, tutorServiceNum: Int, referenceData: ReferenceData, timesheetName: String, invoiceName: String, billingType: BillingTypeOption, cost1: Float, cost2: Float, cost3: Float, price1: Float, price2: Float, price3: Float) async {

		await referenceData.tutors.tutorsList[tutorNum].updateTutorService(tutorServiceNum: tutorServiceNum, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
	}
    
   
	func copyNewTimesheet(tutorName: String, tutorEmail: String) async {

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
				} else {
					print("No valid string found for the key 'name'")
				}
				
			}
		} catch {
			print("ERROR:  Could not create Timesheet for Tutor: \(tutorName)")
		}
       
	print("New Timesheet File ID for tutor \(tutorName) is \(newTimesheetFileID)")

		do {
			try await addPermissionToFile(fileId: newTimesheetFileID, role: "writer", type: "user", emailAddress: tutorEmail)
		} catch {
			print("Could not add access permission to new Timesheet for Tutor: \(tutorName)")
		}
		
		let range = PgmConstants.timesheetTutorNameCell
		do {
			try await writeSheetCells(fileID: newTimesheetFileID, range:range, values: [[tutorName]])
		} catch {
			print("ERROR: can not write Tutor Name into new Tutor Timesheet")
		}
	}
         
	func createNewDetailsSheet(tutorName: String, tutorKey: String) async {
	    
		var updateValues = [[String]]()
		
		do {
			try await createNewSheetInSpreadsheet(spreadsheetId: tutorDetailsFileID, sheetTitle: tutorName)
		} catch {
			print("ERROR: could not create new Tutor Details sheet for tutor \(tutorName)")
		}
					    
		var range = tutorName + PgmConstants.tutorHeader1Range
		updateValues = PgmConstants.tutorHeader1Array
		do {
			try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues)
		} catch {
			print("Failed to save Tutor Details Header 1 data for Tutor \(tutorName):\(error.localizedDescription)")
		}
		
		range = tutorName + PgmConstants.tutorHeader2Range
		updateValues = PgmConstants.tutorHeader2Array
		do {
			try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues)
		} catch {
			print("Failed to save Tutor Details Header 2 data for Tutor \(tutorName):\(error.localizedDescription)")
		}
		    
		range = tutorName + PgmConstants.tutorHeader3Range
		updateValues = [[tutorKey, tutorName]]
		do {
			try await writeSheetCells(fileID: tutorDetailsFileID, range:range, values: updateValues)
		} catch {
			print("Failed to save Tutor Details Header 3 data for tutor \(tutorName):\(error.localizedDescription)")
		}
		
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
    
	func createNewDetailsSheetOLD(tutorName: String, tutorKey: String) {
	    
	    var spreadsheetID: String
	    var updateValues: [[String]] = []
	    
	    let batchUpdate = GTLRSheets_BatchUpdateSpreadsheetRequest.init()
	    let request = GTLRSheets_Request.init()
	    let sheetService = GTLRSheetsService()
	    let currentUser = GIDSignIn.sharedInstance.currentUser
	    
	    sheetService.authorizer = currentUser?.fetcherAuthorizer
	    let properties = GTLRSheets_SheetProperties.init()
	    properties.title = tutorName
	    
	    let sheetRequest = GTLRSheets_AddSheetRequest.init()
	    sheetRequest.properties = properties
	    
	    request.addSheet = sheetRequest
	    
	    batchUpdate.requests = [request]
	    
	    let createQuery = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batchUpdate, spreadsheetId: tutorDetailsFileID)
	    
	    sheetService.executeQuery(createQuery) { (ticket, result, err) in
		if let error = err {
		    print(error)
		    print("Error with creating Tutor Details sheet for tutor \(tutorName):\(error.localizedDescription)")
		} else {
		    print("Tutor Details Sheet added for tutor \(tutorName)")
		}
	       
		var range = tutorName + PgmConstants.tutorHeader1Range
		updateValues = PgmConstants.tutorHeader1Array
		let valueRange1 = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
		valueRange1.majorDimension = "ROWS" // Indicates horizontal row insert
		valueRange1.range = range
		valueRange1.values = updateValues
		let query1 = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange1, spreadsheetId: tutorDetailsFileID, range: range)
		query1.valueInputOption = "USER_ENTERED"
		sheetService.executeQuery(query1) { ticket, object, error in
		    if let error = error {
			print(error)
			print("Failed to save Tutor Details Header 1 data for Tutor \(tutorName):\(error.localizedDescription)")
			return
		    }
		    else {
			print("Tutor Details Header 1 saved for tutor \(tutorName)")
		    }
		}
		
		range = tutorName + PgmConstants.tutorHeader2Range
		updateValues = PgmConstants.tutorHeader2Array
		let valueRange2 = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
		valueRange2.majorDimension = "ROWS" // Indicates horizontal row insert
		valueRange2.range = range
		valueRange2.values = updateValues
		let query2 = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange2, spreadsheetId: tutorDetailsFileID, range: range)
		query2.valueInputOption = "USER_ENTERED"
		sheetService.executeQuery(query2) { ticket, object, error in
		    if let error = error {
			print(error)
			print("Failed to save Tutor Details Header 2 data for Tutor \(tutorName):\(error.localizedDescription)")
			return
		    }
		    else {
			print("Tutor Details Header 2 saved tutor \(tutorName)")
		    }
		}
		
		range = tutorName + PgmConstants.tutorHeader3Range
		updateValues = [[tutorKey, tutorName]]
		let valueRange3 = GTLRSheets_ValueRange() // GTLRSheets_ValueRange holds the updated values and other params
		valueRange3.majorDimension = "COLUMNS" // Indicates horizontal row insert
		valueRange3.range = range
		valueRange3.values = updateValues
		let query3 = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange3, spreadsheetId: tutorDetailsFileID, range: range)
		query3.valueInputOption = "USER_ENTERED"
		sheetService.executeQuery(query3) { ticket, object, error in
		    if let error = error {
			print(error)
			print("Failed to save Tutor Details Header 3 data for tutor \(tutorName):\(error.localizedDescription)")
			return
		    }
		    else {
			print("Tutor Details Header 3 saved for Tutor \(tutorName)")
		    }
		}
	    }
	}
	
	func addPermissionToDriveFileOLD(fileId: String, tutorEmail: String, role: String, type: String) {
	    let service = GTLRDriveService()
      //      service.authorizer = GTMAppAuthFetcherAuthorization(authState: OAuth2.authState)
	    let currentUser = GIDSignIn.sharedInstance.currentUser
	    service.authorizer = currentUser?.fetcherAuthorizer

	    let permission = GTLRDrive_Permission()
	    permission.role = role  // e.g., "reader", "writer"
	    permission.type = type  // e.g., "user", "group", "domain", "anyone"
	    permission.emailAddress = tutorEmail

	    let query = GTLRDriveQuery_PermissionsCreate.query(withObject: permission, fileId: fileId)
	    
	    service.executeQuery(query) { ticket, permission, error in
		if let error = error {
		    print("Error adding permission: \(error.localizedDescription)")
		} else {
		    print("Permission added successfully for \(tutorEmail)")
		}
	    }
	}
}
