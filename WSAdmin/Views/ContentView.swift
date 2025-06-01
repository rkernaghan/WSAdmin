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

	let userAuthVM = UserAuthVM()
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
				if (userAuthVM.isLoggedIn) {
					DataMgmtView()
				} else {
					SignInView()
				}
			}
			.toolbar {
				Text("Hi Stephen")
			}
		}
		.navigationTitle("Write Seattle Administration")
		.environment(refDataVM)
		.environment(userAuthVM)
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

