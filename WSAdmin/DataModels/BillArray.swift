//
//  BillingArray.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//
import Foundation

class BillArray {
    
    var billClients = [BillClient]()
    
    func addBillClient(newBillClient: BillClient) {
        self.billClients.append(newBillClient)
    }
    
    func processTimesheet(timesheet: Timesheet) {
        
        var timesheetNum = 0
        while timesheetNum < timesheet.timesheetRows.count {
            let timesheetClientName = timesheet.timesheetRows[timesheetNum].clientName
            var (foundFlag, billClientNum) = findBillClientByName(billClientName: timesheetClientName)
            if !foundFlag {
                let newBillClient = BillClient(clientName: timesheetClientName, clientEmail: timesheet.timesheetRows[timesheetNum].clientEmail, clientPhone: timesheet.timesheetRows[timesheetNum].clientPhone)
                self.addBillClient(newBillClient: newBillClient)
                (foundFlag, billClientNum) = findBillClientByName(billClientName: timesheetClientName)
            }
            let studentName = timesheet.timesheetRows[timesheetNum].studentName
            let serviceDate = timesheet.timesheetRows[timesheetNum].serviceDate
            let duration = timesheet.timesheetRows[timesheetNum].duration
            let serviceName = timesheet.timesheetRows[timesheetNum].serviceName
            let notes = timesheet.timesheetRows[timesheetNum].notes
            let tutorName = timesheet.timesheetRows[timesheetNum].tutorName
            let cost = timesheet.timesheetRows[timesheetNum].cost
            let newBillItem = BillItem(studentName: studentName, serviceDate: serviceDate, duration: duration, serviceName: serviceName, notes: notes, cost: cost, tutorName: tutorName)
            self.billClients[billClientNum].billItems.append(newBillItem)
            timesheetNum += 1
        }
    }
        
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
    
    func generateInvoice(alreadyBilledTutors: [String], referenceData: ReferenceData) -> Invoice {
        let newInvoice = Invoice()
        var timesheetServiceName: String = ""
        var duration: Int = 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let invoiceDate = dateFormatter.string(from: Date())
        let dueDate = invoiceDate
        
        var clientNum = 0
        while clientNum < billClients.count {
 //   print("Client : \(billClients[clientNum].clientName) ")
            var billItemNum = 0
            while billItemNum < billClients[clientNum].billItems.count {
                let tutorName = billClients[clientNum].billItems[billItemNum].tutorName
                let (tutorFound, tutorNum) = referenceData.tutors.findTutorByName(tutorName: tutorName)
                if tutorFound {
                    timesheetServiceName = billClients[clientNum].billItems[billItemNum].serviceName
                    let (serviceFound, serviceNum) = referenceData.tutors.tutorsList[tutorNum].findTutorServiceByName(serviceName: timesheetServiceName)
                    if serviceFound {
                        duration = billClients[clientNum].billItems[billItemNum].duration
                        let (quantity, rate, cost, price) = referenceData.tutors.tutorsList[tutorNum].tutorServices[serviceNum].computerSessionCostPrice(duration: duration)
                        newInvoice.totalRevenue += price
                        newInvoice.totalCost += cost
                        newInvoice.totalSessions += 1
                        let invoiceLine = InvoiceLine(invoiceNum: String(clientNum), clientName: billClients[clientNum].clientName, clientEmail: billClients[clientNum].clientEmail, invoiceDate: invoiceDate, dueDate: dueDate, terms: PgmConstants.termsString, locationName: tutorName, tutorName: tutorName, itemName: timesheetServiceName, description: billClients[clientNum].billItems[billItemNum].notes, quantity: String(quantity), rate: String(rate), amount: price, taxCode: PgmConstants.taxCodeString, serviceDate: billClients[clientNum].billItems[billItemNum].serviceDate, studentName: billClients[clientNum].billItems[billItemNum].studentName, cost: cost)
                        newInvoice.addInvoiceLine(invoiceLine: invoiceLine)
         //               print("     Bill Item: \(billClients[clientNum].billItems[billItemNum].studentName) \(billClients[clientNum].billItems[billItemNum].serviceDate) \(billClients[clientNum].billItems[billItemNum].serviceName) \(billClients[clientNum].billItems[billItemNum].duration) ")

                    }
                }
                billItemNum += 1
            }
            clientNum += 1
        }
        newInvoice.totalProfit = newInvoice.totalRevenue - newInvoice.totalCost
        newInvoice.isInvoiceLoaded = true
//        newInvoice.printInvoice()
        return(newInvoice)
    }
               
    func printBillArray() {
        
        var clientNum = 0
        while clientNum < billClients.count {
            print("Client : \(billClients[clientNum].clientName) ")
            var billItemNum = 0
            while billItemNum < billClients[clientNum].billItems.count {
                print("     Bill Item: \(billClients[clientNum].billItems[billItemNum].studentName) \(billClients[clientNum].billItems[billItemNum].serviceDate) \(billClients[clientNum].billItems[billItemNum].serviceName) \(billClients[clientNum].billItems[billItemNum].duration) ")
                billItemNum += 1
            }
            clientNum += 1
        }
    }
            
}

