//
//  TutorServiceView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-30.
//

import Foundation
import SwiftUI

struct TutorServiceView: View {
	@Binding var tutorNum: Int
	@Binding var tutorServiceNum: Int
	var referenceData: ReferenceData
	
	var timesheetName: String
	var invoiceName: String
	var billingType: BillingTypeOption
	@State var cost1: Float
	@State var cost2: Float
	@State var cost3: Float
	@State var price1: Float
	@State var price2: Float
	@State var price3: Float
	
	@State private var showAlert: Bool = false
	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	@Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		
		VStack(alignment: .leading) {
			HStack {
				Text("Timesheet Name: ")
					.frame(width: 110)
					.textFieldStyle(.roundedBorder)
				Text(timesheetName)
					.frame(width: 120)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Invoice Name: ")
					.frame(width: 100)
					.textFieldStyle(.roundedBorder)
				Text(invoiceName)
					.frame(width: 120)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Billing Type: ")
					.frame(width: 80)
					.textFieldStyle(.roundedBorder)
				Text(billingType.rawValue)
					.frame(width: 80)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Cost 1")
				TextField("Cost 1", value: $cost1, format: .number)
					.frame(width: 100)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Cost 2")
				TextField("Cost 2", value: $cost2, format: .number)
					.frame(width: 100)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Cost 3")
				TextField("Cost 3", value: $cost3, format: .number)
					.frame(width: 100)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Price 1")
				TextField("Price 1", value: $price1, format: .number)
					.frame(width: 100)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Price 2")
				TextField("Price 2", value: $price2, format: .number)
					.frame(width: 100)
					.textFieldStyle(.roundedBorder)
			}
			HStack {
				Text("Price 3")
				TextField("Price 3", value: $price3, format: .number)
					.frame(width: 100)
					.textFieldStyle(.roundedBorder)
			}
			
			Button{
				Task {
					let (updateResult, updateMessage) = await tutorMgmtVM.updateTutorService(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
					if !updateResult {
						showAlert = true
						buttonErrorMsg = updateMessage
					} else {
						dismiss()
					}
					
				}
			} label: {
				Label("Edit Service", systemImage: "square.and.arrow.up")
			}
			.padding()
			//            .background(Color.orange)
			//            .foregroundColor(Color.white)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			
			Spacer()
			
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
	}
}

//#Preview {
//    AddStudent()
//}


