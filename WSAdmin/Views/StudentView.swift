//
//  AddStudent.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import SwiftUI

struct StudentView: View {
	
	var updateStudentFlag: Bool
	var originalStudentName: String
	var referenceData: ReferenceData
	var studentKey: String
	
	@State var studentName: String
	@State var contactFirstName: String
	@State var contactLastName: String
	@State var contactPhone: String
	@State var contactEmail: String
	@State var contactZipCode: String
	@State var location: String
	
	@State private var showAlert: Bool = false
	
	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		
		VStack(alignment: .leading) {
			HStack {
				Text("Student Name")
				TextField("Student Name", text: $studentName)
					.frame(width: 150)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Contact Name")
				TextField("Contact First Name", text: $contactFirstName)
					.frame(width: 150)
					.textFieldStyle(.roundedBorder)
			
				TextField("Contact Last Name", text: $contactLastName)
					.frame(width: 150)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Contact Email")
				TextField("Contact EMail", text: $contactEmail)
					.frame(width: 200)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Contact Phone")
				TextField("Contact Phone", text: $contactPhone)
					.frame(width: 125)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Contact Zip Code")
				TextField("Contact Zip Code", text: $contactZipCode)
					.frame(width: 125)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Picker("Location", selection: $location) {
					ForEach(referenceData.locations.locationsList) { option in
						Text(String(option.locationName)).tag(option.locationName)
					}
				}
				.frame(width: 200)
				.clipped()
			}
			
			
			Button(action: {
				let studentName = studentName.trimmingCharacters(in: .whitespaces)
				let contactFirstName = contactFirstName.trimmingCharacters(in: .whitespaces)
				let contactLastName = contactLastName.trimmingCharacters(in: .whitespaces)
				let contactEmail = contactEmail.trimmingCharacters(in: .whitespaces)
				let contactPhone = contactPhone.trimmingCharacters(in: .whitespaces)
				let contactZipCode = contactZipCode.trimmingCharacters(in: .whitespaces)
				Task {
					if updateStudentFlag {
						let (studentValidationResult, validationMessage) = studentMgmtVM.validateUpdatedStudent(referenceData: referenceData, studentName: studentName, originalStudentName: originalStudentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactZipCode: contactZipCode, locationName: location)
						if studentValidationResult {
							let (updateResult, updateMessage) = await studentMgmtVM.updateStudent(referenceData: referenceData, studentKey: studentKey, studentName: studentName, originalStudentName: originalStudentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactZipCode: contactZipCode, location: location)
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
						let (studentValidationResult, validationMessage) = studentMgmtVM.validateNewStudent(referenceData: referenceData, studentName: studentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactZipCode: contactZipCode, locationName: location)
						if studentValidationResult {
							let (addResult, addMessage) = await studentMgmtVM.addNewStudent(referenceData: referenceData, studentName: studentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactZipCode: contactZipCode, location: location)
							if !addResult {
								buttonErrorMsg = addMessage
								showAlert = true
							} else {
								dismiss()
							}
						} else {
							buttonErrorMsg = validationMessage
							showAlert = true
						}
					}
				}
			}){
				if updateStudentFlag {
					Text("Update Student \(originalStudentName)")
				} else {
					Text("Add New Student")
				}
			}
			.navigationTitle("Student Display")
			
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
			.padding()
			//            .background(Color.orange)
			//            .foregroundColor(Color.white)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			
			Spacer()
			
		}
	}
}

//#Preview {
//    AddStudent()
//}
