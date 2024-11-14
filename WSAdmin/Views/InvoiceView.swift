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
						//                    Group {
						//                    TableColumn("Invoice Num", value: \.invoiceNum)
						TableColumn("Client Name", value: \.clientName)
							.width(min: 80, ideal: 120, max: 200)
						//                        TableColumn("Client Email", value: \.clientEmail)
						//                        TableColumn("Invoice Date", value: \.invoiceDate)
						// TableColumn("Due Date", value: \.dueDate)
						TableColumn("Location", value: \.locationName)
							.width(min: 50, ideal: 60, max: 80)
						TableColumn("Terms", value: \.terms)
							.width(min: 60, ideal: 60, max: 80)
						//                  }
						//                  Group {
						TableColumn("Tutor Name", value: \.tutorName)
							.width(min: 60, ideal: 100, max: 140)
						TableColumn("Item", value: \.itemName)
							.width(min: 100, ideal: 150, max: 220)
						TableColumn("Description", value: \.description)
							.width(min: 70, ideal: 90, max: 120)
						TableColumn("Quantity", value: \.quantity)
							.width(min: 40, ideal: 40, max: 60)
						TableColumn("Rate", value: \.rate)
							.width(min: 40, ideal: 40, max: 50)
						//                       TableColumn("Amount", value: \.amount)
						TableColumn("Amount") { data in
							Text(String(data.amount.formatted(.number.precision(.fractionLength(2)))))
						}
						.width(min: 40, ideal: 40, max: 50)
						//              TableColumn("Tax Code", value: \.taxCode)
						TableColumn("Service Date", value: \.serviceDate)
							.width(min: 50, ideal: 60, max: 80)
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
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
		}
	}
}

// #Preview {
//    TutorStudentsView()
// }
