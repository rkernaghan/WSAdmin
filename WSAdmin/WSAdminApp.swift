//
//  WSAdminApp.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//

import SwiftUI

struct PgmConstants {
    static let dataCountRange = "Master!A2:B12"
    static let tutorRange = "Master!D2:P"
    static let studentRange = "Master!R3:AG"
    static let serviceRange = "Master!AI3:AT"
    static let cityRange = "Master!AV3:AY"
    
    static let tutorKeyPosition = 0
    static let tutorNamePosition = 1
    static let tutorEmailPosition = 2
    static let tutorPhonePosition = 3
    static let tutorStatusPosition = 4
    static let tutorStartDatePosition = 5
    static let tutorEndDatePosition = 6
    static let tutorMaxStudentPosition = 7
    static let tutorStudentCountPosition = 8
    static let tutorServiceCountPosition = 9
    static let tutorSessionCountPosition = 10
    static let tutorTotalCostPosition = 11
    static let tutorTotalRevenuePosition = 12
    static let tutorTotalProfitPosition = 13
    
    static let studentKeyPosition = 0
    static let studentNamePosition = 1
    static let studentGuardianPosition = 2
    static let studentPhonePosition = 3
    static let studentEmailPosition = 4
    static let studentTypePosition = 5
    static let studentStartDatePosition = 6
    static let studentEndDatePosition = 7
    static let studentStatusPosition = 8
    static let studentTutorKeyPosition = 9
    static let studentTutorNamePosition = 10
    static let studentLocationPosition = 11
    static let studentSessionsPosition = 12
    static let studentTotalCostPosition = 13
    static let studentTotalRevenuePosition = 14
    static let studentTotalProfitPosition = 15
    
    static let serviceKeyPosiiton = 0
    static let serviceTimesheetNamePosition = 1
    static let serviceInvoiveNamePosition = 2
    static let serviceTypePosition = 3
    static let serviceBillingTypePosition = 4
    static let serviceStatusPosition = 5
    static let serviceCost1Position = 6
    static let serviceCost2Position = 7
    static let serviceCost3Position = 8
    static let servicePrice1Position = 9
    static let servicePrice2Position = 10
    static let servicePrice3Position = 11
    
    static let cityKeyPosition = 0
    static let cityNamePosition = 1
    static let cityMonthRevenuePosition = 2
    static let cityTotalRevenuePosition = 3
    
    static let monthNames = ["Jan", "Feb", "Mar", "April", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"]
    static let firstTimesheetRow = 5
    static let servicePrompt = "Choose Service"
    static let studentPrompt = "Choose Student"
    static let notePrompt = "Choose Note"
}
var submitErrorMsg: String = " "
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
