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
//  @EnvironmentObject var authViewModel: AuthenticationViewModel
//    @ObservedObject var vm = UserAuthModel
//    @State var vm: UserAuthModel
    @Environment(UserAuthModel.self) var userAuthModel: UserAuthModel
 //   @Environment(TimesheetModel.self) var timesheetModel: TimesheetModel
    

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
            
           #if os(iOS)
            .pickerStyle(.segmented)
          #endif
        }
      }
      Spacer()
    }
  }
    

}

#Preview {
    SignInView()
}

