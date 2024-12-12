//
//  ContentView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//
import Foundation
import SwiftUI
import GoogleSignIn

// ContentView - main view in view hierarchy; invoked from WSAdmin

struct ContentView: View {

	let authVM = UserAuthVM()
	let refDataVM = RefDataVM()
	let studentMgmtVM = StudentMgmtVM()
	let tutorMgmtVM = TutorMgmtVM()
	let serviceMgmtVM = ServiceMgmtVM()
	let locationMgmtVM = LocationMgmtVM()
	let billingVM = BillingVM()
	let financeSummaryVM = FinanceSummaryVM()
    
	var body: some View {
		NavigationStack {
			VStack{
				if (authVM.isLoggedIn) {
					DataMgmtView()
				} else {
					SignInView()
				}
			}
		}
		.navigationTitle("Write Seattle Administration")
		.environment(refDataVM)
		.environment(authVM)
		.environment(studentMgmtVM)
		.environment(tutorMgmtVM)
		.environment(serviceMgmtVM)
		.environment(locationMgmtVM)
		.environment(billingVM)
		.environment(financeSummaryVM)

	}
}

#Preview {
	ContentView()
}

