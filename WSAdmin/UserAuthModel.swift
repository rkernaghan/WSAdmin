//
//  AuthModel.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-01.
//

import Foundation
import SwiftUI
import GoogleSignIn


@Observable class UserAuthModel {
    
    var isLoggedIn: Bool = false
    var errorMessage: String = ""
    
    init() {
        check()
    }
    
    func checkStatus() {
        if (GIDSignIn.sharedInstance.currentUser != nil) {
            let user = GIDSignIn.sharedInstance.currentUser
            guard let user = user else {
                return }

            checkAuthScope()
            self.isLoggedIn = true
        } else {
            self.isLoggedIn = false

        }
    }
    
    func check() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                self.errorMessage = "error: \(error.localizedDescription)"
                print(self.errorMessage)
            }
            
            self.checkStatus()
        }
    }
    
    func checkAuthScope() -> Bool {
        
 //       let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets","https://www.googleapis.com/auth/drive.readonly"]
 //       let additionalScopes = ["https://www.googleapis.com/auth/drive.readonly"]
        let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets"]
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            return(false) ;  /* Not signed in. */
        }
        let grantedScopes = currentUser.grantedScopes
        if grantedScopes == nil || !grantedScopes!.contains(additionalScopes) {
             print("CheckScope - Need to request additional scope")
            return(false)
            
        } else {
            print("CheckScope - Already have scope")
            return(true)
        }
    }
    
func getAuthScope( ) {
    
 //   let additionalScopes = ["https://www.googleapis.com/auth/drive.readonly"]
 //   let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets","https://www.googleapis.com/auth/drive.readonly"]
    let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets"]
    guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
        return ;  /* Not signed in. */
    }
//    guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
//        return}
    guard let presentingWindow = NSApplication.shared.mainWindow else {
              return}
    
//    currentUser.addScopes(additionalScopes, presenting: presentingViewController) { signInResult, error in
    currentUser.addScopes(additionalScopes, presenting: presentingWindow) { signInResult, error in
        guard error == nil else {
            return }
        
        guard let signInResult = signInResult else {
            return }
        
        let grantedScopes = currentUser.grantedScopes
        if grantedScopes == nil || !grantedScopes!.contains(additionalScopes) {
            print("GetScope - Additional scopes not granted")
            self.isLoggedIn = false
        }
        else {
            print("GetScope - Got the additional scopes")
            self.isLoggedIn = true
        }
    }
}
        
        
    func signIn() {
        
 //       guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
 //           return
 //       }
        guard let presentingWindow = NSApplication.shared.mainWindow else {
                  return}
        
 //       GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) {signInResult, error in
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) {signInResult, error in
                guard let result = signInResult else {
                    // Inspect error
                    return
                }
                if self.checkAuthScope() == false {
                    self.getAuthScope()
                    if self.checkAuthScope() == false {
                        print("SignIn - could not get additional scope")
                        self.isLoggedIn = false
                    } else {
                        print("SignIn - got additional scope")
  //                      readData(fileName: "Timesheet 2024 Tutor 2")
                        self.isLoggedIn = true
                    }
                } else {
                    print("SignIn - already had scope")
  //                  readData(fileName: "Timesheet 2024 Tutor 2")
                    
                    self.isLoggedIn = true
                }
            }
      }
        
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isLoggedIn = false
        self.checkStatus()
    }
}

