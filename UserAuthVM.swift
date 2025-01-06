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
			print("UserAuthVM-signin: Could not get presenting window")
			return}
		
		print("UserAuthVM-signIn: Starting Signin")
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let userCSVURL = documentsURL.appendingPathComponent("AuthDebugFiles")
		
		do {
			try FileManager.default.createDirectory(at: userCSVURL, withIntermediateDirectories: true, attributes: nil)
			
			do {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
				let fileDate = dateFormatter.string(from: Date())
				
				let fileName = "UserAuth Debug File \(fileDate).txt"
				let fileManager = FileManager.default
				
				// Get the path to the Documents directory
				guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
					print("Could not find the Documents directory.")
					return
				
				}
				
				// Set the file path
				let fileURL = documentsDirectory.appendingPathComponent(fileName)
				
				// Create the file if it doesn't exist
				if !fileManager.fileExists(atPath: fileURL.path) {
					fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
				}
				// Open the file for writing
				let fileHandle = try FileHandle(forWritingTo: fileURL)
				
				GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) {signInResult, error in
					if let error = error  {
						print("UserAuthVM-signIn: Sign in error: \(error.localizedDescription)")
						var data = "UserAuthVM-signIn: Sign in error: \(error.localizedDescription)\n".data(using: .utf8)!
						fileHandle.write(data)
						
						data = "UserAuthVM-signIn: Sign in error: \(error)\n".data(using: .utf8)!
						fileHandle.write(data)
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
					
//					if self.checkAuthScope(fileHandle: fileHandle) == false {
					if self.checkAuthScope() == false {
//						let authScopeStatus = self.getAuthScope(fileHandle: fileHandle)
						let authScopeStatus = self.getAuthScope()
						if authScopeStatus == false {
							print("UserAuthVM-signIn: Could not get additional scope")
							let data = "UserAuthVM-signIn: Could not get additional scope\n".data(using: .utf8)!
							fileHandle.write(data)
							self.isLoggedIn = false
						} else {
							print("UserAuthVM-signIn: Got additional scope")
							let data = "UserAuthVM-signIn: Got additional scope\n".data(using: .utf8)!
							fileHandle.write(data)
							self.isLoggedIn = true
						}
					} else {
						print("UserAuthVM-signIn: Already had scope")
						let data = "UserAuthVM-signIn: Already had scope\n".data(using: .utf8)!
						fileHandle.write(data)
						self.isLoggedIn = true
					}
//				print("Closing filehandle")
//				fileHandle.closeFile()
				}

					
			} catch {
				print("Error: Could not write to CSV file: \(error)")
	
	
			}
		} catch {
			print("Error creating directory: \(error)")
	
	
		}
		
		
	}
	
	
	
	// Attempts to restore previousGoogle signin
	//
	func restoreSignIn() {
		
		print("UserAuthVM-restoreSignIn: Starting restoreSignIn function")
		let data = "UserAuthVM-restoreSignIn: Starting restoreSignIn function\n".data(using: .utf8)!
//		fileHandle.write(data)
		
		GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
			if let error = error {
				self.errorMessage = "error: \(error.localizedDescription)"
				print("UserAuthVM-restoreSignIn: Could not restore previous signin \(self.errorMessage)")
				let data = "UserAuthVM-restoreSignIn: Could not restore previous signin \(self.errorMessage)\n".data(using: .utf8)!
//				fileHandle.write(data)
			}
			
			self.checkSignInStatus()
		}
	}
	
	// Checks if user is logged in and if so:
	//		- sets up OAuth attributes to manage token expiry
	//		- determines whether the user already has necessary Google scope
	//
//	func checkStatus(fileHandle: FileHandle) {
	func checkSignInStatus() {
		var tokenExpirationDate: Date?
		
		print("UserAuthVM-checkStatus: Starting checkStatus")
		let data = "UserAuthVM-checkStatus: Starting checkStatus\n".data(using: .utf8)!
//		fileHandle.write(data)
		
		if (GIDSignIn.sharedInstance.currentUser != nil) {
			print("UserAuthVM-checkstatus: User is logged in")
			let data = "UserAuthVM-checkstatus: User is logged in\n".data(using: .utf8)!
//			fileHandle.write(data)
			let user = GIDSignIn.sharedInstance.currentUser
			guard let user = user else {
				print("UserAuthVM-checkStatus: User signed in but user is nil, returning early")
				let data = "UserAuthVM-checkStatus: User signed in but user is nil, returning early\n".data(using: .utf8)!
//				fileHandle.write(data)
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
				
//				let scopeStatus = checkAuthScope(fileHandle: fileHandle)
				let scopeStatus = checkAuthScope()
				if !scopeStatus {
					print("UserAuthVM-checkStatus: User did not have scope, requesting it")
					let data = "UserAuthVM-checkStatus: User did not have scope, requesting it\n".data(using: .utf8)!
//					fileHandle.write(data)
//					let scopeRequest = getAuthScope(fileHandle: fileHandle)
					let scopeRequest = getAuthScope()
					if scopeRequest {
						print("UserAuthVM-checkStatus: Scope request succeeded")
						let data = "UserAuthVM-checkStatus: Scope request succeeded\n".data(using: .utf8)!
//						fileHandle.write(data)
						self.isLoggedIn = true
					} else {
						self.isLoggedIn = false
						print("UserAuthVM-checkStatus: Scope request failed")
						let data = "UserAuthVM-checkStatus: Scope request failed\n".data(using: .utf8)!
//						fileHandle.write(data)
					}
				} else {
					print("UserAuthVM-checkStatus: User already has scope")
					let data = "UserAuthVM-checkStatus: Starting checkStatus\n".data(using: .utf8)!
//					fileHandle.write(data)
					self.isLoggedIn = true
				}
			} else {
				print("UserAuthVM-checkStatus: User not logged in")
				let data = "UserAuthVM-checkStatus: User not logged in\n".data(using: .utf8)!
//				fileHandle.write(data)
				self.isLoggedIn = false
			}
		}
	}
	
	// Checks whether user has necessary Goolge scopes necessary for program
	// "drive" scope required to create new Timesheet for new Tutor
	//
//	func checkAuthScope(fileHandle: FileHandle) -> Bool {
	func checkAuthScope() -> Bool {
		let additionalScopes = [sheetScope, driveScope]
		guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
			print("UserAuthVM-checkAuthScope: Not signed in")
			let data = "UserAuthVM-checkAuthScope: Not signed in\n".data(using: .utf8)!
//			fileHandle.write(data)
			return(false) ;  /* Not signed in. */
		}
		
		let grantedScopes = currentUser.grantedScopes
		if grantedScopes == nil || !grantedScopes!.contains(sheetScope) {
			print("UserAuthVM-checkAuthScope: Need to request additional scope")
			let data = "UserAuthVM-checkAuthScope: Need to request additional scope\n".data(using: .utf8)!
//			fileHandle.write(data)
			return(false)
		} else {
			print("UserAuthVM-checkAuthScope: Already have scope")
			let data = "UserAuthVM-checkAuthScope: Already have scope\n".data(using: .utf8)!
//			fileHandle.write(data)
			return(true)
		}
	}
	
	// Requests additional scopes necessary for the program from Google, which in turn prompts user to approve
	//	https://www.googleapis.com/auth/spreadsheets scope is required to read and write spreadsheets
	//	https://www.googleapis.com/auth/drive scope is required to get fileIDs, create new timesheets, rename spreadsheets/timesheets, etc.
	//
//	func getAuthScope(fileHandle: FileHandle ) -> Bool {
	func getAuthScope( ) -> Bool {
		var gotAuthScope: Bool = false
		
		print("UserAuthVM-getAuthScope: Starting")
		let data = "UserAuthVM-getAuthScope: Starting\n".data(using: .utf8)!
//		fileHandle.write(data)
		let additionalScopes = [driveScope,sheetScope]
		guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
			print("UserAuthVM-getAuthScope: Not signed in")
			let data = "UserAuthVM-getAuthScope: Not signed in\n".data(using: .utf8)!
//			fileHandle.write(data)
			return(gotAuthScope) ;  /* Not signed in. */
		}
		guard let presentingWindow = NSApplication.shared.mainWindow else {
			print("UserAuthVM-getAuthScope: No presenting window")
			let data = "UserAuthVM-getAuthScope: No presenting window\n".data(using: .utf8)!
//			fileHandle.write(data)
			return(gotAuthScope)}
		
		currentUser.addScopes(additionalScopes, presenting: presentingWindow) { signInResult, error in
			if let error = error {
				print("UserAuthVM-getAuthScope: Error requesting additional scopes: \(error.localizedDescription)")
				let data = "UserAuthVM-getAuthScope: Error requesting additional scopes: \(error.localizedDescription)\n".data(using: .utf8)!
//				fileHandle.write(data)
				self.isLoggedIn = false
			} else {
				print("UserAuthVM-getAuthScope: Additional scopes granted.")
				let data = "UserAuthVM-getAuthScope: Additional scopes granted.\n".data(using: .utf8)!
//				fileHandle.write(data)
				self.isLoggedIn = true
				gotAuthScope = true
				// Can now use the updated user to make authenticated API requests
				if let grantedScopes = currentUser.grantedScopes {
					print("UserAuthVM-getAuthScope: Granted scopes: \(grantedScopes)")
					let data = "UserAuthVM-getAuthScope: Granted scopes: \(grantedScopes)\n".data(using: .utf8)!
//					fileHandle.write(data)
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

