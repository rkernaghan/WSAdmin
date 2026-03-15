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
					Text("Total Cost: \(String(invoice.totalCost.formatted(.number.precision(.fractionLength(2)))))")
					Text("Total Price: \(String(invoice.totalRevenue.formatted(.number.precision(.fractionLength(2)))))")
					Text("Total Profit: \(String(invoice.totalProfit.formatted(.number.precision(.fractionLength(2)))))")
				}
				
				if alreadyBilledTutors.count > 0 {
					Spacer()
					Text("Warning: Tutors Already Billed This Month: \(alreadyBilledTutors)")
						.bold()
						.foregroundStyle(.red)
				}
				VStack {
					Table(invoice.invoiceLines) {
					    Group {
						TableColumn("Invoice\nNum", value: \InvoiceLine.invoiceNum)
							.width(min: 30, ideal: 42, max: 50)
						TableColumn("Client Name", value: \InvoiceLine.clientName)
							.width(min: 60, ideal: 100, max: 200)
						TableColumn("Client Email", value: \InvoiceLine.clientEmail)
						// TableColumn("Invoice Date", value: \InvoiceLine.invoiceDate)
						// TableColumn("Due Date", value: \InvoiceLine.dueDate)
						TableColumn("Reference", value: \InvoiceLine.studentName)
							    .width(min: 60, ideal: 80, max: 120)
						TableColumn("Invoice Date", value: \InvoiceLine.invoiceDate)
							.width(min: 55, ideal: 60, max: 80)
						TableColumn("Due Date", value: \InvoiceLine.dueDate)
							.width(min: 55, ideal: 60, max: 80)
						  }
						
					  Group {
						TableColumn("Item\nCode", value: \InvoiceLine.serviceCode)
							  .width(min: 20, ideal: 30, max: 40)
//						TableColumn("Tutor Name", value: \InvoiceLine.tutorName)
//							.width(min: 60, ideal: 100, max: 140)
//						TableColumn("Item", value: \InvoiceLine.itemName)
//							.width(min: 100, ideal: 150, max: 220)
						TableColumn("Description", value: \InvoiceLine.description)
							.width(min: 140, ideal: 200, max: 260)
						TableColumn("Quantity", value: \InvoiceLine.quantity)
							.width(min: 35, ideal: 35, max: 50)
//						TableColumn("Rate", value: \InvoiceLine.rate)
//							.width(min: 40, ideal: 40, max: 50)
						//                       TableColumn("Amount", value: \.amount)
						TableColumn("Amount") { data in
							Text(String(data.amount.formatted(.number.precision(.fractionLength(2)))))
							}
							.width(min: 40, ideal: 40, max: 50)
//						TableColumn("Tax Code", value: \InvoiceLine.taxCode)
						TableColumn("Account\nCode", value: \InvoiceLine.accountCode)
							  .width(min: 40, ideal: 40, max: 50)
						TableColumn("Branding\nTheme", value: \InvoiceLine.brandingTheme)
							  .width(min: 60, ideal: 70, max: 85)
//						TableColumn("Service Date", value: \InvoiceLine.serviceDate)
//							.width(min: 50, ideal: 60, max: 80)
						}
					}
					HStack {
						Button(action: {
							Task {
								let (csvGenerationResult, csvGenerationMessage) = await billingVM.generateCSVFile(invoice: invoice, billingMonth: billingMonth, billingYear: billingYear, tutorBillingMonth: billedTutorMonth, alreadyBilledTutors: alreadyBilledTutors, referenceData: referenceData)
								if csvGenerationResult {
									dismiss()
								} else {
									buttonErrorMsg = csvGenerationMessage
									showAlert = true
								}
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
			.navigationTitle("Invoice View")
			
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
		}
	}
}

// #Preview {
//    TutorStudentsView()
// }

