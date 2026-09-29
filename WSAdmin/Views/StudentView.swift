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
	@State var contactAddress1: String
	@State var contactAddress2: String
	@State var contactCity: String
	@State var contactState: String
	@State var contactZipCode: String
	
	@State var contactEmail: String
	@State var location: String
	
	@State private var showAlert: Bool = false
	@State private var showNewLocationField: Bool = false
	@State private var newLocationName: String = ""
	@State private var isSavingLocation: Bool = false

	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	@Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(LocationMgmtVM.self) var locationMgmtVM: LocationMgmtVM
	@Environment(\.dismiss) var dismiss

	// Validates and adds the Location typed into the New Location field, then selects it in the Location picker
	private func saveNewLocation() {
		let locationName = newLocationName.trimmingCharacters(in: .whitespaces)
		let (locationValidationResult, validationMessage) = locationMgmtVM.validateNewLocation(referenceData: referenceData, locationName: locationName)
		if !locationValidationResult {
			buttonErrorMsg = validationMessage
			showAlert = true
			return
		}

		isSavingLocation = true
		Task {
			let (addResult, addMessage) = await locationMgmtVM.addNewLocation(referenceData: referenceData, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0)
			isSavingLocation = false
			if addResult {
				location = locationName
				newLocationName = ""
				showNewLocationField = false
			} else {
				buttonErrorMsg = addMessage
				showAlert = true
			}
		}
	}

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
				Text("Contact Address 1")
				TextField("Contact Address 1", text: $contactAddress1)
					.frame(width: 125)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Contact Address 2")
				TextField("Contact Address 2", text: $contactAddress2)
					.frame(width: 125)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Contact City")
				TextField("Contact City", text: $contactCity)
					.frame(width: 125)
					.textFieldStyle(.roundedBorder)
			}
			
			HStack {
				Text("Contact State")
				TextField("Contact State", text: $contactState)
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

				Button("Add New Location") {
					newLocationName = ""
					showNewLocationField = true
				}
				.disabled(showNewLocationField)
			}

			// Entry field for a Location that isn't in the picker list yet
			if showNewLocationField {
				HStack {
					Text("New Location")
					TextField("New Location Name", text: $newLocationName)
						.frame(width: 200)
						.textFieldStyle(.roundedBorder)
						.onSubmit { saveNewLocation() }

					Button("Save Location") { saveNewLocation() }
						.disabled(newLocationName.trimmingCharacters(in: .whitespaces).isEmpty || isSavingLocation)

					Button("Cancel") {
						newLocationName = ""
						showNewLocationField = false
					}
					.disabled(isSavingLocation)
				}
			}

			
			Button(action: {
				let studentName = studentName.trimmingCharacters(in: .whitespaces)
				let contactFirstName = contactFirstName.trimmingCharacters(in: .whitespaces)
				let contactLastName = contactLastName.trimmingCharacters(in: .whitespaces)
				let contactEmail = contactEmail.trimmingCharacters(in: .whitespaces)
				let contactPhone = contactPhone.trimmingCharacters(in: .whitespaces)
				let contactAddress1 = contactAddress1.trimmingCharacters(in: .whitespaces)
				let contactAddress2 = contactAddress2.trimmingCharacters(in: .whitespaces)
				let contactCity = contactCity.trimmingCharacters(in: .whitespaces)
				let contactState = contactState.trimmingCharacters(in: .whitespaces)
				let contactZipCode = contactZipCode.trimmingCharacters(in: .whitespaces)
				Task {
					if updateStudentFlag {
						let (studentValidationResult, validationMessage) = studentMgmtVM.validateUpdatedStudent(referenceData: referenceData, studentName: studentName, originalStudentName: originalStudentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactAddress1: contactAddress1, contactAddress2: contactAddress2, contactCity: contactCity, contactState: contactState, contactZipCode: contactZipCode, locationName: location)
						if studentValidationResult {
							let (updateResult, updateMessage) = await studentMgmtVM.updateStudent(referenceData: referenceData, studentKey: studentKey, studentName: studentName, originalStudentName: originalStudentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactAddress1: contactAddress1, contactAddress2: contactAddress2, contactCity: contactCity, contactState: contactState, contactZipCode: contactZipCode, location: location)
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
						let (studentValidationResult, validationMessage) = studentMgmtVM.validateNewStudent(referenceData: referenceData, studentName: studentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactAddress1: contactAddress1, contactAddress2: contactAddress2, contactCity: contactCity, contactState: contactState, contactZipCode: contactZipCode, locationName: location)
						if studentValidationResult {
							let (addResult, addMessage) = await studentMgmtVM.addNewStudent(referenceData: referenceData, studentName: studentName, contactFirstName: contactFirstName, contactLastName: contactLastName, contactEmail: contactEmail, contactPhone: contactPhone, contactAddress1: contactAddress1, contactAddress2: contactAddress2, contactCity: contactCity, contactState: contactState, contactZipCode: contactZipCode, location: location)
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
