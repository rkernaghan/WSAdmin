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

let driveScope:String = "https://www.googleapis.com/auth/drive"
let sheetScope:String = "https://www.googleapis.com/auth/spreadsheets"

@Observable class UserAuthVM {
    
	var isLoggedIn: Bool = false
	var errorMessage: String = ""
	
	init() {
		restoreSignIn()
	}
	

	func signIn() {
		
		var tokenExpirationDate: Date?
		guard let presentingWindow = NSApplication.shared.mainWindow else {
			print("UserAuthVM - Signing - Could not get presenting window")
			return}
		
		print("UserAuthVM-SignIn: Starting Signin")
		
		GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) {signInResult, error in
			if let error = error  {
				print("UserAuthVM-SignIn: Sign in error: \(error.localizedDescription)")
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
					print("UserAuthVM-SignIn: - could not get additional scope")
					self.isLoggedIn = false
				} else {
					print("UserAuthVM-SignIn: got additional scope")
					self.isLoggedIn = true
				}
			} else {
				print("UserAuthVM-SignIn: - already had scope")
				self.isLoggedIn = true
			}
		}
	}
	
	
	
	// Attempts to restore Google signin
	//
	func restoreSignIn() {
		
		print("Starting check function")
		
		GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
			if let error = error {
				self.errorMessage = "error: \(error.localizedDescription)"
				print("UserAuthVM-Check: Could not restore previous signin \(self.errorMessage)")
			}
			
			self.checkStatus()
		}
	}
	
	// Checks if user is logged in and if so:
	//		- sets up OAuth attributes to manage token expirty
	//		- determines whether the user already has necessary Google scope
	//
	func checkStatus() {
		var tokenExpirationDate: Date?
		
		print("UserAuthVM-checkstatus: Starting checkStatus")
		
		if (GIDSignIn.sharedInstance.currentUser != nil) {
			print("UserAuthVM-checkstatus: User is logged in")
			let user = GIDSignIn.sharedInstance.currentUser
			guard let user = user else {
				print("UserAuthVM-checkStatus: User signed in but user is nil, returning early")
				return }
			
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
				
				let scopeStatus = checkAuthScope()
				if !scopeStatus {
					print("UserAuthVM-checkStatus: User did not have scope, requesting it")
					let scopeRequest = getAuthScope()
					if scopeRequest {
						print("UserAuthVM-checkStatus: Scope request succeeded")
						self.isLoggedIn = true
					} else {
						self.isLoggedIn = false
						print("UserAuthVM-checkStatus: Scope request failed")
					}
				} else {
					print("UserAuthVM -checkStatus: user already has scope")
					self.isLoggedIn = true
				}
			} else {
				print("UserAuthVM-checkStatus: User not logged in")
				self.isLoggedIn = false
			}
		}
	}
	
	// Checks whether user has necessary Goolge scopes necessary for program
	// "drive" scope required to create new Timesheet for new Tutor
	//
	func checkAuthScope() -> Bool {
		
		let additionalScopes = [sheetScope, driveScope]
		guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
			print("UserAuthVM-checkAuthScope: Not signed in")
			return(false) ;  /* Not signed in. */
		}
		
		let grantedScopes = currentUser.grantedScopes
		if grantedScopes == nil || !grantedScopes!.contains(sheetScope) {
			print("UserAuthVM-checkAuthScope: - Need to request additional scope")
			return(false)
		} else {
			print("UserAuthVM-checkAuthScope: - Already have scope")
			return(true)
		}
	}
	
	// Requests additional scopes necessary for the program from Google, which in turn prompts user to approve
	//	https://www.googleapis.com/auth/spreadsheets scope is required to read and write spreadsheets
	//	https://www.googleapis.com/auth/drive scope is required to get fileIDs, create new timesheets, rename spreadsheets/timesheets, etc.
	//
	func getAuthScope( ) -> Bool {
		var gotAuthScope: Bool = false
		
		print("UserAuthVM-getAuthScope - starting")
		let additionalScopes = [driveScope,sheetScope]
		guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
			print("UserAuthVM-getAuthScope: Not signed in")
			return(gotAuthScope) ;  /* Not signed in. */
		}
		guard let presentingWindow = NSApplication.shared.mainWindow else {
			print("UserAuthVM-getAuthScope: No presenting window")
			return(gotAuthScope)}
		
		currentUser.addScopes(additionalScopes, presenting: presentingWindow) { signInResult, error in
			if let error = error {
				print("UserAuthVM-getAuthScope: Error requesting additional scopes: \(error.localizedDescription)")
				self.isLoggedIn = false
			} else {
				print("UserAuthVM-getAuthScope: Additional scopes granted.")
				self.isLoggedIn = true
				gotAuthScope = true
				// Can now use the updated user to make authenticated API requests
				if let grantedScopes = currentUser.grantedScopes {
					print("UserAuthVM-getAuthScope: Granted scopes: \(grantedScopes)")
				}
			}
		}
		return(gotAuthScope)
	}

	
	func signOut() {
		print("UserAuthVM-signOut - Starting")
		GIDSignIn.sharedInstance.signOut()
		isLoggedIn = false
//		self.checkStatus()
	}
}

