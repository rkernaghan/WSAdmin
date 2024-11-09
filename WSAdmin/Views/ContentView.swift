//
//  ContentView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//
import Foundation
import SwiftUI
import GoogleSignIn

struct ContentView: View {

	let authVM = UserAuthVM()
	let refDataVM = RefDataVM()
	let studentMgmtVM = StudentMgmtVM()
	let tutorMgmtVM = TutorMgmtVM()
	let serviceMgmtVM = ServiceMgmtVM()
	let locationMgmtVM = LocationMgmtVM()
	let billingVM = BillingVM()
    
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

	}
}

#Preview {
	ContentView()
}

