//
//  AuthModel.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-01.
//

import Foundation
import SwiftUI
import GoogleSignIn
import OSLog


@Observable class UserAuthVM {
    
	var isLoggedIn: Bool = false
	var errorMessage: String = ""
	
	init() {
		check()
	}
	
	let logger = Logger()
	func signIn() {
		
		var tokenExpirationDate: Date?
		guard let presentingWindow = NSApplication.shared.mainWindow else {
			return}
		
		logger.log("Starting Signin")
		
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
					self.logger.log("SignIn - could not get additional scope")
					self.isLoggedIn = false
				} else {
					print("SignIn - got additional scope")
					self.logger.log("SignIn - got additional scope")
					self.isLoggedIn = true
				}
			} else {
				self.logger.log("SignIn - already had additional scope")
				print("SignIn - already had scope")
				self.isLoggedIn = true
			}
		}
	}
	
	func checkStatus() {
		var tokenExpirationDate: Date?
		
		logger.log("SignIn:checkstatus - starting checkStatus")
		
		if (GIDSignIn.sharedInstance.currentUser != nil) {
			logger.log("SignIn:checkstatus - user is logged in")
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
		
		logger.log("SignIn - starting check function")
		
		GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
			if let error = error {
				self.errorMessage = "error: \(error.localizedDescription)"
				self.logger.log("SignIn:check restoring previous signin \(error.localizedDescription)")
				print(self.errorMessage)
			}
			
			self.checkStatus()
		}
	}
	
	// "drive" scope required to create new Timesheet for new Tutor
	//
	func checkAuthScope() -> Bool {
		
		logger.log("SignIn:checkAuthScope - starting checkAuthScope")
		let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets","https://www.googleapis.com/auth/drive"]
		guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
			logger.log("SignIn:checkAuthStatus - not signed in")
			return(false) ;  /* Not signed in. */
		}
		
		let grantedScopes = currentUser.grantedScopes
		if grantedScopes == nil || !grantedScopes!.contains(additionalScopes) {
			print("CheckScope - Need to request additional scope")
			logger.log("SignIn:checkAuthStatus - need to request additional scope")
			return(false)
		} else {
			print("CheckScope - Already have scope")
			logger.log("SignIn:checkAuthStatus - already have additional scope")
			return(true)
		}
	}
	
	func getAuthScope( ) {
		
		logger.log("SignIn:getAuthScope - starting")
//		let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets"]
		let additionalScopes = ["https://www.googleapis.com/auth/spreadsheets","https://www.googleapis.com/auth/drive"]
		guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
			logger.log("SignIn:getAuthScope - not signed in")
			return ;  /* Not signed in. */
		}
		guard let presentingWindow = NSApplication.shared.mainWindow else {
			return}
		
		currentUser.addScopes(additionalScopes, presenting: presentingWindow) { signInResult, error in
			if let error = error {
				print("Error requesting additional scopes: \(error.localizedDescription)")
				self.logger.log("SignIn:getAuthScope - error requesting scope \(error.localizedDescription)")
				self.isLoggedIn = false
			} else {
				print("Additional scopes granted.")
				self.logger.log("SignIn:getAuthScope - additional scope granted")
				self.isLoggedIn = true
				// You can now use the updated user to make authenticated API requests
				if let grantedScopes = currentUser.grantedScopes {
					self.logger.log("SignIn:getAuthScope - Granted scopes: \(grantedScopes)")
					print("Granted scopes: \(grantedScopes)")
				}
			}
		}
	}

	
	func signOut() {
		logger.log("SignIn:signOut - starting")
		GIDSignIn.sharedInstance.signOut()
		isLoggedIn = false
		self.checkStatus()
	}
}

