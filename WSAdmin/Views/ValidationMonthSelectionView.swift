//
//  ValidationMonthSelectionView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2025-04-23.
//



import SwiftUI

struct ValidationMonthSelectionView: View {
	
	var referenceData: ReferenceData
	
	@Environment(SystemVM.self) var systemVM: SystemVM
	
	@State private var selectedMonth: String = monthArray[Calendar.current.dateComponents([.month], from: Date()).month! - 1]
	@State private var selectedYear: String = yearArray[Calendar.current.dateComponents([.year], from: Date()).year! - 2024]
	@State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
	@State private var showAlert: Bool = false
	@State private var showMessages: Bool = false
	@State private var validationMessages = BillingMessages()

	
	
	var body: some View {
		
		VStack {
			
			HStack {
				
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
							validationMessages.billingMessageList.removeAll()
							showMessages = true
	
							await systemVM.ValidateMonthBillingData(referenceData: referenceData, monthName: selectedMonth, yearName: selectedYear,  validationMessages: validationMessages)
							
						}
					} label: {
						Label("Validate Month", systemImage: "square.and.arrow.up")
					}
					.alert(buttonErrorMsg, isPresented: $showAlert) {
						Button("OK", role: .cancel) { }
					}
				}
			}
			
		}
		.navigationDestination(isPresented: $showMessages) {
			ValidationProgressView(validationMessages: validationMessages, referenceData: referenceData,  billingMonth: selectedMonth, billingYear: selectedYear)
			
		}
	}
	
}

#Preview {
	//    BillingSelectionView()
}
