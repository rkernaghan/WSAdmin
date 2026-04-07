//
//  BillingArray.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//
import Foundation

// BillArray has the functions and data to process a set of Timesheets and store them in a format suitable for generating an invoice from.
// A BillArray has one BillClient for each client assigned to the Tutors being billed in this invoice.
// Each BillClient has one or more BillItems, which are the Timesheet rows (tutoring sessions) from the Timesheets for the Tutors being billed

class BillArray {
    
	var billClients = [BillClient]()			// Array of BillClients (one for each client in the invoice)
	var monthName: String					// Name of the month the invoice is for
	
	init(monthName: String) {
		self.monthName = monthName
	}
	
	// Adds a new client to a BillArray
	func addBillClient(newBillClient: BillClient) {
		self.billClients.append(newBillClient)
	}
	
	// Extract the data from a single Tutor Timesheet into arrays of BillItems under each applicable BillClient, each BillItem represents a single tutoring session.
	// The BillArray contains one BillClient for each month's Clients and each tutoring session for that Client is represented by a BillItem under that BillClient
	//
	@MainActor func processTimesheet(timesheet: Timesheet, billingMessages: WindowMessages, referenceData: ReferenceData) {
		var invoiceServiceName = "Not Found"
		var timesheetRowNum = 0
		while timesheetRowNum < timesheet.timesheetRows.count {
			let timesheetClientName = timesheet.timesheetRows[timesheetRowNum].clientName
			
			// If this is the first session processed for a client that month, create a new BillClient in the BillArray
			var (foundFlag, billClientNum) = findBillClientByName(billClientName: timesheetClientName)
			if !foundFlag {
				let newBillClient = BillClient(clientName: timesheetClientName, clientEmail: timesheet.timesheetRows[timesheetRowNum].clientEmail, clientPhone: timesheet.timesheetRows[timesheetRowNum].clientPhone)
				self.addBillClient(newBillClient: newBillClient)
				(foundFlag, billClientNum) = findBillClientByName(billClientName: timesheetClientName)
			}
			// Pull the data from the Timesheet row for a session
			let studentName = timesheet.timesheetRows[timesheetRowNum].studentName
			let serviceDate = timesheet.timesheetRows[timesheetRowNum].serviceDate
			let duration = timesheet.timesheetRows[timesheetRowNum].duration
			let timesheetServiceName = timesheet.timesheetRows[timesheetRowNum].timesheetServiceName
			let (serviceFound, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetServiceName)
			if serviceFound {
				invoiceServiceName = referenceData.services.servicesList[serviceNum].serviceInvoiceName
			}
			
			let notes = timesheet.timesheetRows[timesheetRowNum].notes
			let tutorName = timesheet.timesheetRows[timesheetRowNum].tutorName
			let cost = timesheet.timesheetRows[timesheetRowNum].cost
			//Create new BillItem instance and add it to the BillClients array
			let newBillItem = BillItem(studentName: studentName, serviceDate: serviceDate, duration: duration, timesheetServiceName: timesheetServiceName, invoiceServiceName: invoiceServiceName, notes: notes, cost: cost, tutorName: tutorName)
			self.billClients[billClientNum].billItems.append(newBillItem)
			timesheetRowNum += 1
		}
	}
        
	// Finds a client in a BillArray by client name
	func findBillClientByName(billClientName: String) -> (Bool, Int) {
		var found = false
		
		var billClientNum = 0
		while billClientNum < billClients.count && !found {
			if self.billClients[billClientNum].clientName == billClientName {
				found = true
			} else {
				billClientNum += 1
			}
		}
		return(found, billClientNum)
	}
    
	// 
	@MainActor func generateInvoice(alreadyBilledTutors: [String], referenceData: ReferenceData) -> Invoice {
		var clientName: String = ""
		var clientEmail: String = ""
		var clientInvoiceDate: String = ""
		var clientDueDate: String = ""
		var clientTerms: String = ""
		var dueDateStr: String = ""
		let brandingTheme = "Standard"
		let accountCode = referenceData.dataCounts.accountCode
		let fixedQuantity: String = "1.0"
		
		let newInvoice = Invoice()
		var timesheetServiceName: String = ""
		var duration: Int = 0
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM/dd/yyyy"
		let invoiceDate = dateFormatter.string(from: Date())
		
		// Calculate the due date of the invoice, which is 7 days from today's date
		let calendar = Calendar.current
		let now = Date()
		let dueDate = calendar.date(byAdding: .day, value: 7, to: now)
		if let dueDate = dueDate {
			dueDateStr = dateFormatter.string(from: dueDate)
		} else {
			dueDateStr = invoiceDate
		}
		
		var prevClientName = ""
		var clientNum = 0
		// Loop through each client in the billClients, which is a list of clients being billed in this invoice
		while clientNum < billClients.count {
			//   print("Client : \(billClients[clientNum].clientName) ")
			var billItemNum = 0
			// Loop through each tutoring session for the client
			while billItemNum < billClients[clientNum].billItems.count {
				let tutorName = billClients[clientNum].billItems[billItemNum].tutorName
				let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
				if tutorFound {
					timesheetServiceName = billClients[clientNum].billItems[billItemNum].timesheetServiceName
					let (tutorServiceFound, tutorServiceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByName(serviceName: timesheetServiceName)
					if tutorServiceFound {
						
						// Get the ServiceCode for the Service using TimesheetServiceName
						let (serviceFound, serviceNum) = referenceData.services.findServiceByName(timesheetName: timesheetServiceName)
						if !serviceFound {
							print("Error: could not find Service: \(timesheetServiceName) to get Service Code")
						} else {
							let serviceCode = referenceData.services.servicesList[serviceNum].serviceCode
							
							duration = billClients[clientNum].billItems[billItemNum].duration
							
							let (quantity, rate, cost, price) = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].computeSessionCostPrice(duration: duration)
							
							// Get the Invoice Service Name and remove any commas from the name (there should not be any commas but this is a double check)
							let invoiceServiceName = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].invoiceServiceName.replacingOccurrences(of: ",", with: "")
							
							newInvoice.totalRevenue += price	// Increment the running total Revenue for this invoice
							newInvoice.totalCost += cost		// Increment the running total Cost for this invoice
							newInvoice.totalSessions += 1		// Increment the running total sessions for this invoice
							
							let studentName = billClients[clientNum].billItems[billItemNum].studentName
							let notes = billClients[clientNum].billItems[billItemNum].notes
							let serviceDate = billClients[clientNum].billItems[billItemNum].serviceDate
							let timesheetServiceName = billClients[clientNum].billItems[billItemNum].timesheetServiceName
							
							let (foundFlag, studentNum) = referenceData.students.findStudentByName(studentName: studentName)
							if !foundFlag {
								print("Error: Could not find Student \(studentName) in Students List")
							} else {
								let studentLocation = referenceData.students.studentsList[studentNum].studentLocation
								
								clientName = billClients[clientNum].clientName
								clientEmail = billClients[clientNum].clientEmail
								let description = serviceDate + " - " + invoiceServiceName + " - " + notes
								
								// If this is the same client as the previous tutoring session in this invoice, some attributes are blank as required by QuickBooks CSV format
//								if clientName == prevClientName {
//									clientName = ""
//									clientEmail = ""
//									clientDueDate = ""
//									clientInvoiceDate = ""
//									clientTerms = ""
//								} else {			// If this session is for a different client, fill in client name, due date, etc
									prevClientName = clientName
									clientDueDate = dueDateStr
									clientTerms = PgmConstants.termsString
									clientInvoiceDate = invoiceDate
//								}
								// Add a line to the invoice with the tutoring session data
							let invoiceLine = InvoiceLine(invoiceNum: String(referenceData.dataCounts.highestInvoiceNumber + 1), clientName: clientName, clientEmail: clientEmail, invoiceDate: clientInvoiceDate, dueDate: clientDueDate, terms: clientTerms, locationName: studentLocation, tutorName: tutorName, serviceCode: serviceCode, itemName: invoiceServiceName, description: description, quantity: fixedQuantity, rate: String(rate), amount: price, taxCode: String(price.formatted(.number.precision(.fractionLength(2)))) + PgmConstants.taxCodeString, serviceDate: billClients[clientNum].billItems[billItemNum].serviceDate, studentName: studentName, cost: cost, accountCode: accountCode, brandingTheme: brandingTheme)
							newInvoice.addInvoiceLine(invoiceLine: invoiceLine)
							
							}
							
						}
						
					}
				}
				billItemNum += 1
			}
			clientNum += 1
			referenceData.dataCounts.increaseHighestInvoiceNumber()				// Invoice numbers increase for each client (not each session)
		}

		
		newInvoice.totalProfit = newInvoice.totalRevenue - newInvoice.totalCost
		newInvoice.isInvoiceLoaded = true
		//        newInvoice.printInvoice()
		return(newInvoice)
	}
	
	// Prints a the elements of a BillArray (used for debugging processes)
	func printBillArray() {
		
		var clientNum = 0
		while clientNum < billClients.count {
			print("Client : \(billClients[clientNum].clientName) ")
			var billItemNum = 0
			while billItemNum < billClients[clientNum].billItems.count {
				print("     Bill Item: \(billClients[clientNum].billItems[billItemNum].studentName) \(billClients[clientNum].billItems[billItemNum].serviceDate) \(billClients[clientNum].billItems[billItemNum].timesheetServiceName) \(billClients[clientNum].billItems[billItemNum].duration) ")
				billItemNum += 1
			}
			clientNum += 1
		}
	}
            
}

