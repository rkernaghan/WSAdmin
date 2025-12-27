//
//  StudentSelectionView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-04.
//
import SwiftUI

struct StudentSelectionView: View {
	@Binding var tutorNum: Int
	var referenceData: ReferenceData
	
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	@State private var selectedStudents = Set<Student.ID>()
	@State private var sortOrder = [KeyPathComparator(\Student.studentName)]
	@State private var showAlert = false
	@State private var viewChange: Bool = false
	
	var body: some View {
		
		//        for objectID in tutorIndex {
		//            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == tutorIndex} ) {
		VStack {
			Table(referenceData.students.studentsList.filter{$0.studentStatus == "Unassigned"}, selection: $selectedStudents, sortOrder: $sortOrder) {
				
				TableColumn("Student Name", value: \.studentName)
					.width(min: 140, ideal: 180, max: 220)
				TableColumn("Contact First Name", value: \.studentContactFirstName)
					.width(min: 140, ideal: 180, max: 220)
				TableColumn("Contact Last Name", value: \.studentContactLastName)
					.width(min: 140, ideal: 180, max: 220)
				TableColumn("Status", value: \.studentStatus)
					.width(min: 100, ideal: 120, max: 140)
			}
			
			.contextMenu(forSelectionType: Tutor.ID.self) { items in
				if items.count == 1 {
					VStack {
						
						Button {
							Task {
								let (assignResult, assignMessage) = await tutorMgmtVM.assignStudent(studentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
								if !assignResult {
									showAlert = true
									buttonErrorMsg = assignMessage
								} else {
									dismiss()
								}
							}
						} label: {
							Label("Assign Student to \(referenceData.tutors.tutorsList[tutorNum].tutorName)", systemImage: "square.and.arrow.up")
						}
					}
					
				} else {
					Button {
						Task {
							let (assignResult, assignMessage) = await tutorMgmtVM.assignStudent(studentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
							if !assignResult {
								showAlert = true
								buttonErrorMsg = assignMessage
							} else {
								dismiss()
							}
						}
					} label: {
						Label("Assign Students to \(referenceData.tutors.tutorsList[tutorNum].tutorName)", systemImage: "square.and.arrow.up")
					}
				}
				
			} primaryAction: { items in
				//              store.favourite(items)
			}
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
		
	}
}

