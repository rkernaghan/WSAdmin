//
//  BillingView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-14.
//

import SwiftUI

struct BillingView: View {

    var referenceData: ReferenceData

    @Environment(BillingVM.self) var billingVM: BillingVM
    
    @State private var selectedTutors = Set<Tutor.ID>()
    @State private var selectedMonth: String = "Oct"
    @State private var selectedYear: String = "2024"
    @State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
    @State private var showAlert: Bool = false
    @State private var showInvoice: Bool = false
    @State private var selectAll: Bool = false
    @State private var invoice = Invoice()

    var body: some View {
    
        VStack {
            
            Toggle("Select All", isOn: $selectAll)
            
            HStack {
                Table(referenceData.tutors.tutorsList, selection: $selectedTutors, sortOrder: $sortOrder) {
                    
                    TableColumn("Tutor Name", value: \.tutorName)
                    TableColumn("Tutor Status", value: \.tutorStatus)
                }
                
                VStack {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(monthArray, id: \.self) { item in
                            Text(item)
                        }
                    }
                    .frame(width: 140)
                
                    Picker("Year", selection: $selectedYear) {
                        ForEach(yearArray, id: \.self) { item in
                            Text(item)
                        }
                    }
                    .frame(width: 140)
                    
                    Button {
                        Task {
                            invoice = await billingVM.generateInvoice(tutorSet: selectedTutors, timesheetYear: selectedYear, timesheetMonth: selectedMonth, referenceData: referenceData)
                            showInvoice = true
                        }
                    } label: {
                        Label("Generate Invoice", systemImage: "square.and.arrow.up")
                    }
                    .alert(buttonErrorMsg, isPresented: $showAlert) {
                        Button("OK", role: .cancel) { }
                    }
                }
            }
            
            .contextMenu(forSelectionType: Tutor.ID.self) { items in
                if items.count == 1 {
                    VStack {
                        
                        Button {
                            
                        } label: {
                            Label("Assign Tutor to Student", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } else {
                    Button {
                        
                    } label: {
                        Label("Assign Tutors Student", systemImage: "square.and.arrow.up")
                    }
                }
                    
                } primaryAction: { items in
                    //              store.favourite(items)
                }
            }
            .navigationDestination(isPresented: $showInvoice) {
                InvoiceView(invoice: invoice)
            }
        }
 
    }

#Preview {
//    BillingView()
}
