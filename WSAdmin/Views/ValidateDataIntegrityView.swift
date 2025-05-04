//
//  ValidateDataIntegrityView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2025-05-04.
//

import SwiftUI

struct ValidateDataIntegrityView: View {
	
	var validationMessages: WindowMessages
	var referenceData: ReferenceData

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
