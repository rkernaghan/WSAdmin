//
//  TutorSelectionView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-04.
//
import SwiftUI

struct TutorSelectionView: View {
	@Binding var studentNum: Int
	var referenceData: ReferenceData
	
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
	@Environment(\.dismiss) var dismiss
	
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
					.width(min: 120, ideal: 140, max: 180)
				TableColumn("Tutor Status", value: \.tutorStatus)
					.width(min: 100, ideal: 120, max: 200)
			}
			
			.contextMenu(forSelectionType: Tutor.ID.self) {items in
				//				if items.count == 1 {
				VStack {
					
					Button {
						Task {
							
							let (assignResult, assignMessage) = await studentMgmtVM.assignStudent(studentNum: studentNum, tutorIndex: items, referenceData: referenceData)
							if !assignResult {
								showAlert = true
								buttonErrorMsg = assignMessage
							}
							dismiss()
							
						}
					} label: {
						Label("Assign Tutor to \(referenceData.students.studentsList[studentNum].studentName)", systemImage: "square.and.arrow.up")
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


