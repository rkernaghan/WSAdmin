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
    
    fileprivate func SignInButton() -> Button<Text> {
        Button(action: {
            authVM.signIn()
        }) {
            Text("Sign In")
        }
    }
    
    fileprivate func SignOutButton() -> Button<Text> {
        Button(action: {
            authVM.signOut()
        }) {
            Text("Sign Out")
        }
    }
    

    var body: some View {
        NavigationStack {
            VStack{
                
                if (authVM.isLoggedIn) {
                    DataMgmtView()
                } else {
                    SignInView()
                }
                Text(authVM.errorMessage)
            }
        }
        .navigationTitle("Write Seattle Administration")
        .environment(refDataVM)
        .environment(authVM)
        .environment(studentMgmtVM)
        .environment(tutorMgmtVM)
        .environment(serviceMgmtVM)
        .environment(locationMgmtVM)
    }
}

#Preview {
    ContentView()
}

