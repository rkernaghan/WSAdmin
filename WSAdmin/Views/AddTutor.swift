//
//  AddTutor.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//
import Foundation
import SwiftUI

struct AddTutor: View {
    var referenceData: ReferenceData
    
    @State var tutorName: String
    @State var maxStudents: String
    @State var contactPhone: String
    @State var contactEmail: String
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var body: some View {
        
        Text("Add Tutor")
        
        VStack {
            HStack {
                Text("Tutor Name")
                TextField("Tutor Name", text: $tutorName)
                    .frame(width: 300)
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
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            HStack {
                Text("Max Students")
                TextField("Max Students", text: $maxStudents)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            Button(action: {
                tutorMgmtVM.addNewTutor(referenceData: referenceData, tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxSessions: maxStudents)
    
            }){
                Text("Add Tutor")
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

        }
    }
}

//#Preview {
//    AddStudent()
//}
