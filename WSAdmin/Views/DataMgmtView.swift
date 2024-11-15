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
    
	var body: some View {
		
		VStack {
			SideView(referenceData: referenceData)
				.frame(minWidth: 100, minHeight: 140)
			
				.onAppear(perform: {
					Task {
						if runMode == "PROD" {
							(_, tutorDetailsFileID) = try await getFileID(fileName: PgmConstants.tutorDetailsProdFileName)
							(_, referenceDataFileID) = try await getFileID(fileName: PgmConstants.referenceDataProdFileName)
							(_, timesheetTemplateFileID) = try await getFileID(fileName: PgmConstants.timesheetTemplateTestFileName)
							studentBillingFileNamePrefix = PgmConstants.studentBillingProdFileNamePrefix
							tutorBillingFileNamePrefix = PgmConstants.tutorBillingProdFileNamePrefix
						} else {
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
	@State private var showAlert: Bool = false
	
	@Environment(UserAuthVM.self) var userAuthVM: UserAuthVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(SystemVM.self) var systemVM: SystemVM
        
	var body: some View {
 
		List {
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
				BillingView(referenceData: referenceData)
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
			
			Button("Validate System") {
				Task {
					await systemVM.validateSystem(referenceData: referenceData)
				}
			}
			Button("Backup System") {
				Task {
					await systemVM.backupSystem()
				}
			}
			Button("Create Next Years Files") {
				Task {
					let (generateResult, generateMessage) = await systemVM.generateNewYearFiles(referenceData: referenceData)
					if !generateResult {
						showAlert.toggle()
						buttonErrorMsg = generateMessage
					}
				}
			}
                
		}
		
//            	.listStyle(SidebarListStyle())
		.navigationTitle("Sidebar")
            
		Button(action: {
			userAuthVM.signOut()
                //                dismiss() }) {
		}) {
			Text("Sign Out")
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
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
