//
//  StudentsView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-03.
//
import SwiftUI

struct StudentListView: View {
	var referenceData: ReferenceData
	var studentArray = [Student]()
	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
	
	@State private var selectedStudents: Set<Student.ID> = []
	@State private var sortOrder = [KeyPathComparator(\Student.studentName)]
	@State private var showAlert = false
	
	@State private var assignTutor: Bool = false
	@State private var unassignTutor: Bool = false
	@State private var editStudent: Bool = false
	@State private var reassignStudent: Bool = false
	@State private var showDeleted: Bool = true
	@State private var showUnassigned: Bool = true
	@State private var showAssigned: Bool = true
	@State private var showSuspended: Bool = true
	
	@State private var emptyArray = [Student]()
	@State private var studentNumber: Int = 0
	
	@State private var buttonErrorMsg: String = ""
	
	var body: some View {
		if referenceData.students.isStudentDataLoaded {

			var deletedArray: [Student] {
				if showDeleted  {
					return referenceData.students.studentsList.filter{$0.studentStatus == .StudentDeleted}
				} else {
					return emptyArray
				}
			}
			var unassignedArray: [Student] {
				if showUnassigned {
					return referenceData.students.studentsList.filter{$0.studentStatus == .StudentUnassigned}
				} else {
					return emptyArray
				}
			}
			var suspendedArray: [Student] {
				if showSuspended  {
					return referenceData.students.studentsList.filter{$0.studentStatus == .StudentSuspended}
				} else {
					return emptyArray
				}
			}
			var assignedArray: [Student] {
				if showAssigned {
					return referenceData.students.studentsList.filter{$0.studentStatus == .StudentAssigned}
				} else {
					return emptyArray
				}
			}
			
			let studentArray: [Student] = assignedArray + unassignedArray + suspendedArray + deletedArray
			
			VStack {
				
				HStack {
					Toggle("Show Assigned", isOn: $showAssigned)
					Toggle("Show Unassigned", isOn: $showUnassigned)
					Toggle("Show Suspended", isOn: $showSuspended)
					Toggle("Show Deleted", isOn: $showDeleted)
					Text("     Student Count: ")
					Text(String(studentArray.count))
				}
				
				Table(studentArray, selection: $selectedStudents) {
					Group {
						TableColumn("Student Name", value: \Student.studentName)
							.width(min: 90, ideal: 160, max: 260)
						
						TableColumn("Contact\nFirst Name", value: \Student.studentContactFirstName)
							.width(min: 30, ideal: 40, max: 260)
						
						TableColumn("Contact\nLast Name", value: \Student.studentContactLastName)
							.width(min: 30, ideal: 70, max: 260)
												
						TableColumn("Student\nStatus") { (data: Student) in
							Text( String(describing: data.studentStatus.rawValue))
						}
						.width(min: 50, ideal: 75, max: 90)
						
						TableColumn("Tutor Name",value: \Student.studentTutorName)
							.width(min: 80, ideal: 120, max: 180)
					}
					
					Group {
//						TableColumn("Phone", value: \Student.studentContactPhone)
//							.width(min: 90, ideal: 100, max: 110)
						
//						TableColumn("EMail", value: \Student.studentContactEmail)
//							.width(min: 60, ideal: 100, max: 200)
						
//						TableColumn("Zip Code", value: \Student.studentContactZipCode)
//							.width(min: 40, ideal: 50, max: 90)
					}
					             
					Group {
						TableColumn("Start Date", value: \Student.studentStartDate)
							.width(min: 60, ideal: 75, max: 90)
						
						TableColumn("Assigned\nUnassigned\nDate", value: \Student.studentAssignedUnassignedDate)
							.width(min: 60, ideal: 75, max: 90)
						
						TableColumn("Last Billed\nDate", value: \Student.studentLastBilledDate)
							.width(min: 60, ideal: 75, max: 90)
						
						TableColumn("End Date", value: \Student.studentEndDate)
							.width(min: 60, ideal: 70, max: 90)
					}
					Group {
						
						
//						TableColumn("Location", value: \Student.studentLocation)
//							.width(min: 70, ideal: 80, max: 140)
						
						TableColumn("Total\nSessions") {data in
							Text(String(data.studentSessions))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 60)
						
//						TableColumn("Total Cost") {data in
//							Text(String(data.studentTotalCost.formatted(.number.precision(.fractionLength(0)))))
//								.frame(maxWidth: .infinity, alignment: .center)
//						}
//						.width(min: 60, ideal: 80, max: 90)
//					}
//					Group {
//
//						TableColumn("Total Revenue") {data in
//							Text(String(data.studentTotalRevenue.formatted(.number.precision(.fractionLength(0)))))
//								.frame(maxWidth: .infinity, alignment: .center)
//						}
//						.width(min: 60, ideal: 80, max: 90)
						
						TableColumn("Total\nProfit") { data in
							let profit = data.studentTotalProfit.formatted(.number.precision(.fractionLength(0)))
							Text(String(profit))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 60)

					}
				}
				.frame(minWidth: 600, idealWidth: 1200)
				.contextMenu(forSelectionType: Student.ID.self) { items in
					if items.isEmpty {
						Button { } label: {
							Label("New Student", systemImage: "plus")
						}
					} else if items.count == 1 {
						VStack {
							
							Button {
								Task {
									await handleAssignTutor(items: items)
								}
							} label: {
								Label("Assign Tutor to Student", systemImage: "square.and.arrow.up")
							}
							
							Button {
								Task {
									await handleUnassignStudent(items: items)
								}
							} label: {
								Label("Unassign Student", systemImage: "square.and.arrow.up")
							}
							
							Button {
								Task {
									await handleEditStudent(items: items)
								}
							} label: {
								Label("Edit Student", systemImage: "square.and.arrow.up")
							}
							
							Button {
								Task {
									await handleReassignStudent(items: items)
								}
							} label: {
								Label("ReAssign Student", systemImage: "square.and.arrow.up")
							}
							
							Button(role: .destructive) {
								Task {
									await handleSuspendStudent(items: items)
								}
							} label: {
								Label("Suspend Student", systemImage: "trash")
							}
//							.alert(buttonErrorMsg, isPresented: $showAlert) {
//								Button("OK", role: .cancel) { }
//							}
							
							Button(role: .destructive) {
								Task {
									await handleUnsuspendStudent(items: items)
								}
							} label: {
								Label("UnSuspend Student", systemImage: "trash")
							}
//							.alert(buttonErrorMsg, isPresented: $showAlert) {
//								Button("OK", role: .cancel) { }
//							}
							
							
							Button(role: .destructive) {
								Task {
									await handleDeleteStudent(items: items)
								}
							} label: {
								Label("Delete Student", systemImage: "trash")
							}
//							.alert(buttonErrorMsg, isPresented: $showAlert) {
//								Button("OK", role: .cancel) { }
//							}
							
//							Button(role: .destructive) {
//								Task {
//									let (unDeleteResult, unDeleteMessage) = await studentMgmtVM.undeleteStudent(indexes: items, referenceData: referenceData)
//									if unDeleteResult == false {
//										showAlert = true
//										buttonErrorMsg = unDeleteMessage
//									}
//								}
//							} label: {
//								Label("UnDelete Student", systemImage: "trash")
//							}
//							.alert(buttonErrorMsg, isPresented: $showAlert) {
//								Button("OK", role: .cancel) { }
//							}
						}
						
					} else {
						
						deleteMultipleAlertButton(items: items)
						
						unassignMultipleAlertButton(items: items)
						
						suspendMultipleAlertButton(items: items)
						
						unsuspendMultipleAlertButton(items: items)
					}
				} primaryAction: { items in
					//              store.favourite(items)
				}
				
			}
			.navigationTitle("Students List")
			
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
			
			.navigationDestination(isPresented: $assignTutor) {
				TutorSelectionView(studentNum: $studentNumber, referenceData: referenceData)
			}
			
			.navigationDestination(isPresented: $reassignStudent) {
				TutorSelectionView(studentNum: $studentNumber, referenceData: referenceData)
			}
			
			.navigationDestination(isPresented: $editStudent) {
				let student = referenceData.students.studentsList[studentNumber]
				StudentView(updateStudentFlag: true, originalStudentName: student.studentName, referenceData: referenceData, studentKey: student.studentKey, studentName: student.studentName, contactFirstName: student.studentContactFirstName, contactLastName: student.studentContactLastName, contactPhone: student.studentContactPhone, contactAddress1: student.studentContactAddress1, contactAddress2: student.studentContactAddress2, contactCity: student.studentContactCity, contactState: student.studentContactState,  contactZipCode: student.contactZipCode, contactEmail: student.studentContactEmail, location: student.studentLocation)
			}
		}
	}
	
	// MARK: - Helper extracted buttons for multiple selection alert buttons
	
	@ViewBuilder
	private func deleteMultipleAlertButton(items: Set<Student.ID>) -> some View {
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
	}
	
	@ViewBuilder
	private func unassignMultipleAlertButton(items: Set<Student.ID>) -> some View {
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
	}
	
	@ViewBuilder
	private func suspendMultipleAlertButton(items: Set<Student.ID>) -> some View {
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
	}
	
	@ViewBuilder
	private func unsuspendMultipleAlertButton(items: Set<Student.ID>) -> some View {
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
	
	// MARK: - Helper async functions for context menu single item buttons
	
	private func handleAssignTutor(items: Set<Student.ID>) async {
		for objectID in items {
			if let idx = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				studentNumber = idx
				assignTutor.toggle()
			}
		}
	}
	
	private func handleUnassignStudent(items: Set<Student.ID>) async {
		let (unassignResult, unassignMessage) = await studentMgmtVM.unassignStudent(studentIndex: items, referenceData: referenceData)
		if !unassignResult {
			showAlert = true
			buttonErrorMsg = unassignMessage
		}
	}
	
	private func handleEditStudent(items: Set<Student.ID>) async {
		for objectID in items {
			if let idx = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
				studentNumber = idx
				editStudent.toggle()
			}
		}
	}
	
	private func handleReassignStudent(items: Set<Student.ID>) async {
		guard let objectID = items.first,
			  let idx = referenceData.students.studentsList.firstIndex(where: { $0.id == objectID }) else { return }
		studentNumber = idx
		reassignStudent.toggle()
	}
	
	private func handleSuspendStudent(items: Set<Student.ID>) async {
		let (suspendResult, suspendMessage) = await studentMgmtVM.suspendStudent(studentIndex: items, referenceData: referenceData)
		if suspendResult == false {
			showAlert = true
			buttonErrorMsg = suspendMessage
		}
	}
	
	private func handleUnsuspendStudent(items: Set<Student.ID>) async {
		let (unsuspendResult, unsuspendMessage) = await studentMgmtVM.unsuspendStudent(studentIndex: items, referenceData: referenceData)
		if unsuspendResult == false {
			showAlert = true
			buttonErrorMsg = unsuspendMessage
		}
	}
	
	private func handleDeleteStudent(items: Set<Student.ID>) async {
		let (deleteResult, deleteMessage) = await studentMgmtVM.deleteStudent(indexes: items, referenceData: referenceData)
		if deleteResult == false {
			showAlert = true
			buttonErrorMsg = deleteMessage
		}
	}
}

