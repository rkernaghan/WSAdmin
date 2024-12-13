//
//  BillingProgressView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-30.
//
import SwiftUI

struct BillingProgressView: View {
	
	var billingMessages: BillingMessages
	var referenceData: ReferenceData
	var invoice: Invoice
	var billingMonth: String
	var billingYear: String
	var billedTutorMonth: TutorBillingMonth
	var alreadyBilledTutors: [String]

	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(LocationMgmtVM.self) var locationMgmtVM: LocationMgmtVM

	@State private var showInvoice: Bool = false
	@State private var showAlert: Bool = false
	
	var body: some View {
						
		VStack {
			List(billingMessages.billingMessageList) {
				Text($0.billingMessageText)
			}
			
			Button("Show Invoice") {
				showInvoice = true
			}
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
		
		.navigationDestination(isPresented: $showInvoice) {
			InvoiceView(invoice: invoice, billingMonth: billingMonth, billingYear: billingYear, billedTutorMonth: billedTutorMonth, alreadyBilledTutors: alreadyBilledTutors, referenceData: referenceData)
		}
			
		
	}
}

