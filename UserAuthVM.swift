//
//  AuthModel.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-01.
//

import Foundation
import SwiftUI
import GoogleSignIn


@Observable class UserAuthVM {
    
	var isLoggedIn: Bool = false
	var errorMessage: String = ""
	
	init() {
		check()
	}
	
	func checkStatus() {
		var tokenExpirationDate: Date?
		
		if (GIDSignIn.sharedInstance.currentUser != nil) {
			let user = GIDSignIn.sharedInstance.currentUser
			guard let user = user else {
				return }
			
			checkAuthScope()
			self.isLoggedIn = true
			
			let currentUser = GIDSignIn.sharedInstance.currentUser
			if let user = currentUser {
				
				let clientID = GIDSignIn.sharedInstance.configuration?.clientID
				let currentUser = GIDSignIn.sharedInstance.currentUser
				if let user = currentUser {
					accessOAuthToken = user.accessToken.tokenString
					refreshOAuthToken = user.refreshToken.tokenString
					tokenExpirationDate = user.accessToken.expirationDate
					
				}
				
				if let tokenExpirationDate = tokenExpirationDate {
					oauth2Token.accessToken = accessOAuthToken
					oauth2Token.refreshToken = refreshOAuthToken
					oauth2Token.expiresAt = tokenExpirationDate
					oauth2Token.clientID = clientID
				}
			} else {
				self.isLoggedIn = false
			}
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
	
	// "drive" scope required to create new Timesheet for new Tutor
	//
	func checkAuthScope() -> Bool {
		
		let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets","https://www.googleapis.com/auth/drive"]
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
		
//		let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets"]
		let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets","https://www.googleapis.com/auth/drive"]
		guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
			return ;  /* Not signed in. */
		}
		guard let presentingWindow = NSApplication.shared.mainWindow else {
			return}
		
		currentUser.addScopes(additionalScopes, presenting: presentingWindow) { signInResult, error in
			if let error = error {
				print("Error requesting additional scopes: \(error.localizedDescription)")
				self.isLoggedIn = false
			} else {
				print("Additional scopes granted.")
				self.isLoggedIn = true
				// You can now use the updated user to make authenticated API requests
				if let grantedScopes = currentUser.grantedScopes {
						print("Granted scopes: \(grantedScopes)")
				}
			}
		}
	}

	
	
	func signIn() {
		
		var tokenExpirationDate: Date?
		guard let presentingWindow = NSApplication.shared.mainWindow else {
			return}
		
		GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) {signInResult, error in
			if let error = error  {
				print("Sign in error: \(error.localizedDescription)")
				return
			}
			
			//		    guard let signInResult = signInResult else { return }
			let clientID = GIDSignIn.sharedInstance.configuration?.clientID
			let currentUser = GIDSignIn.sharedInstance.currentUser
			if let user = currentUser {
				accessOAuthToken = user.accessToken.tokenString
				refreshOAuthToken = user.refreshToken.tokenString
				tokenExpirationDate = user.accessToken.expirationDate
				
			}
			
			if let tokenExpirationDate = tokenExpirationDate {
				oauth2Token.accessToken = accessOAuthToken
				oauth2Token.refreshToken = refreshOAuthToken
				oauth2Token.expiresAt = tokenExpirationDate
				oauth2Token.clientID = clientID
			}
			
			if self.checkAuthScope() == false {
				self.getAuthScope()
				if self.checkAuthScope() == false {
					print("SignIn - could not get additional scope")
					self.isLoggedIn = false
				} else {
					print("SignIn - got additional scope")
					self.isLoggedIn = true
				}
			} else {
				print("SignIn - already had scope")
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

