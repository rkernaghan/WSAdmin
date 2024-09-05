//
//  SignInView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-01.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct SignInView: View {
    @Environment(UserAuthVM.self) var userAuthModel: UserAuthVM
    @State private var showAlert = false

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Spacer()
            
                    GoogleSignInButton(action: {
                        userAuthModel.signIn()  })
                    .accessibilityIdentifier("GoogleSignInButton")
                    .accessibility(hint: Text("Sign in with Google button."))
                    .padding()
                }
            }
            Spacer()
        }
    }
}

#Preview {
    SignInView()
}

