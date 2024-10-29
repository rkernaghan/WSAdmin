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
    var referenceData: ReferenceData
    
    @State var tutorName: String
    @State var contactEmail: String
    @State var contactPhone: String
    @State var maxStudents: Int
    
    @State private var showAlert = false
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        VStack {
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
                TextField("Contact EMail", text: $contactEmail)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            HStack {
                Text("Tutor Phone")
                TextField("Contact Phone", text: $contactPhone)
                    .frame(width: 120)
                    .textFieldStyle(.roundedBorder)
             }
            
            Button(action: {
                Task {
                    let tutorName = tutorName.trimmingCharacters(in: .whitespaces)
                    let contactEmail = contactEmail.trimmingCharacters(in: .whitespaces)
                    let contactPhone = contactPhone.trimmingCharacters(in: .whitespaces)
                    
                    if updateTutorFlag {
                        let (tutorValidationResult, validationMessage) = tutorMgmtVM.validateUpdatedTutor(tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorMaxStudents: maxStudents, referenceData: referenceData)
                        if tutorValidationResult {
                            await tutorMgmtVM.updateTutor(tutorNum: tutorNum, referenceData: referenceData, tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
                            dismiss()
                        } else {
                            buttonErrorMsg = validationMessage
                            showAlert = true
                        }
                        
                    } else {
                        let (tutorValidationResult, validationMessage) = tutorMgmtVM.validateNewTutor(tutorName: tutorName, tutorEmail: contactEmail, tutorPhone: contactPhone, tutorMaxStudents: maxStudents, referenceData: referenceData)
                        if tutorValidationResult {
                            await tutorMgmtVM.addNewTutor(referenceData: referenceData, tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
                            dismiss()
                        } else {
                            buttonErrorMsg = validationMessage
                            showAlert = true
                        }
                    }
                }
                
            }){
                Text("Add Tutor")
            }
            .alert(buttonErrorMsg, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding()

            Spacer()

        }
    }
}

//#Preview {
//    AddStudent()
//}
