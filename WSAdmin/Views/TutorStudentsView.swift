//
//  TutorStudentsView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-21.
//

import SwiftUI

struct TutorStudentsView: View {
	@Binding var tutorNum: Int
	var referenceData: ReferenceData
    
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
	@Environment(\.dismiss) var dismiss
	
	@State private var selectedStudents: Set<Student.ID> = []
	@State private var showAlert: Bool = false
    
	var body: some View {
		VStack {
			Table(referenceData.tutors.tutorsList[tutorNum].tutorStudents, selection: $selectedStudents) {
				TableColumn("Student Name", value: \.studentName)
					.width(min:90, ideal: 120, max: 260)
				
				TableColumn("Client Name", value: \.clientName)
					.width(min: 90, ideal: 120, max: 260)
				
				TableColumn("Assigned Date", value: \.assignedDate)
					.width(min: 60, ideal: 75, max: 90)
				
				TableColumn("Last Billed Date", value: \.lastBilledDate)
					.width(min: 60, ideal: 75, max: 90)
				
				TableColumn("Phone", value: \.clientPhone)
					.width(min: 90, ideal: 110, max: 120)
				
				TableColumn("Email", value: \.clientEmail)
					.width(min: 60, ideal: 100, max: 200)
			}
			
			.contextMenu(forSelectionType: Student.ID.self) { items in
				if items.isEmpty {
					Button { } label: {
						Label("New Student", systemImage: "plus")
					}
				} else if items.count == 1 {
					VStack {
                        
						Button {
							Task {
								let (unassignResult, unassignMessage) = await studentMgmtVM.unassignTutorStudent(tutorStudentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
								if !unassignResult {
									showAlert = true
									buttonErrorMsg = unassignMessage
								} else {
									dismiss()
								}
							}
						} label: {
							Label("Unassign Student", systemImage: "square.and.arrow.up")
						}
					}
                    
				} else {
					Button {
						Task {
							let (unassignResult, unassignMessage) = await studentMgmtVM.unassignTutorStudent(tutorStudentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
							if !unassignResult {
								showAlert = true
								buttonErrorMsg = unassignMessage
							} else {
								dismiss()
							}
						}
					} label: {
						Label("Unassign Students", systemImage: "square.and.arrow.up")
					}
				}
			} primaryAction: { items in
				//              store.favourite(items)
			}
		}
		.navigationTitle("\(referenceData.tutors.tutorsList[tutorNum].tutorName) Tutor Students List")
		
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
	}
    
}

// #Preview {
//    TutorStudentsView()
// }
