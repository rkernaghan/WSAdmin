//
//  InvoiceView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import SwiftUI

struct InvoiceView: View {
    var invoice: Invoice
    var billingMonth: String
    var billingYear: String
    var billedTutorMonth: TutorBillingMonth
    var alreadyBilledTutors: [String]
    var referenceData: ReferenceData
    
    @Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @Environment(BillingVM.self) var billingVM: BillingVM
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedServices: Set<InvoiceLine.ID> = []
    @State private var tutorServiceNum: Int = 0
    @State private var editTutorService = false
    @State private var unassignTutorService = false
    @State private var showAlert: Bool = false
//    @State private var sortOrder = [KeyPathComparator(\TutorService.timesheetServiceName)]
    
    var body: some View {
        if invoice.isInvoiceLoaded {
            VStack {
                HStack {
                    Text("Total Sessions: \(String(invoice.totalSessions))")
                    Text("Total Cost: \(String(invoice.totalCost))")
                    Text("Total Price: \(String(invoice.totalRevenue))")
                    Text("Total Profit: \(String(invoice.totalProfit))")
                }
                VStack {
                    Table(invoice.invoiceLines) {
                        //                    Group {
                        //                    TableColumn("Invoice Num", value: \.invoiceNum)
                        TableColumn("Client Name", value: \.clientName)
                        //                        TableColumn("Client Email", value: \.clientEmail)
                        //                        TableColumn("Invoice Date", value: \.invoiceDate)
                        // TableColumn("Due Date", value: \.dueDate)
                        TableColumn("Location", value: \.locationName)
                        TableColumn("Terms", value: \.terms)
                        //                  }
                        //                  Group {
                        TableColumn("Tutor Name", value: \.tutorName)
                        TableColumn("Item", value: \.itemName)
                        TableColumn("Description", value: \.description)
                        TableColumn("Quantity", value: \.quantity)
                        TableColumn("Rate", value: \.rate)
 //                       TableColumn("Amount", value: \.amount)
                        TableColumn("Amount") { data in
                            Text(String(data.amount.formatted(.number.precision(.fractionLength(2)))))
                        }
                        //              TableColumn("Tax Code", value: \.taxCode)
                        TableColumn("Service Date", value: \.serviceDate)
                        //                 }
                    }
                    HStack {
                        Button(action: {
  
                            let (csvGenerationResult, csvGenerationMessage) = billingVM.generateCSVFile(invoice: invoice, billingMonth: billingMonth, billingYear: billingYear, tutorBillingMonth: billedTutorMonth, alreadyBilledTutors: alreadyBilledTutors, referenceData: referenceData)
                            if csvGenerationResult {
                                    dismiss()
                            } else {
                                buttonErrorMsg = csvGenerationMessage
                                showAlert = true
                            }
                        }){
                            Text("Generate CSV File")
                        }
                        .alert(buttonErrorMsg, isPresented: $showAlert) {
                            Button("OK", role: .cancel) { }
                        }
                    }
                }
            }
        }
    }
}

// #Preview {
//    TutorStudentsView()
// }
