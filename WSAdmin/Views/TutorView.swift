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
    @State var maxStudents: String
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var body: some View {
        
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
                if updateTutorFlag {
                    tutorMgmtVM.updateTutor(tutorNum: tutorNum, referenceData: referenceData, tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
                } else {
                    tutorMgmtVM.addNewTutor(referenceData: referenceData, tutorName: tutorName, contactEmail: contactEmail, contactPhone: contactPhone, maxStudents: maxStudents)
                }
            }){
                Text("Add Tutor")
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
