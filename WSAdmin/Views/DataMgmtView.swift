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
	@Environment(BilledTutorVM.self) var billedTutorVM: BilledTutorVM
	@Environment(BilledStudentVM.self) var billedStudentVM: BilledStudentVM
    
	var fileIDs = FileData()
	var dataCounts = DataCounts()
	@State var referenceData = ReferenceData()
    
	var body: some View {
		
		SideView(referenceData: referenceData)
			.frame(minWidth: 100, minHeight: 100)
			.toolbar {
				ToolbarItemGroup {
					
					Button(role: .destructive) {
					    Task {
						    await systemVM.validateSystem(referenceData: referenceData)
					    }
					} label: {
					    Label("Validate System", systemImage: "trash")
					}
					
					Button(role: .destructive) {
					    Task {
						await systemVM.backupSystem()
					    }
					} label: {
					    Label("Backup System", systemImage: "trash")
					}
				}
			}
		
			.onAppear(perform: {
				Task {
					if runMode == "PROD" {
						(_, tutorDetailsFileID) = try await getFileIDAsync(fileName: PgmConstants.tutorDetailsProdFileName)
						(_, referenceDataFileID) = try await getFileIDAsync(fileName: PgmConstants.referenceDataProdFileName)
						(_, timesheetTemplateFileID) = try await getFileIDAsync(fileName: PgmConstants.timesheetTemplateTestFileName)
						studentBillingFileNamePrefix = PgmConstants.studentBillingProdFileNamePrefix
						tutorBillingFileNamePrefix = PgmConstants.tutorBillingProdFileNamePrefix
					} else {
						(_, tutorDetailsFileID) = try await getFileIDAsync(fileName: PgmConstants.tutorDetailsTestFileName)
						(_, referenceDataFileID) = try await getFileIDAsync(fileName: PgmConstants.referenceDataTestFileName)
						(_, timesheetTemplateFileID) = try await getFileIDAsync(fileName: PgmConstants.timesheetTemplateTestFileName)
						studentBillingFileNamePrefix = PgmConstants.studentBillingTestFileNamePrefix
						tutorBillingFileNamePrefix = PgmConstants.tutorBillingTestFileNamePrefix
					}
					await refDataVM.loadReferenceData(referenceData: referenceData)
				}
			})
		
			
	}
}

struct SideView: View {
	var referenceData: ReferenceData
	@Environment(UserAuthVM.self) var userAuthVM: UserAuthVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
        
	var body: some View {
 
		List {
			NavigationLink {
				TutorsView(referenceData: referenceData)
			} label: {
				Label("Tutors", systemImage: "person")
			}
                
			NavigationLink {
				StudentsView(referenceData: referenceData)
			} label: {
				Label("Students", systemImage: "graduationcap")
			}
                
			NavigationLink {
				ServicesView(referenceData: referenceData)
			} label: {
				Label("Services", systemImage: "list.bullet")
			}
                
			NavigationLink {
				LocationsView(referenceData: referenceData)
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
                
		}
//            	.listStyle(SidebarListStyle())
		.navigationTitle("Sidebar")
            
		Button(action: {
			userAuthVM.signOut()
                //                dismiss() }) {
		}) {
			Text("Sign Out")
		}
		.padding()
		.clipShape(RoundedRectangle(cornerRadius: 10))
	}

}

struct TutorsView: View {
	@State var referenceData: ReferenceData
    
	@State private var selectedTutors: Set<Tutor.ID> = []
	@State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
	@State private var showAlert: Bool = false
	@State private var viewChange: Bool = false
	@State private var assignStudent:Bool = false
	@State private var listTutorStudents: Bool = false
	@State private var listTutorServices: Bool = false
	@State private var assignService: Bool = false
	@State private var editService: Bool = false
	@State private var editTutor: Bool = false
    
	@State private var tutorNumber: Int = 0
	@State private var showAssigned: Bool = true
	@State private var showUnassigned: Bool = true
	@State private var showDeleted: Bool = false
	@State private var showSuspended: Bool = false
    
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
	var body: some View {
		if referenceData.tutors.isTutorDataLoaded {

			var tutorArray: [Tutor] {
				if showDeleted && showSuspended && showAssigned && showUnassigned {
					return referenceData.tutors.tutorsList
				} else if showUnassigned {
					return referenceData.tutors.tutorsList.filter{$0.tutorStatus == "Unassigned"}
				} else if showDeleted {
					return referenceData.tutors.tutorsList.filter{$0.tutorStatus == "Deleted"}
				} else if showSuspended {
					return referenceData.tutors.tutorsList.filter{$0.tutorStatus == "Suspended"}
				} else {
					return referenceData.tutors.tutorsList.filter{$0.tutorStatus == "Unassigned" || $0.tutorStatus == "Assigned" }
				}
			}

			VStack {
				HStack {
					Toggle("Show Assigned", isOn: $showAssigned)
					Toggle("Show Unassigned", isOn: $showUnassigned)
					Toggle("Show Suspended", isOn: $showSuspended)
					Toggle("Show Deleted", isOn: $showDeleted)
					Text("     Tutor Count: ")
					Text(String(tutorArray.count))
				}
 
				Table(tutorArray,selection: $selectedTutors, sortOrder: $sortOrder) {
					TableColumn("Tutor Name", value: \.tutorName)
						.width(min: 100, ideal: 120, max: 240)
                    
					TableColumn("Phone", value: \.tutorPhone)
						.width(min: 80, ideal: 80, max: 100)
                    
					TableColumn("Email", value: \.tutorEmail)
						.width(min: 150, ideal: 180, max: 260)
                    
					TableColumn("Start Date", value: \.tutorStartDate)
						.width(min: 60, ideal: 80, max: 80)
                    
					TableColumn("End Date", value: \.tutorEndDate)
						.width(min: 60, ideal: 80, max: 80)
                    
					TableColumn("Status", value: \.tutorStatus)
						.width(min: 50, ideal: 70, max: 80)
                    
					TableColumn("Max\nStudents", value: \.tutorMaxStudents) { data in
						Text(String(data.tutorMaxStudents))
					}
					.width(min: 50, ideal: 60, max: 60)
                    
					TableColumn("Student\nCount", value: \.tutorStudentCount) {data in
						Text(String(data.tutorStudentCount))
					}
					.width(min: 40, ideal: 50, max: 50)
					
					TableColumn("Service\nCount", value: \.tutorServiceCount) {data in
						Text(String(data.tutorServiceCount))
					}
					.width(min: 50, ideal: 60, max: 60)
                    //                    TableColumn("Total Cost", value: \.tutorTotalCost)
                    //                    TableColumn("Total Revenue", value: \.tutorTotalRevenue)
  //                  TableColumn("Total Profit", value: \.tutorTotalProfit) { data in
  //                      Text(String(data.tutorTotalProfit.formatted(.number.precision(.fractionLength(2)))))
  //                  }
				}
				.contextMenu(forSelectionType: Tutor.ID.self) { items in
					if items.isEmpty {
						VStack {
							Button {
								print("empty selected Tutor")
							} label: {
								Label("New Tutor", systemImage: "plus")
							}
						}
					} else if items.count == 1 {
						VStack {
							
							Button("Assign Student to Tutor") {
								for objectID in items {
									if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
										tutorNumber = idx
										assignStudent = true
									}
								}
							}
                            
							Button("List Tutor Students") {
								for objectID in items {
									if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
										tutorNumber = idx
										listTutorStudents.toggle()
									}
								}
							}
							
							Button("List Tutor Services") {
								for objectID in items {
									if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
										tutorNumber = idx
										listTutorServices.toggle()
									}
								}
							}
							
							Button("Add Service to Tutor") {
								for objectID in items {
									if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
										tutorNumber = idx
										assignService.toggle()
									}
								}
							}
							
							Button("Edit Service Costs for Tutor") {
								editService.toggle()
							}
							
							Button("Edit Tutor") {
								for objectID in items {
									if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
										tutorNumber = idx
										editTutor.toggle()
									}
								}
							}
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await tutorMgmtVM.deleteTutor(indexes: items, referenceData: referenceData)
									
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Delete Tutor", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) {
									print("error alert")
								}
							}
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await tutorMgmtVM.unDeleteTutor(indexes: items, referenceData: referenceData)
									
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Undelete Tutor", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) { }
							}
							
							Button(role: .destructive) {
								Task {
									let (suspendResult, suspendMessage) = await tutorMgmtVM.suspendTutor(tutorIndex: items, referenceData: referenceData)
									
									if suspendResult == false {
										showAlert = true
										buttonErrorMsg = suspendMessage
									}
								}
							} label: {
								Label("Suspend Tutor", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) {
									print("error alert")
								}
							}
							
							Button(role: .destructive) {
								Task {
									let (unsuspendResult, unsuspendMessage) = await tutorMgmtVM.unsuspendTutor(tutorIndex: items, referenceData: referenceData)
									
									if unsuspendResult == false {
										showAlert = true
										buttonErrorMsg = unsuspendMessage
										//                                   viewChange.toggle()
									}
								}
							} label: {
								Label("UnSuspend Tutor", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) { }
							}
						}
						
					} else {
						Button {
							
						} label: {
							Label("Edit Tutors", systemImage: "heart")
						}
						
						Button(role: .destructive) {
							Task {
								let (deleteResult, deleteMessage) = await tutorMgmtVM.deleteTutor(indexes: items, referenceData: referenceData)
							}
						} label: {
							Label("Delete Tutors", systemImage: "trash")
						}
					}
				} primaryAction: { items in
					//              store.favourite(items)
				}
			}
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
			
			.navigationDestination(isPresented: $assignService) {
				ServiceSelectionView(tutorNum: $tutorNumber, referenceData: referenceData)
			}
			
			.navigationDestination(isPresented: $assignStudent) {
				StudentSelectionView(tutorNum: $tutorNumber, referenceData: referenceData)
			}
			.navigationDestination(isPresented: $listTutorStudents) {
				TutorStudentsView(tutorNum: $tutorNumber, referenceData: referenceData)
			}
			.navigationDestination(isPresented: $listTutorServices) {
				TutorServicesView(tutorNum: $tutorNumber, referenceData: referenceData)
			}
			.navigationDestination(isPresented: $editTutor) {
				TutorView( updateTutorFlag: true, tutorNum: tutorNumber, originalTutorName: referenceData.tutors.tutorsList[tutorNumber].tutorName, referenceData: referenceData, tutorName: referenceData.tutors.tutorsList[tutorNumber].tutorName, tutorEmail: referenceData.tutors.tutorsList[tutorNumber].tutorEmail, tutorPhone: referenceData.tutors.tutorsList[tutorNumber].tutorPhone, maxStudents: referenceData.tutors.tutorsList[tutorNumber].tutorMaxStudents )
			}
		}
	}
}

struct TutorStudentsList: View {
    var referenceData: ReferenceData
    var tutorIndex: Set<Tutor.ID>
    
    var body: some View {
        
   //     for objectID in tutorIndex {
   //         if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                Table(referenceData.tutors.tutorsList[0].tutorStudents) {
                    TableColumn("Student Name", value: \.studentName)
                    TableColumn("Phone", value: \.clientName)
                    TableColumn("Email", value: \.clientEmail)
                    TableColumn("Status", value: \.clientPhone)
                }
                
            }
        }
 //   }
// }


struct StudentSelectionView: View {
    @Binding var tutorNum: Int
    var referenceData: ReferenceData

    
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    @State private var selectedStudents = Set<Student.ID>()
    @State private var sortOrder = [KeyPathComparator(\Student.studentName)]
    @State private var showAlert = false
    @State private var viewChange: Bool = false

    var body: some View {
        
        //        for objectID in tutorIndex {
        //            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == tutorIndex} ) {
        VStack {
            Table(referenceData.students.studentsList.filter{$0.studentStatus != "Assigned"}, selection: $selectedStudents, sortOrder: $sortOrder) {
                
                TableColumn("Student Name", value: \.studentName)
                TableColumn("Status", value: \.studentStatus)
            }
            
            .contextMenu(forSelectionType: Tutor.ID.self) { items in
                if items.count == 1 {
                    VStack {
                        
                        Button {
                            Task {
                                await tutorMgmtVM.assignStudent(studentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
                            }
                        } label: {
                            Label("Assign Student to Tutor", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } else {
                    Button {
                        Task {
                            await tutorMgmtVM.assignStudent(studentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
                        }
                    } label: {
                        Label("Assign Students to Tutor", systemImage: "square.and.arrow.up")
                    }
                }
                    
                } primaryAction: { items in
                    //              store.favourite(items)
                }
            }
        }
    }

struct ServiceSelectionView: View {
	@Binding var tutorNum: Int
	var referenceData: ReferenceData
	
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	
	@State private var selectedServices = Set<Service.ID>()
	@State private var sortOrder = [KeyPathComparator(\Service.serviceTimesheetName)]
	@State private var showAlert = false
	@State private var viewChange: Bool = false
	
	var body: some View {
		
		VStack {
			Table(referenceData.services.servicesList.filter{$0.serviceType == .Special}, selection: $selectedServices, sortOrder: $sortOrder) {
				
				TableColumn("Timesheet Name", value: \.serviceTimesheetName)
				TableColumn("BillingType") {data in
					Text(data.serviceBillingType.rawValue)
				}
				.width(min: 50, ideal: 70, max: 80)
			}
			
			.contextMenu(forSelectionType: Tutor.ID.self) { items in
				if items.count == 1 {
					VStack {
						
						Button {
							Task {
								await tutorMgmtVM.assignService(serviceIndex: items, tutorNum: tutorNum, referenceData: referenceData)
							}
						} label: {
							Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
						}
					}
					
				} else {
					Button {
						Task {
							await tutorMgmtVM.assignService(serviceIndex: items, tutorNum: tutorNum, referenceData: referenceData)
						}
					} label: {
						Label("Assign Services to Tutor", systemImage: "square.and.arrow.up")
					}
				}
				
			} primaryAction: { items in
				//              store.favourite(items)
			}
		}
	}
}


struct StudentsView: View {
	var referenceData: ReferenceData
	var studentArray = [Student]()
    
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    
	@State private var selectedStudents: Set<Student.ID> = []
	@State private var sortOrder = [KeyPathComparator(\Student.studentName)]
	@State private var showAlert = false

	@State private var assignTutor = false
	@State private var unassignTutor = false
	@State private var editStudent = false
	@State private var showDeleted = false
	@State private var showUnassigned = false
    
	@State private var studentNumber: Int = 0
    
	var body: some View {
		if referenceData.students.isStudentDataLoaded {
			
			var studentArray: [Student] {
				if showDeleted {
					return referenceData.students.studentsList
				} else if showUnassigned {
					return referenceData.students.studentsList.filter{$0.studentStatus == "Unassigned"}
				} else {
					return referenceData.students.studentsList.filter{$0.studentStatus != "Deleted"}
				}
			}
			
			VStack {
				
				HStack {
					Toggle("Show Deleted", isOn: $showDeleted)
					Toggle("Show Unassigned", isOn: $showUnassigned)
					Text("     Student Count: ")
					Text(String(studentArray.count))
				}
				
				Table(studentArray, selection: $selectedStudents) {
					//               Group {
					TableColumn("Student Name", value: \Student.studentName)
						.width(min: 90, ideal: 149, max: 260)
					
					TableColumn("Guardian", value: \Student.studentGuardian)
						.width(min: 90, ideal: 140, max: 260)
					
					TableColumn("Phone", value: \Student.studentPhone)
						.width(min: 100, ideal: 120, max: 120)
					
					TableColumn("EMail", value: \Student.studentEmail)
						.width(min: 100, ideal: 120, max: 200)
					
					TableColumn("Student\nType") {data in
						Text(data.studentType.rawValue)
					}
					.width(min: 50, ideal: 70, max: 90)
					//             }
					//           Group {
					TableColumn("Start Date", value: \Student.studentStartDate)
						.width(min: 80, ideal: 90, max: 90)
					
					TableColumn("End Date", value: \Student.studentEndDate)
						.width(min: 80, ideal: 90, max: 90)
					
					TableColumn("Status", value: \Student.studentStatus)
						.width(min: 70, ideal: 80, max: 90)
					
					TableColumn("Tutor Name",value: \Student.studentTutorName)
						.width(min: 100, ideal: 150, max: 240)
					
					TableColumn("Location", value: \Student.studentLocation)
						.width(min: 80, ideal: 1200, max: 160)
	//                  }
	//                  TableColumn("Location", value: \.studentLocation)
	//                  TableColumn("Sessions", value: \.studentSessions) {data in
	//                  Text("\(data.studentTotalSessions)")
	//                  }
	//                  TableColumn("Total Cost", value: \.studentTotalCost)
	//                  TableColumn("Total Revenue", value: \.studentTotalRevenue)
	//                  TableColumn("Total Profit", value: \.studentTotalProfit)
	//                  }
				}
				//                .width(min: 600, ideal: 800)
				.contextMenu(forSelectionType: Student.ID.self) { items in
					if items.isEmpty {
						Button { } label: {
							Label("New Student", systemImage: "plus")
						}
					} else if items.count == 1 {
						VStack {
							
							Button {
								for objectID in items {
									if let idx = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
										studentNumber = idx
										assignTutor.toggle()
									}
								}
							} label: {
								Label("Assign Tutor to Student", systemImage: "square.and.arrow.up")
							}
							
							Button {
								Task {
									let (unassignResult, unassignMessage) = await studentMgmtVM.unassignStudent(studentIndex: items, referenceData: referenceData)
									if !unassignResult {
										showAlert = true
										buttonErrorMsg = unassignMessage
									}
								}
							} label: {
								Label("Unassign Student", systemImage: "square.and.arrow.up")
							}
							
							Button {
								Task {
									for objectID in items {
										if let idx = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
											studentNumber = idx
											editStudent.toggle()
										}
									}
								}
							} label: {
								Label("Edit Student", systemImage: "square.and.arrow.up")
							}
							
							Button {
								
							} label: {
								Label("ReAssign Student", systemImage: "square.and.arrow.up")
							}
							
							Button(role: .destructive) {
								Task {
									let (suspendResult, suspendMessage) = await studentMgmtVM.suspendStudent(studentIndex: items, referenceData: referenceData)
									if suspendResult == false {
										showAlert = true
										buttonErrorMsg = suspendMessage
									}
								}
							} label: {
								Label("Suspend Student", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) { }
							}
							
							Button(role: .destructive) {
								Task {
									let (unsuspendResult, unsuspendMessage) = await studentMgmtVM.unsuspendStudent(studentIndex: items, referenceData: referenceData)
									if unsuspendResult == false {
										showAlert = true
										buttonErrorMsg = unsuspendMessage
									}
								}
							} label: {
								Label("UnSuspend Student", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) { }
							}
							
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await studentMgmtVM.deleteStudent(indexes: items, referenceData: referenceData)
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Delete Student", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) { }
							}
							
							Button(role: .destructive) {
								Task {
									let (unDeleteResult, unDeleteMessage) = await studentMgmtVM.undeleteStudent(indexes: items, referenceData: referenceData)
									if unDeleteResult == false {
										showAlert = true
										buttonErrorMsg = unDeleteMessage
									}
								}
							} label: {
								Label("UnDelete Student", systemImage: "trash")
							}
							.alert(buttonErrorMsg, isPresented: $showAlert) {
								Button("OK", role: .cancel) { }
							}
						}
						
					} else {
						
						Button(role: .destructive) {
							Task {
								let (deleteResult, deleteMessage) = await studentMgmtVM.deleteStudent(indexes: items, referenceData: referenceData)
								if deleteResult == false {
									showAlert = true
									buttonErrorMsg = deleteMessage
								}
							}
						} label: {
							Label("Delete Multiple Students", systemImage: "trash")
						}
						.alert(buttonErrorMsg, isPresented: $showAlert) {
							Button("OK", role: .cancel) { }
						}
						
						Button {
							Task {
								let (unassignResult, unassignMessage) = await studentMgmtVM.unassignStudent(studentIndex: items, referenceData: referenceData)
								if !unassignResult {
									showAlert = true
									buttonErrorMsg = unassignMessage
								}
							}
						} label: {
							Label("Unassign Multiple Students", systemImage: "square.and.arrow.up")
						}
						.alert(buttonErrorMsg, isPresented: $showAlert) {
							Button("OK", role: .cancel) { }
						}
						
						Button {
							Task {
								let (suspendResult, suspendMessage) = await studentMgmtVM.suspendStudent(studentIndex: items, referenceData: referenceData)
								if suspendResult == false {
									showAlert = true
									buttonErrorMsg = suspendMessage
								}
							}
						} label: {
							Label("Suspend Multiple Students", systemImage: "square.and.arrow.up")
						}
						.alert(buttonErrorMsg, isPresented: $showAlert) {
							Button("OK", role: .cancel) { }
						}
						
						Button {
							Task {
								let (unsuspendResult, unsuspendMessage) = await studentMgmtVM.unsuspendStudent(studentIndex: items, referenceData: referenceData)
								if unsuspendResult == false {
									showAlert = true
									buttonErrorMsg = unsuspendMessage
								}
							}
						} label: {
							Label("UnSuspend Multiple Students", systemImage: "square.and.arrow.up")
						}
						.alert(buttonErrorMsg, isPresented: $showAlert) {
							Button("OK", role: .cancel) { }
						}
					}
				} primaryAction: { items in
					//              store.favourite(items)
				}
				
			}
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
			
			.navigationDestination(isPresented: $assignTutor) {
				TutorSelectionView(studentNum: $studentNumber, referenceData: referenceData)
			}
			.navigationDestination(isPresented: $editStudent) {
				StudentView(updateStudentFlag: true, originalStudentName: referenceData.students.studentsList[studentNumber].studentName, referenceData: referenceData, studentKey: referenceData.students.studentsList[studentNumber].studentKey, studentName: referenceData.students.studentsList[studentNumber].studentName, guardianName: referenceData.students.studentsList[studentNumber].studentGuardian, contactPhone: referenceData.students.studentsList[studentNumber].studentPhone, contactEmail: referenceData.students.studentsList[studentNumber].studentEmail, location: referenceData.students.studentsList[studentNumber].studentLocation,
					    studentType: referenceData.students.studentsList[studentNumber].studentType )
			}
		}
	}
}

struct TutorSelectionView: View {
	@Binding var studentNum: Int
	var referenceData: ReferenceData

	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    
	@State private var selectedTutor: Tutor.ID?
	@State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
	@State private var showAlert = false
	@State private var viewChange: Bool = false

	var body: some View {
		
		var activeTutors: [Tutor] {
				return referenceData.tutors.tutorsList.filter{$0.tutorStatus != "Deleted" && $0.tutorStatus != "Suspended"}
			}
			
		VStack {
			Table(activeTutors, selection: $selectedTutor, sortOrder: $sortOrder) {
				
				TableColumn("Tutor Name", value: \.tutorName)
				TableColumn("Tutor Status", value: \.tutorStatus)
			}
			
			.contextMenu(forSelectionType: Tutor.ID.self) {items in
//				if items.count == 1 {
					VStack {
						
						Button {
							Task {
//								if let items = items {
									let (assignResult, assignMessage) = await studentMgmtVM.assignStudent(studentNum: studentNum, tutorIndex: items, referenceData: referenceData)
									if !assignResult {
										showAlert = true
										buttonErrorMsg = assignMessage
									}
//								}
							}
						} label: {
							Label("Assign Tutor to Student", systemImage: "square.and.arrow.up")
						}
						.alert(buttonErrorMsg, isPresented: $showAlert) {
							Button("OK", role: .cancel) { }
						}
					}
					
//				}
				
			} primaryAction: { items in
				//              store.favourite(items)
			}
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
		}
	}
}

struct ServicesView: View {
	var referenceData: ReferenceData
	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	
	@State private var selectedServices = Set<Service.ID>()
	@State private var sortOrder = [KeyPathComparator(\Service.serviceTimesheetName)]
	
	@State private var assignService: Bool = false
	@State private var editService: Bool = false
	@State private var listServiceCosts: Bool = false
	@State private var showDeleted: Bool = false
	@State private var showUnassigned: Bool = false
	@State private var showAlert: Bool = false
	
	@State private var serviceNumber: Int = 0
	@State private var serviceCostList = TutorServiceCostList()
	
	
	var body: some View {
		if referenceData.services.isServiceDataLoaded {
			
			var serviceArray: [Service] {
				if showDeleted {
					return referenceData.services.servicesList
				} else if showUnassigned {
					return referenceData.services.servicesList.filter{$0.serviceStatus == "Unassigned"}
				} else {
					return referenceData.services.servicesList.filter{$0.serviceStatus != "Deleted"}
				}
			}
			
			VStack {
				HStack {
					Toggle("Show Deleted", isOn: $showDeleted)
					Toggle("Show Unassigned", isOn: $showUnassigned)
					Text("     Service Count: ")
					Text(String(serviceArray.count))
				}
				
				Table(serviceArray, selection: $selectedServices, sortOrder: $sortOrder) {
					//               Group {
					TableColumn("Timesheet Name", value: \Service.serviceTimesheetName)
						.width(min: 120, ideal: 150, max: 240)
					
					TableColumn("Invoice Name", value: \Service.serviceInvoiceName)
						.width(min: 120, ideal: 150, max: 240)
					
					TableColumn("Service\nType") {data in
						Text(data.serviceType.rawValue)
					}
					.width(min: 50, ideal: 70, max: 80)
					
					TableColumn("Billing\nType") {data in
						Text(data.serviceBillingType.rawValue)
					}
					.width(min: 50, ideal: 70, max: 80)
					
					TableColumn("Service\nStatus", value: \Service.serviceStatus)
						.width(min: 50, ideal: 70, max: 80)
					
					TableColumn("Assigned\nTutors" ) { data in
						Text(String(data.serviceCount))
					}
					.width(min: 40, ideal: 60, max: 70)
					
					TableColumn("Cost 1") { data in
						Text(String(data.serviceCost1.formatted(.number.precision(.fractionLength(2)))))
					}
					.width(min: 40, ideal: 50, max: 50)
					
					TableColumn("Cost 2", value: \Service.serviceCost2) { data in
						Text(String(data.serviceCost2.formatted(.number.precision(.fractionLength(2)))))
					}
					.width(min: 40, ideal: 50, max: 50)
					
					TableColumn("Cost 3", value: \Service.serviceCost3) { data in
						Text(String(data.serviceCost3.formatted(.number.precision(.fractionLength(2)))))
					}
					.width(min: 40, ideal: 50, max: 50)
					
					TableColumn("Price 1", value: \Service.servicePrice1) { data in
						Text(String(data.servicePrice1.formatted(.number.precision(.fractionLength(2)))))
					}
					.width(min: 40, ideal: 50, max: 50)
					
		//                    TableColumn("Price 2", value: \Service.servicePrice2) { data in
		//                        Text(String(data.servicePrice2.formatted(.number.precision(.fractionLength(2)))))
		//                    }
		//                   TableColumn("Price 3", value: \Service.servicePrice3) { data in
		//                       Text(String(data.servicePrice3.formatted(.number.precision(.fractionLength(2)))))
		//                   }
		//               }
					
				}
				.contextMenu(forSelectionType: Service.ID.self) { items in
					if items.isEmpty {
						Button {
							//                     AddService(referenceData: referenceData, timesheetName: " ", invoiceName: " ", serviceType: " ", billingType: " ")
						} label: {
							Label("New Service", systemImage: "plus")
						}
					} else if items.count == 1 {
						VStack {
							Button {
								for objectID in items {
									if let idx = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
										serviceNumber = idx
										assignService.toggle()
									}
								}
							} label: {
								Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
							}
							
							Button {
								for objectID in items {
									if let idx = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
										serviceNumber = idx
										editService.toggle()
									}
								}
							} label: {
								Label("Edit Service", systemImage: "square.and.arrow.up")
							}
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await serviceMgmtVM.deleteService(indexes: items, referenceData: referenceData)
									
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Delete Service", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								Task {
									let (unDeleteResult, unDeleteMessage) = await serviceMgmtVM.unDeleteService(indexes: items, referenceData: referenceData)
									if unDeleteResult == false {
										showAlert = true
										buttonErrorMsg = unDeleteMessage
									}
								}
							} label: {
								Label("Undelete Service", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								for objectID in items {
									if let idx = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
										serviceNumber = idx
										listServiceCosts.toggle()
										serviceCostList = tutorMgmtVM.buildServiceCostArray(serviceNum: serviceNumber, referenceData: referenceData)
									}
								}
							} label: {
								Label("List Individual Tutor Costs", systemImage: "trash")
							}
						}
						
					} else {
						Button {
							
						} label: {
							Label("Edit Services", systemImage: "heart")
						}
						Button(role: .destructive) {
							
						} label: {
							Label("Delete Selected", systemImage: "trash")
						}
					}
					
				} primaryAction: { items in
					//              store.favourite(items)
				}
				.alert(buttonErrorMsg, isPresented: $showAlert) {
					Button("OK", role: .cancel) { }
				}
				
				.navigationDestination(isPresented: $assignService) {
					TutorServiceSelectionView(serviceNum: $serviceNumber, referenceData: referenceData)
				}
				.navigationDestination(isPresented: $editService) {
					if referenceData.services.servicesList.count > 0 {
						ServiceView(updateServiceFlag: true, serviceNum: serviceNumber, originalTimesheetName: referenceData.services.servicesList[serviceNumber].serviceTimesheetName, referenceData: referenceData, serviceKey: referenceData.services.servicesList[serviceNumber].serviceKey, timesheetName: referenceData.services.servicesList[serviceNumber].serviceTimesheetName,  invoiceName:  referenceData.services.servicesList[serviceNumber].serviceInvoiceName, serviceType:  referenceData.services.servicesList[serviceNumber].serviceType, billingType:  referenceData.services.servicesList[serviceNumber].serviceBillingType, serviceCount:  referenceData.services.servicesList[serviceNumber].serviceCount, cost1:  referenceData.services.servicesList[serviceNumber].serviceCost1, cost2: referenceData.services.servicesList[serviceNumber].serviceCost2, cost3: referenceData.services.servicesList[serviceNumber].serviceCost3, price1: referenceData.services.servicesList[serviceNumber].servicePrice1, price2: referenceData.services.servicesList[serviceNumber].servicePrice2, price3: referenceData.services.servicesList[serviceNumber].servicePrice3)
					}
				}
				.navigationDestination(isPresented: $listServiceCosts) {
					if $serviceCostList.tutorServiceCostList.count > 0 {
						TutorServiceCostView(serviceNum: $serviceNumber, serviceCostList: $serviceCostList, referenceData: referenceData)
					}
				}
			}
		}
	}
}

struct TutorServiceSelectionView: View {
	@Binding var serviceNum: Int
	var referenceData: ReferenceData
	
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	
	@State private var selectedTutor = Set<Tutor.ID>()
	@State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
	@State private var showAlert = false
	@State private var viewChange: Bool = false
	
	var body: some View {
		
		VStack {
			Table(referenceData.tutors.tutorsList, selection: $selectedTutor, sortOrder: $sortOrder) {
				
				TableColumn("Tutor Name", value: \.tutorName)
				TableColumn("Tutor Status", value: \.tutorStatus)
			}
			
			.contextMenu(forSelectionType: Tutor.ID.self) { items in
				if items.count == 1 {
					VStack {
						Button {
							Task {
								await tutorMgmtVM.assignTutorService(serviceNum: serviceNum, tutorIndex: items, referenceData: referenceData)
							}
							
						} label: {
							Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
						}
					}
					
					
				} else {
					Button {
						Task {
							await tutorMgmtVM.assignTutorService(serviceNum: serviceNum, tutorIndex: items, referenceData: referenceData)
						}
					} label: {
						Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
					}
				}
				
			} primaryAction: { items in
				//              store.favourite(items)
			}
			
		}
	}
}

struct LocationsView: View {
	var referenceData: ReferenceData
	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(LocationMgmtVM.self) var locationMgmtVM: LocationMgmtVM
	@State private var selectedLocations = Set<Location.ID>()
	@State private var sortOrder = [KeyPathComparator(\Location.locationName)]
	@State private var listStudents: Bool = false
	@State private var editLocation: Bool = false
	@State private var locationNumber: Int = 0
	@State private var showDeleted: Bool = false
	@State private var showAlert: Bool = false
	
	var body: some View {
		if referenceData.locations.isLocationDataLoaded {
			
			var locationArray: [Location] {
				if showDeleted {
					return referenceData.locations.locationsList
				} else {
					return referenceData.locations.locationsList.filter{$0.locationStatus != "Deleted"}
				}
			}
			
			VStack {
				Toggle("Show Deleted", isOn: $showDeleted)
				
				Table(locationArray, selection: $selectedLocations, sortOrder: $sortOrder) {
					TableColumn("Location Name", value: \.locationName)
						.width(min: 60, ideal: 80, max: 120)
					
					TableColumn("Student\nCount", value: \.locationStudentCount) {data in
						Text(String(data.locationStudentCount))
							.frame(alignment: .center)
					}
					.width(min: 30, ideal: 60, max: 120)
					
					TableColumn("Location\nMonth Revenue", value: \Location.locationMonthRevenue) { data in
						Text(String(data.locationMonthRevenue.formatted(.number.precision(.fractionLength(2)))))
							.frame(alignment: .center)
					}
					.width(min: 30, ideal: 60, max: 120)
					
					TableColumn("Location\nTotal Revenue", value: \Location.locationTotalRevenue) { data in
						Text(String(data.locationTotalRevenue.formatted(.number.precision(.fractionLength(2)))))
							.frame(alignment: .center)
					}
					.width(min: 30, ideal: 60, max: 120)
					
					TableColumn("Location\nStatus", value: \.locationStatus)
						.width(min: 50, ideal: 70, max: 80)
				}
				.contextMenu(forSelectionType: Location.ID.self) { items in
					if items.isEmpty {
						Button {
							//                       let result = AddLocation(referenceData: referenceData, locationName: " ", locationMonthRevenue: 0.0, locationTotalRevenue: 0.0)
						} label: {
							Label("New Service", systemImage: "plus")
						}
					} else if items.count == 1 {
						VStack {
							Button {
								Task {
									for objectID in items {
										if let idx = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
											locationNumber = idx
											editLocation.toggle()
										}
									}
								}
							} label: {
								Label("Edit Location", systemImage: "square.and.arrow.up")
							}
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await locationMgmtVM.deleteLocation(indexes: items, referenceData: referenceData)
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Delete Location", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								Task {
									let (unDeleteResult, unDeleteMessage) = await locationMgmtVM.undeleteLocation(indexes: items, referenceData: referenceData)
									if unDeleteResult == false {
										showAlert = true
										buttonErrorMsg = unDeleteMessage
									}
								}
							} label: {
								Label("Undelete Location", systemImage: "trash")
							}
						}
						
					} else {
						VStack {
							Button {
								
							} label: {
								Label("Edit Locations", systemImage: "heart")
							}
							Button(role: .destructive) {
								
							} label: {
								Label("Delete Selected Locations", systemImage: "trash")
							}
						}
					}
					
				} primaryAction: { items in
					//              store.favourite(items)
				}
				.alert(buttonErrorMsg, isPresented: $showAlert) {
					Button("OK", role: .cancel) { }
				}
				
				.navigationDestination(isPresented: $editLocation) {
					LocationView(updateLocationFlag: true, locationNum: locationNumber, originalLocationName: referenceData.locations.locationsList[locationNumber].locationName, referenceData: referenceData, locationName: referenceData.locations.locationsList[locationNumber].locationName )
				}
			}
		}
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
