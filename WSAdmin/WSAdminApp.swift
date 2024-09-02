//
//  WSAdminApp.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//

import SwiftUI

@main
struct WSAdmin: App {
    
    var body: some Scene {
       
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Students") {
            
            }
            CommandMenu("Services") {
                
            }
            CommandMenu("Tutors") {
                
            }
        }
    }
}
