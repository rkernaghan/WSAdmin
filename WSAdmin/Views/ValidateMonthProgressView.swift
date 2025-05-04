//
//  ValidationProgressView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2025-04-23.
//

import SwiftUI

struct ValidateMonthProgressView: View {
	
	var validationMessages: WindowMessages
	var referenceData: ReferenceData
	var billingMonth: String
	var billingYear: String

	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	
	@State private var showAlert: Bool = false
	
	var body: some View {
		
		VStack {
			List(validationMessages.windowMessageList) {
				Text($0.windowLineText)
			}
			
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
		
		
	}
}
