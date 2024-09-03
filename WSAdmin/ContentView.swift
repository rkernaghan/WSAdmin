//
//  ContentView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//

import SwiftUI
import GoogleSignIn

struct ContentView: View {

    let vm = UserAuthModel()
    let refVM = RefDataModel()
    
    fileprivate func SignInButton() -> Button<Text> {
        Button(action: {
            vm.signIn()
        }) {
            Text("Sign In")
        }
    }
    
    fileprivate func SignOutButton() -> Button<Text> {
        Button(action: {
            vm.signOut()
        }) {
            Text("Sign Out")
        }
    }
    

    var body: some View {
        VStack{
            
            if (vm.isLoggedIn) {
                DataMgmtView()
 
 //               SignOutButton()
            } else {
                SignInView()
            }
            Text(vm.errorMessage)
        }
        .navigationTitle("Login")
        .environment(refVM)
        .environment(vm)
    }
}

#Preview {
    ContentView()
}

