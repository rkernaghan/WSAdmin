//
//  AddStudent.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import SwiftUI

struct StudentView: View {
    
    var updateStudentFlag: Bool
    var referenceData: ReferenceData
    var studentKey: String
    
    @State var studentName: String
    @State var guardianName: String
    @State var contactPhone: String
    @State var contactEmail: String
    @State var location: String
    @State var studentType: StudentTypeOption
    
    @State private var showAlert: Bool = false
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        VStack {
            HStack {
                Text("Student Name")
                TextField("Stuudent Name", text: $studentName)
                    .frame(width: 150)
                    .textFieldStyle(.roundedBorder)
             }
            
            HStack {
                Text("Guardian Name")
                TextField("Guardian Name", text: $guardianName)
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
                Picker("Location", selection: $location) {
                    ForEach(referenceData.locations.locationsList) { option in
                        Text(String(option.locationName)).tag(option.locationName)
                            }
                        }
                .frame(width: 200)
                .clipped()
             }

            HStack {
                Picker("Student Type", selection: $studentType) {
                            ForEach(StudentTypeOption.allCases) { option in
                                Text(String(describing: option))
                            }
                        }
                .frame(width: 200)
                .clipped()
            }

            Button(action: {
                let studentName = studentName.trimmingCharacters(in: .whitespaces)
                let guardianName = guardianName.trimmingCharacters(in: .whitespaces)
                let contactEmail = contactEmail.trimmingCharacters(in: .whitespaces)
                let contactPhone = contactPhone.trimmingCharacters(in: .whitespaces)
                
                if updateStudentFlag {
                    let (studentValidationResult, validationMessage) = studentMgmtVM.validateUpdatedStudent(referenceData: referenceData, studentName: studentName, guardianName: guardianName, contactEmail: contactEmail, contactPhone: contactPhone, studentType: studentType, locationName: location)
                    if studentValidationResult {
                        studentMgmtVM.updateStudent(referenceData: referenceData, studentKey: studentKey, studentName: studentName, guardianName: guardianName, contactEmail: contactEmail, contactPhone: contactPhone, studentType: studentType, location: location)
                        dismiss()
                    } else {
                        buttonErrorMsg = validationMessage
                        showAlert = true
                    }
                } else {
                    let (studentValidationResult, validationMessage) = studentMgmtVM.validateNewStudent(referenceData: referenceData, studentName: studentName, guardianName: guardianName, contactEmail: contactEmail, contactPhone: contactPhone, studentType: studentType, locationName: location)
                    if studentValidationResult {
                        studentMgmtVM.addNewStudent(referenceData: referenceData, studentName: studentName, guardianName: guardianName, contactEmail: contactEmail, contactPhone: contactPhone, studentType: studentType, location: location)
                        dismiss()
                    } else {
                        buttonErrorMsg = validationMessage
                        showAlert = true
                    }
                }
            }){
                Text("Add/Edit Student")
            }
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