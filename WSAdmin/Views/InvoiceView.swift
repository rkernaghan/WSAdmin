//
//  InvoiceView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import SwiftUI

struct InvoiceView: View {
    var invoice: Invoice
    
    @Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedServices: Set<InvoiceLine.ID> = []
    @State private var tutorServiceNum: Int = 0
    @State private var editTutorService = false
    @State private var unassignTutorService = false
//    @State private var sortOrder = [KeyPathComparator(\TutorService.timesheetServiceName)]
    
    var body: some View {
        if invoice.isInvoiceLoaded {
            VStack {
                Table(invoice.invoiceLines) {
//                    Group {
                        TableColumn("Invoice Num", value: \.invoiceNum)
                        TableColumn("Client Name", value: \.clientName)
                        TableColumn("Client Email", value: \.clientEmail)
                        TableColumn("Invoice Date", value: \.invoiceDate)
                        TableColumn("Due Date", value: \.dueDate)
                        TableColumn("Location", value: \.locationName)
                        TableColumn("Terms", value: \.terms)
  //                  }
  //                  Group {
                        TableColumn("Tutor Name", value: \.tutorName)
                        TableColumn("Item", value: \.itemName)
                        TableColumn("Description", value: \.description)
                        //              TableColumn("Quantity", value: \.quantity)
                        //              TableColumn("Rate", value: \.rate)
                        //              TableColumn("Amount", value: \.amount)
                        //              TableColumn("Tax Code", value: \.taxCode)
                        //              TableColumn("Service Date", value: \.serviceDate)
   //                 }
                }
            }
        }
    }
}

// #Preview {
//    TutorStudentsView()
// }
