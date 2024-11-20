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
	@State private var selectedMonth: String = monthArray[Calendar.current.dateComponents([.month], from: Date()).month! - 1]
	@State private var selectedYear: String = yearArray[Calendar.current.dateComponents([.year], from: Date()).year! - 2024]
	@State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
	@State private var showAlert: Bool = false
	@State private var showInvoice: Bool = false
	@State private var selectAll: Bool = false
	@State private var invoice = Invoice()
	@State private var alreadyBilledTutors = [String]()
	@State private var billedTutorMonth = TutorBillingMonth(monthName: "")
	
	var body: some View {
		
		VStack {
			
			var tutorList: [Tutor] = referenceData.tutors.tutorsList.filter{$0.tutorStatus == "Assigned"}
			
			Toggle(isOn: Binding(
				get: { selectedTutors.count == tutorList.count && !tutorList.isEmpty },
				set: { isSelectAll in
					if isSelectAll {
						// Select all rows by adding all row IDs to selectedRows
						selectedTutors = Set(tutorList.map { $0.id })
					} else {
						// Deselect all rows by clearing selectedRows
						selectedTutors.removeAll()
					}
				}
			)) {
				Text("Select All")
			}
			.padding()
			HStack {
				Table(referenceData.tutors.tutorsList.filter{$0.tutorStatus == "Assigned"}, selection: $selectedTutors, sortOrder: $sortOrder) {
					
					TableColumn("Tutor Name", value: \.tutorName)
						.width(min: 120, ideal: 140, max: 200)
					
					TableColumn("Student\nCount") {data in
						Text(String(data.tutorStudentCount))
					}
					.width(min: 60, ideal: 80, max: 100)
					
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
							(invoice, billedTutorMonth, alreadyBilledTutors) = await billingVM.generateInvoice(tutorSet: selectedTutors, billingYear: selectedYear, billingMonth: selectedMonth, referenceData: referenceData)
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
			
		}
		.navigationDestination(isPresented: $showInvoice) {
			InvoiceView(invoice: invoice, billingMonth: selectedMonth, billingYear: selectedYear, billedTutorMonth: billedTutorMonth, alreadyBilledTutors: alreadyBilledTutors, referenceData: referenceData)
		}
	}
	
}

#Preview {
	//    BillingView()
}
