//
//  DataMgmtView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-02.
//
import Foundation
import SwiftUI

struct Option: Hashable {
	let title: String
	let imageName: String
}

class FileData {
//    var fileID: String = " "
	var testTutorBillingFile: String = " "
	var testStudentBillingFile: String = " "
    
	var prodTutorBillingFile: String = " "
	var prodStudentBillingFile: String = " "
	}

class ReferenceData {
	var tutors = TutorsList()
	var students = StudentsList()
	var services = ServicesList()
	var locations = LocationsList()
	var dataCounts = DataCounts()
}

struct DataMgmtView: View {

	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(SystemVM.self) var systemVM: SystemVM

	var fileIDs = FileData()
	var dataCounts = DataCounts()
	@State var referenceData = ReferenceData()
	@State private var showAlert: Bool = false
	@State private var statusMessage: String = ""
    
	var body: some View {
		
		VStack {
			SideView(referenceData: referenceData, statusMessage: $statusMessage)
				.frame(minWidth: 100, minHeight: 140)
			
				.onAppear(perform: {
					Task {
						if runMode == "PROD" {
							(_, tutorDetailsFileID) = try await getFileID(fileName: PgmConstants.tutorDetailsProdFileName)
							(_, referenceDataFileID) = try await getFileID(fileName: PgmConstants.referenceDataProdFileName)
							(_, timesheetTemplateFileID) = try await getFileID(fileName: PgmConstants.timesheetTemplateProdFileName)
							studentBillingFileNamePrefix = PgmConstants.studentBillingProdFileNamePrefix
							tutorBillingFileNamePrefix = PgmConstants.tutorBillingProdFileNamePrefix
						} else if runMode == "SHADOW" {
							(_, tutorDetailsFileID) = try await getFileID(fileName: PgmConstants.tutorDetailsShadowFileName)
							(_, referenceDataFileID) = try await getFileID(fileName: PgmConstants.referenceDataShadowFileName)
							(_, timesheetTemplateFileID) = try await getFileID(fileName: PgmConstants.timesheetTemplateProdFileName)
							studentBillingFileNamePrefix = PgmConstants.studentBillingShadowFileNamePrefix
							tutorBillingFileNamePrefix = PgmConstants.tutorBillingShadowFileNamePrefix
						} else if runMode == "TEST"{
							(_, tutorDetailsFileID) = try await getFileID(fileName: PgmConstants.tutorDetailsTestFileName)
							(_, referenceDataFileID) = try await getFileID(fileName: PgmConstants.referenceDataTestFileName)
							(_, timesheetTemplateFileID) = try await getFileID(fileName: PgmConstants.timesheetTemplateTestFileName)
							studentBillingFileNamePrefix = PgmConstants.studentBillingTestFileNamePrefix
							tutorBillingFileNamePrefix = PgmConstants.tutorBillingTestFileNamePrefix
						}
						let loadResult = await refDataVM.loadReferenceData(referenceData: referenceData)
						if !loadResult {
							showAlert.toggle()
							buttonErrorMsg = "Critical Error: Unable to load Reference Data - Restart program"
						} else {
							statusMessage = "Reference Data Loaded"
						}
					}
				})
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
			
	}
	
}

struct SideView: View {
	var referenceData: ReferenceData
	@Binding var statusMessage: String
	
	@State private var showAlert: Bool = false
	@State private var showFinanceSummary: Bool = false
	@State private var showTutorAvailabilitySummary: Bool = false
	@State private var showDataIntegritySummary: Bool = false
	@State private var financeSummaryArray = [FinanceSummaryRow]()
	@State private var tutorAvailabilityArray = [TutorAvailabilityRow]()
	@State private var validationMessages = WindowMessages()
	
	@Environment(UserAuthVM.self) var userAuthVM: UserAuthVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(SystemVM.self) var systemVM: SystemVM
	@Environment(FinanceSummaryVM.self) var financeSummaryVM: FinanceSummaryVM
        
	var body: some View {
 
		List {
			Text(statusMessage)
			.padding()
			
			NavigationLink {
				TutorListView(referenceData: referenceData)
			} label: {
				Label("Tutors", systemImage: "person")
			}
                
			NavigationLink {
				StudentListView(referenceData: referenceData)
			} label: {
				Label("Students", systemImage: "graduationcap")
			}
                
			NavigationLink {
				ServiceListView(referenceData: referenceData)
			} label: {
				Label("Services", systemImage: "list.bullet")
			}
                
			NavigationLink {
				LocationListView(referenceData: referenceData)
			} label: {
				Label("Locations", systemImage: "building")
			}

			NavigationLink {
				BillingSelectionView(referenceData: referenceData)
			} label: {
				Label("Billing", systemImage: "person")
			}
                
			NavigationLink {
				TutorView( updateTutorFlag: false, tutorNum: 0, originalTutorName: "", referenceData: referenceData, tutorName: "", tutorEmail: "", tutorPhone: "", maxStudents: 0)
			} label: {
				Label("Add Tutor", systemImage: "person")
			}
                
			NavigationLink {
				StudentView(updateStudentFlag: false, originalStudentName: "", referenceData: referenceData, studentKey: "", studentName: "", guardianName: "", contactPhone: "", contactEmail: "", location: "", studentType: .Minor)
			} label: {
				Label("Add Student", systemImage: "graduationcap")
			}
                
			NavigationLink {
				ServiceView(updateServiceFlag: false, serviceNum: 0, originalTimesheetName: "", referenceData: referenceData, serviceKey: " ", timesheetName: "", invoiceName: "", serviceType: .Base, billingType: .Fixed, serviceCount: 0, cost1: 0.0, cost2: 0.0, cost3: 0.0, price1: 0.0, price2: 0.0, price3: 0.0 )
			} label: {
				Label("Add Service", systemImage: "list.bullet")
			}
                
			NavigationLink {
				LocationView(updateLocationFlag: false, locationNum: 0, originalLocationName: "" , referenceData: referenceData, locationName: "")
			} label: {
				Label("Add Location", systemImage: "building")
			}
			
			Spacer()
			
			Button("Tutor Availability Summary") {
				Task {
					statusMessage = " "
					tutorAvailabilityArray = await tutorMgmtVM.buildTutorAvailabilityArray(referenceData: referenceData)
					showTutorAvailabilitySummary = true
				}
			}
			
			Button("Finance Summary") {
				Task {
					statusMessage = " "
					financeSummaryArray = await financeSummaryVM.buildFinanceSummary()
					showFinanceSummary = true
				}
			}
			
			Button("Validate System Data Integrity") {
				Task {
					statusMessage = " "
					await systemVM.validateSystem(referenceData: referenceData, validationMessages: validationMessages)
					showDataIntegritySummary = true
				}

			}
	
			
			Button("Backup System") {
				Task {
					statusMessage = " "
					let backupFlag = await systemVM.backupSystem()
					if backupFlag {
						statusMessage = "Backup Successful"
					} else {
						statusMessage = "Backup Failed"
					}
				}
			}
			
			NavigationLink {
				ValidationMonthSelectionView(referenceData: referenceData)
			} label: {
				Label("Validate Month", systemImage: "person")
			
			}
			
			
			Button("Create Next Years Files") {
				Task {
					statusMessage = " "
					let (generateResult, generateMessage) = await systemVM.generateNewYearFiles(referenceData: referenceData)
					if !generateResult {
						showAlert.toggle()
						buttonErrorMsg = generateMessage
					}
				}
			}
			
			Button("Update Tutor Timesheet File IDs") {
				Task {
					statusMessage = " "
					let (updateResult, updateMessage) = await systemVM.updateTimesheetFileIDs(referenceData: referenceData)
					if !updateResult {
						showAlert.toggle()
						buttonErrorMsg = updateMessage
					}
				}
			}
			
			Button(action: {
				userAuthVM.signOut()
				//                dismiss() }) {
			}) {
				Text("Sign Out")
			}
                
		}
		
//            	.listStyle(SidebarListStyle())
		.navigationTitle("Sidebar")
            
		
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
		.navigationDestination(isPresented: $showFinanceSummary) {
			FinanceSummary(financeSummaryArray: financeSummaryArray)
		}
		.navigationDestination(isPresented: $showTutorAvailabilitySummary) {
			TutorAvailabilityView(tutorAvailabilityArray: tutorAvailabilityArray)
		}
		.navigationDestination(isPresented: $showDataIntegritySummary) {
			ValidateDataIntegrityView(validationMessages: validationMessages, referenceData: referenceData)
		}
		.padding()
		.clipShape(RoundedRectangle(cornerRadius: 10))
	}
	

}


struct MainView: View {
	var referenceData: ReferenceData
	
	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	
	var body: some View {
		
		Text(" Main View")
	}
}

#Preview {
	DataMgmtView()
}
