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

	@State private var path = NavigationPath()
	
	let userAuthVM = UserAuthVM()
	let refDataVM = RefDataVM()
	let studentMgmtVM = StudentMgmtVM()
	let tutorMgmtVM = TutorMgmtVM()
	let serviceMgmtVM = ServiceMgmtVM()
	let locationMgmtVM = LocationMgmtVM()
	let billingVM = BillingVM()
	let financeSummaryVM = FinanceSummaryVM()
	
	var body: some View {
		NavigationStack(path: $path) {
			VStack{
				if (userAuthVM.isLoggedIn) {
					DataMgmtView(path: $path)
				} else {
					SignInView()
				}
				
				Text("App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
					.font(.footnote)
					.foregroundColor(.secondary)
				Text("Build Number: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")")
					.font(.footnote)
					.foregroundColor(.secondary)
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

