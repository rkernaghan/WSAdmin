//
//  WSAdmin.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//

import SwiftUI

struct PgmConstants {
    static let dataCountTotalStudentsRow = 0
    static let dataCountTotalStudentsCol = 0
    static let dataCountActiveStudentsRow = 1
    static let dataCountActiveStudentsCol = 0
    static let dataCountHighestStudentKeyRow = 2
    static let dataCountHighestStudentKeyCol = 0
    static let dataCountTotalTutorsRow = 3
    static let dataCountTotalTutorsCol = 0
    static let dataCountActiveTutorsRow = 4
    static let dataCountActiveTutorsCol = 0
    static let dataCountHighestTutorKeyRow = 5
    static let dataCountHighestTutorKeyCol = 0
    static let dataCountTotalServicesRow = 6
    static let dataCountTotalServicesCol = 0
    static let dataCountActiveServicesRow = 7
    static let dataCountActiveServicesCol = 0
    static let dataCountHighestServiceKeyRow = 8
    static let dataCountHighestServiceKeyCol = 0
    static let dataCountTotalLocationsRow = 9
    static let dataCountTotalLocationsCol = 0
    static let dataCountHighestLocationKeyRow = 10
    static let dataCountHighestLocationKeyCol = 0
    
    static let tutorDataStudentCountRow = 3
    static let tutorDataStudentCountCol = 1
    static let tutorDataServiceCountRow = 4
    static let tutorDataServiceCountCol = 1
    
    static let testRefFileName = "ReferenceData - TEST"
    static let prodRefFileName = "ReferenceData"
    static let dataCountRange = "Master!B2:B12"
    static let tutorRange = "Master!D2:Q"
    static let studentRange = "Master!T3:AI"
//    static let serviceRange = "Master!AL3:AW"
    static let serviceRange = "Master!AL3:AW"
    static let locationRange = "Master!AZ3:BC"
    
    static let tutorCountsRange = "!A1:B5"
    static let tutorStudentsRange = "!O3:S"
    static let tutorServicesRang = "!D3:M"
    
    static let tutorStartingRowNumber = 2
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
    
    static let tutorDataStudentsStartingRowNumber = 2
    static let tutorDataStudentKeyPosition = 0
    static let tutorDataStudentNamePosition = 1
    static let tutorDataStudentClientNamePosition = 2
    static let tutorDataStudentClientEmailPosition = 3
    static let tutorDataStudentClientPhonePosition = 4
    
    static let studentStartingRowNumber = 3
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
    
    static let serviceStartingRowNumber = 3
    static let serviceKeyPosition = 0
    static let serviceTimesheetNamePosition = 1
    static let serviceInvoiceNamePosition = 2
    static let serviceTypePosition = 3
    static let serviceBillingTypePosition = 4
    static let serviceStatusPosition = 5
    static let serviceCost1Position = 6
    static let serviceCost2Position = 7
    static let serviceCost3Position = 8
    static let servicePrice1Position = 9
    static let servicePrice2Position = 10
    static let servicePrice3Position = 11
    
    static let locationStartingRowNumber = 3
    static let locationKeyPosition = 0
    static let locationNamePosition = 1
    static let locationMonthRevenuePosition = 2
    static let locationTotalRevenuePosition = 3
    
    static let monthNames = ["Jan", "Feb", "Mar", "April", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"]
    static let firstTimesheetRow = 5
    static let servicePrompt = "Choose Service"
    static let studentPrompt = "Choose Student"
    static let notePrompt = "Choose Note"
    
    static let tutorKeyPrefix = "T"
    static let studentKeyPrefix = "S"
    static let serviceBaseKeyPrefix = "B"
    static let serviceSpecialKeyPrefix = "X"
    static let locationKeyPrefix = "C"
    
    static let testReferenceDataFileID: String = "1RdR_GPxAWcDUWBU-eytGKw2uzZhy3yR-MdQegmBZNis"
    static let testTutorDataFileID: String = "1NaSjIe43RrGEa4AdAKHuF343eHlfogzuMuS5SPvowS8"
    static let prodReferenceDataFileID: String = "18GxBUhOAG2arOR0YkTFcv546ujKZ_JyJYkhyawVSMiY"
    static let prodTutorDataFileID: String = "1W6AUOVc91D1YCm2miloHQeMmcOZc2jjc7nEbE0Gnkmg"
}

var submitErrorMsg: String = " "
var runMode: String = "TEST"

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
