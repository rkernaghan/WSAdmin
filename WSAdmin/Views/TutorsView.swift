//
//  TutorsView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-03.
//

import SwiftUI

struct TutorListView: View {
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
	@State private var showDeleted: Bool = true
	@State private var showSuspended: Bool = true
	
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
					Group {
						TableColumn("Tutor Name", value: \Tutor.tutorName)
							.width(min: 70, ideal: 100, max: 180)
						
						TableColumn("Status", value: \Tutor.tutorStatus)
							.width(min: 50, ideal: 70, max: 80)
						
						TableColumn("Student\nCount") {data in
							Text(String(data.tutorStudentCount))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
						
						TableColumn("Service\nCount") {data in
							Text(String(data.tutorServiceCount))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 50, ideal: 60, max: 60)

					}
					Group {
						TableColumn("Phone", value: \Tutor.tutorPhone)
							.width(min: 90, ideal: 100, max: 110)
						
						TableColumn("Email", value: \Tutor.tutorEmail)
							.width(min: 150, ideal: 180, max: 260)
						
						TableColumn("Start Date", value: \Tutor.tutorStartDate)
							.width(min: 60, ideal: 80, max: 80)
						
						TableColumn("End Date", value: \Tutor.tutorEndDate)
							.width(min: 60, ideal: 80, max: 80)
						
						TableColumn("Max\nStudents") { data in
							Text(String(data.tutorMaxStudents))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 50, ideal: 60, max: 60)
						
						TableColumn("Total Cost") {data in
							   Text(String(data.tutorTotalCost.formatted(.number.precision(.fractionLength(0)))))
							.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.width(min: 60, ideal: 80, max: 90)
						
						TableColumn("Total Revenue") {data in
							Text(String(data.tutorTotalRevenue.formatted(.number.precision(.fractionLength(0)))))
								.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.width(min: 60, ideal: 80, max: 90)
						
						TableColumn("Total Profit") { data in
							Text(String(data.tutorTotalProfit.formatted(.number.precision(.fractionLength(0)))))
								.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.width(min: 60, ideal: 80, max: 90)
					}
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
								for objectID in items {
									if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
										tutorNumber = idx
										editService.toggle()
									}
								}
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
			.navigationDestination(isPresented: $editService) {
//				EditStudentSelectionView(tutorNum: $tutorNumber, referenceData: referenceData)
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

