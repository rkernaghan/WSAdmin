//
//  AddTutor.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//
import Foundation
import SwiftUI

struct TutorView: View {
	var updateTutorFlag: Bool
	var tutorNum: Int
	var originalTutorName: String
	var referenceData: ReferenceData
	
	@State var tutorName: String
	@State var tutorEmail: String
	@State var tutorPhone: String
	@State var maxStudents: Int
	
	@State private var showAlert = false
	@State private var dismissAlert = false
	
	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		
		VStack(alignment: .leading) {
			HStack {
				Text("Tutor Name")
				TextField("Tutor Name", text: $tutorName)
					.frame(width: 200)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Max Students")
				TextField("Max Students", value: $maxStudents, format: .number)
					.frame(width: 45)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Tutor Email")
				TextField("Contact EMail", text: $tutorEmail)
					.frame(width: 300)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Tutor Phone")
				TextField("Contact Phone", text: $tutorPhone)
					.frame(width: 120)
					.textFieldStyle(.roundedBorder)
			}
			
			Button(action: {
				Task {
					let tutorName = tutorName.trimmingCharacters(in: .whitespaces)
					let contactEmail = tutorEmail.trimmingCharacters(in: .whitespaces)
					let contactPhone = tutorPhone.trimmingCharacters(in: .whitespaces)
					// Update an existing Tutor
					if updateTutorFlag {
						let (tutorValidationResult, validationMessage) = tutorMgmtVM.validateUpdatedTutor(originalTutorName: originalTutorName, tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorMaxStudents: maxStudents, referenceData: referenceData)
						if tutorValidationResult {
							let (updateResult, updateMessage) = await tutorMgmtVM.updateTutor(tutorNum: tutorNum, referenceData: referenceData, tutorName: tutorName, originalTutorName: originalTutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
							if !updateResult {
								buttonErrorMsg = updateMessage
								showAlert = true
							} else {
								dismiss()
							}
						} else {
							buttonErrorMsg = validationMessage
							showAlert = true
						}
					} else {
						// Add a new Tutor
						let (tutorValidationResult, validationMessage) = tutorMgmtVM.validateNewTutor(tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorMaxStudents: maxStudents, referenceData: referenceData)
						if tutorValidationResult {
							let (addResult, addMessage) = await tutorMgmtVM.addNewTutor(referenceData: referenceData, tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, maxStudents: maxStudents)
							if !addResult {
								buttonErrorMsg = addMessage
								showAlert = true
							} else {
								showAlert = true
								buttonErrorMsg = "You must Allow Access in 2 cells in RefData tab of new Timesheet for \(tutorName)"
								dismissAlert = true
							}
						} else {
							buttonErrorMsg = validationMessage
							showAlert = true
						}
					}
				}
				
			}){
				if updateTutorFlag {
					Text("Update Tutor \(originalTutorName)")
				} else {
					Text("Add New Tutor")
				}
			}
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) {
					if dismissAlert {
						dismiss()
					}
				}
			}
			.padding()
//			.clipShape(RoundedRectangle(cornerRadius: 10))
			
			Spacer()
		}
	}
}

//#Preview {
//    AddStudent()
//}
