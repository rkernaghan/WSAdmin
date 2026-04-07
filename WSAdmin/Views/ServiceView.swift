//
//  AddService.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation
import SwiftUI

struct ServiceView: View {
	var updateServiceFlag: Bool
	var serviceNum: Int
	var originalTimesheetName: String
	var referenceData: ReferenceData
	var serviceKey: String
	
	@State var serviceCode: String
	@State var timesheetName: String
	@State var invoiceName: String
	@State var serviceType: ServiceTypeOption
	@State var billingType: BillingTypeOption
	@State var serviceCount: Int
	@State var cost1: Double
	@State var cost2: Double
	@State var cost3: Double
	@State var price1: Double
	@State var price2: Double
	@State var price3: Double
	
	@State private var showAlert:Bool = false
	
	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	@Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		
		VStack(alignment: .leading) {
			HStack {
				Text("Service Code")
				TextField("Service Code", text: $serviceCode)
					.frame(width: 350)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Timesheet Name")
				TextField("Timesheet Name", text: $timesheetName)
					.frame(width: 350)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Invoice Name")
				TextField("Invoice Name", text: $invoiceName)
					.frame(width: 350)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Cost 1")
				TextField("Cost 1", value: $cost1, format: .number.precision(.fractionLength(2)))
					.frame(width: 80, alignment: .center)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Cost 2")
				TextField("Cost 2", value: $cost2, format: .number.precision(.fractionLength(2)))
					.frame(width: 80, alignment: .center)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Cost 3")
				TextField("Cost 3", value: $cost3, format: .number.precision(.fractionLength(2)))
					.frame(width: 80, alignment: .center)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Price 1")
				TextField("Price 1", value: $price1, format: .number.precision(.fractionLength(2)))
					.frame(width: 80, alignment: .center)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Price 2")
				TextField("Price 2", value: $price2, format: .number.precision(.fractionLength(2)))
					.frame(width: 80, alignment: .center)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Price 3")
				TextField("Price 3", value: $price3, format: .number.precision(.fractionLength(2)))
					.frame(width: 80, alignment: .center)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				if !updateServiceFlag {
					
					Picker("Service Type", selection: $serviceType) {
						ForEach(ServiceTypeOption.allCases) { option in
							Text(String(describing: option))
						}
					}
				} else {
					Text("Service Type:")
					Text( String(describing: serviceType) )
				}
			}
			.frame(width:200)
//			.clipped()
			
			HStack {
				Picker("Billing Type", selection: $billingType) {
					ForEach(BillingTypeOption.allCases, id:\.self) { option in
						Text(String(describing: option))
					}
				}
			}
			.frame(width:200)
			.clipped()
			
			Button{
				Task {
					timesheetName = timesheetName.trimmingCharacters(in: .whitespaces)
					invoiceName = invoiceName.trimmingCharacters(in: .whitespaces)
					
					if updateServiceFlag {
						let (validationResult, validationMessage) = serviceMgmtVM.validateUpdatedService(referenceData: referenceData, timesheetName: timesheetName, originalTimesheetName: originalTimesheetName, invoiceName:invoiceName, serviceType: serviceType, billingType: billingType, serviceCount: serviceCount, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
						if validationResult {
							let (updateResult, updateMessage) = await serviceMgmtVM.updateService(serviceNum: serviceNum, referenceData: referenceData, serviceCode: serviceCode, timesheetName: timesheetName, originalTimesheetName: originalTimesheetName, invoiceName: invoiceName, serviceType: serviceType, billingType: billingType, serviceCount: serviceCount, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
							if !updateResult {
								buttonErrorMsg = updateMessage
								showAlert = true
							} else {
								dismiss()
							}
						} else {
							buttonErrorMsg = validationMessage
							showAlert = true
						}
					} else {
						let (validationResult, validationMessage) = serviceMgmtVM.validateNewService(referenceData: referenceData, timesheetName: timesheetName, invoiceName:invoiceName, serviceType: serviceType, billingType: billingType, serviceCount: serviceCount, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
						if validationResult {
							let (addResult, addMessage) = await serviceMgmtVM.addNewService(referenceData: referenceData, serviceCode: serviceCode, timesheetName: timesheetName, invoiceName: invoiceName, serviceType: serviceType, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
							if !addResult {
								buttonErrorMsg = addMessage
								showAlert = true
							} else {
								dismiss()
							}
						} else {
							buttonErrorMsg = validationMessage
							showAlert = true
						}
					}
				}
			} label: {
				if updateServiceFlag {
					Label("Update Service", systemImage: "square.and.arrow.up")
				} else {
					Label("Add New Service", systemImage: "square.and.arrow.up")
				}
			}
			.navigationTitle("Service Display")
			
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
			.padding()
			.clipShape(RoundedRectangle(cornerRadius: 10))
			
			Spacer()
			
		}
	}
}

//#Preview {
//    AddStudent()
//}

