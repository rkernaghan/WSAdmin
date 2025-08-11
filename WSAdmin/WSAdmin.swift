//
//  WSAdmin.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-08-13.
//
import Foundation
import SwiftUI
import OSLog

struct PgmConstants {
	// Row and column position of Reference Data spreadsheet data
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
	static let dataCountActiveLocationsRow = 10
	static let dataCountActiveLocationsCol = 0
	static let dataCountHighestLocationKeyRow = 11
	static let dataCountHighestLocationKeyCol = 0
	
	static let tutorDataStudentCountRow = 3
	static let tutorDataStudentCountCol = 1
	static let tutorDataServiceCountRow = 4
	static let tutorDataServiceCountCol = 1
	
	static let testRefFileName = "ReferenceData - TEST"
	static let prodRefFileName = "ReferenceData"
	static let dataCountRange = "Master!B2:B13"
	static let tutorRange = "Master!D2:Q"
	static let studentRange = "Master!T3:AI"
	static let serviceRange = "Master!AL3:AX"
	static let locationRange = "Master!BA2:BF"
	
	static let tutorCountsRange = "!A1:B5"
	static let tutorStudentsRange = "!O3:T"
	static let tutorServicesRange = "!D3:M"
	static let tutorDataCountsRange = "!B4:B5"
	static let tutorDataTutorNameCell = "!B2:B2"
	static let tutorDataTimesheetFileIDRange = "!B3:B3"
	
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
	
	static let tutorDataStudentsStartingRowNumber = 3
	static let tutorDataStudentKeyPosition = 0
	static let tutorDataStudentNamePosition = 1
	static let tutorDataStudentClientNamePosition = 2
	static let tutorDataStudentClientEmailPosition = 3
	static let tutorDataStudentClientPhonePosition = 4
	static let tutorDataStudentAssignedDatePosition = 5
	
	static let tutorDataServicesStartingRowNumber = 3
	static let tutorDataServiceKeyPosition = 0
	static let tutorDataServiceTimesheetNamePosition = 1
	static let tutorDataServiceInvoiceNamePosition = 2
	static let tutorDataServiceBillingTypePosition = 3
	static let tutorDataServiceCost1Position = 4
	static let tutorDataServiceCost2Position = 5
	static let tutorDataServiceCost3Position = 6
	static let tutorDataServicePrice1Position = 7
	static let tutorDataServicePrice2Position = 8
	static let tutorDataServicePrice3Position = 9
	
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
	static let serviceCountPosition = 6
	static let serviceCost1Position = 7
	static let serviceCost2Position = 8
	static let serviceCost3Position = 9
	static let servicePrice1Position = 10
	static let servicePrice2Position = 11
	static let servicePrice3Position = 12
	
	static let locationStartingRowNumber = 2
	static let locationKeyPosition = 0
	static let locationNamePosition = 1
	static let locationMonthRevenuePosition = 2
	static let locationTotalRevenuePosition = 3
	static let locationStudentCountPosition = 4
	static let locationStatusPosition = 5
	
	static let monthNames = ["Jan", "Feb", "Mar", "April", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"]
	static let yearNames = ["2024","2025","2026","2027","2028","2029","2030","2031","2032","2032"]
	static let firstTimesheetRow = 5
	static let servicePrompt = "Choose Service"
	static let studentPrompt = "Choose Student"
	static let notePrompt = "Choose Note"
	
	static let tutorKeyPrefix = "T"
	static let studentKeyPrefix = "S"
	static let serviceBaseKeyPrefix = "B"
	static let serviceSpecialKeyPrefix = "X"
	static let locationKeyPrefix = "C"
	
	static let tutorDetailsTestFileName: String = "Tutor Details Data - TEST"
	static let tutorDetailsShadowFileName: String = "Tutor Details Data - Shadow"
	static let tutorDetailsProdFileName: String = "Tutor Details Data"
	static let referenceDataTestFileName: String = "ReferenceData - TEST"
	static let referenceDataShadowFileName: String = "ReferenceData - Shadow"
	static let referenceDataProdFileName: String = "ReferenceData"
	static let studentBillingTestFileNamePrefix: String = "Student Billing Summary - TEST "
	static let studentBillingShadowFileNamePrefix: String = "Student Billing Summary - Shadow "
	static let studentBillingProdFileNamePrefix: String = "Student Billing Summary "
	static let tutorBillingTestFileNamePrefix: String = "Tutor Billing Summary - TEST "
	static let tutorBillingShadowFileNamePrefix: String = "Tutor Billing Summary - Shadow "
	static let tutorBillingProdFileNamePrefix: String = "Tutor Billing Summary "
	static let timesheetTemplateTestFileName: String = "Template Timesheet - TEST"
	static let timesheetTemplateProdFileName: String = "Template Timesheet"
	static let billedTutorTemplateFileName: String = "Template Tutor Billing Summary year"
	static let billedStudentTemplateFileName: String = "Template Student Billing Summary year"
	
	static let tutorHeaderArray1 = ["TUTOR", " ", " ", "Service Key", "Timesheet Name", "Invoice Name", "Billing Type", "Cost 1", "Cost 2", "Cost 3", "Price 1", "Price 2", "Price 3", " ", "Student Key", "Student Name", "Client Name", "Client Email", "Client Phone","Assigned Date"]
	static let tutorHeaderArray2 = [" ", " ", " ", "B000", "-", " ", " ", " ", " ", " ", " ", " ", " ", " ", "S0000", "-"]
	static let tutorHeader1Range = "!A1:T2"
	static let tutorHeader1Array = [tutorHeaderArray1, tutorHeaderArray2]
	static let tutorHeader2Array = [["Student Count", "0"], ["Service Count", "0"],["Notes Count","=RefData!A1"]]
	static let tutorHeader2Range = "!A4:B6"
	static let tutorHeader3Range = "!A2:B3"
	
	static let timesheetSessionCountRow: Int = 2
	static let timesheetSessionCountCol: Int = 1
	static let timesheetFirstSessionRow: Int = 4
	static let timesheetStudentCol = 0
	static let timesheetDateCol = 1
	static let timesheetDurationCol = 2
	static let timesheetServiceCol = 3
	static let timesheetNotesCol = 4
	static let timesheetCostCol = 5
	static let timesheetClientNameCol = 6
	static let timesheetClientEmailCol = 7
	static let timesheetClientPhoneCol = 8
	static let timesheetDataRange = "!A1:I102"
	static let timesheetTutorNameCell = "RefData!A2:A2"
	static let timesheetAvailabilityDataRange = "Availability!A1:C10"
	
	static let studentBillingCountRange = "!A2:A2"
	static let studentBillingRange = "!A4:T"
	static let studentBillingStartRow = 4
	static let studentBillingStudentCol = 0
	static let studentBillingMonthSessionCol = 1					// Session count for the month for the student generated by bill generation (creating CSV file)
	static let studentBillingMonthCostCol = 2
	static let studentBillingMonthRevenueCol = 3
	static let studentBillingMonthProfitCol = 4					// Profit for the Student for the month generated by bill generation
	static let studentBillingTotalSessionCol = 5
	static let studentBillingTotalCostCol = 6
	static let studentBillingTotalRevenueCol = 7
	static let studentBillingTotalProfitCol = 8					// Total profit for the Student generated by bill generation
	static let studentBillingTutorCol = 9
	static let studentBillingStatusCol = 10
	static let studentValidatedMonthSessionCol = 12					// Session count for the month for the student computed by billing stats validation
	static let studentValidatedMonthCostCol = 13
	static let studentValidatedMonthRevenueCol = 14
	static let studentValidatedMonthProfitCol = 15					// Profit for the Student for the month computed by billing stats validation
	static let studentValidatedTotalSessionCol = 16
	static let studentValidatedTotalCostCol = 17
	static let studentValidatedTotalRevenueCol = 18
	static let studentValidatedTotalProfitCol = 19					// Total profit for the Student computed by billing stats validation
	
	static let tutorBillingCountRange = "!A2:A2"
	static let tutorBillingRange = "!A4:S"
	static let tutorBillingStartRow = 4
	static let tutorBillingTutorCol = 0
	static let tutorBillingMonthSessionCol = 1
	static let tutorBillingMonthCostCol = 2
	static let tutorBillingMonthRevenueCol = 3
	static let tutorBillingMonthProfitCol = 4
	static let tutorBillingTotalSessionCol = 5
	static let tutorBillingTotalCostCol = 6
	static let tutorBillingTotalRevenueCol = 7
	static let tutorBillingTotalProfitCol = 8
	static let tutorBillingStatusCol = 9
	static let tutorValidatedMonthSessionCol = 11
	static let tutorValidatedMonthCostCol = 12
	static let tutorValidatedMonthRevenueCol = 13
	static let tutorValidatedMonthProfitCol = 14
	static let tutorValidatedTotalSessionCol = 15
	static let tutorValidatedTotalCostCol = 16
	static let tutorValidatedTotalRevenueCol = 17
	static let tutorValidatedTotalProfitCol = 18
	
	static let termsString: String = "14 days"
	static let taxCodeString: String = "N"
	static let csvSeperator: String = ","
	static let crlf: String = "\r\n"
	static let csvHeader: String = "InvoiceNo,Customer,CustomerEmail,*InvoiceDate,*DueDate,Term,Location,TutorName,Item(Product/Service),ItemDescrip,ItemQuantity,ItemRate,*ItemAmount,*ItemTaxCode,ServiceDate"
	
	static let stephenEmail: String = "stephen.kernaghan@gmail.com"
	static let writeSeattleEmail: String = "info@writeseattle.com"
	static let russellEmail: String = "rskernaghan@gmail.com"
	static let serviceAccountEmail: String = "service-account1@writeseattle2.iam.gserviceaccount.com"
	
	static let systemStartMonthIndex = 6
	static let systemStartYearIndex = 0
}

// Defines the type of a Service
enum ServiceTypeOption: String, CaseIterable, Identifiable, CustomStringConvertible {
	case Base
	case Special
	
	var id: Self { self }
	
	var description: String {
		
		switch self {
			case .Base:
				return "Base"		// Base Services apply to all Tutors and new Base Services are added to all Tutors
			case .Special:
				return "Special"	// Special Services are assigned to individual Tutors
		}
	}
}

enum BillingTypeOption: String, CaseIterable, Identifiable, CustomStringConvertible {
	case Fixed
	case Variable
	
	var id: Self { self }
	
	var description: String {
		
		switch self {
			case .Fixed:
				return "Fixed"		// Fixed cost regardless of tutoring session duration
			case .Variable:
				return "Variable"	// Cost is pro-rated based on the number of minutes
		}
	}
}

enum StudentTypeOption: String, CaseIterable, Identifiable, CustomStringConvertible {
	case Minor
	case Adult
	
	var id: Self { self }
	
	var description: String {
		
		switch self {
			case .Minor:
				return "Minor"
			case .Adult:
				return "Adult"
		}
	}
}

enum MonthSelector: String, CaseIterable, Identifiable, CustomStringConvertible {
	case January
	case February
	case March
	case April
	case May
	case June
	case July
	case August
	case September
	case October
	case November
	case December
	
	var id: Self { self }
	
	var description: String {
		
		switch self {
			case .January:
				return "Jan"
			case .February:
				return "Feb"
			case .March:
				return "Mar"
			case .April:
				return "April"
			case .May:
				return "May"
			case .June:
				return "June"
			case .July:
				return "July"
			case .August:
				return "Aug"
			case .September:
				return "Sept"
			case .October:
				return "Oct"
			case .November:
				return "Nov"
			case .December:
				return "Dec"
		}
	}
}

enum TypeSelector: String, CaseIterable, Identifiable, CustomStringConvertible {
	case Minor
	case Adult
	
	var id: Self { self }
	
	var description: String {
		
		switch self {
			case .Minor:
				return "Minor"
			case .Adult:
				return "Adult"
		}
	}
}

struct SheetData: Decodable {
	let range: String
	let majorDimension: String
	let values: [[String]]
}

class OAuth2Token{
	var accessToken: String?
	var refreshToken: String?
	var expiresAt: Date?
	var clientID: String?
}

let monthArray = ["Jan", "Feb", "Mar", "April", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"]
let yearArray = ["2024", "2025", "2026", "2027", "2028", "2029", "2030", "2031"]
let yearNumbersArray = [2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031]
 
var buttonErrorMsg: String = " "

var studentBillingFileNamePrefix: String = ""
var tutorBillingFileNamePrefix: String = ""
var referenceDataFileID: String = ""
var tutorDetailsFileID: String = ""
var timesheetTemplateFileID: String = ""

var accessOAuthToken: String = ""
var refreshOAuthToken: String = ""
var clientOAuthID: String = ""
var tokenExpiryTime: Date = Date.now

let oauth2Token = OAuth2Token()

var runMode: String = "PROD"			// "PROD" for production data files, anything else (e.g. "TEST" for the test data files

@main
struct WSAdmin: App {
	let systemVM = SystemVM()
	let logger = Logger()
	
	var body: some Scene {
		
		WindowGroup {
			ContentView()
		}
		.environment(systemVM)
	}
}
