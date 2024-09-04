//
//  ContentView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//

import SwiftUI
import GoogleSignIn

struct ContentView: View {

    let authVM = UserAuthModel()
    let refDataVM = RefDataModel()
    
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
        VStack{
            
            if (authVM.isLoggedIn) {
                DataMgmtView()
 
 //               SignOutButton()
            } else {
                SignInView()
            }
            Text(authVM.errorMessage)
        }
        .navigationTitle("Login")
        .environment(refDataVM)
        .environment(authVM)
    }
}

#Preview {
    ContentView()
}

