//
//  AddStudent.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import SwiftUI

struct AddStudent: View {
    var referenceData: ReferenceData
    
    @State var studentName: String
    @State var guardianName: String
    @State var contactPhone: String
    @State var contactEmail: String
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var body: some View {
        
        Text("Add Student")
        
        VStack {
            HStack {
                Text("Student Name")
                TextField("Stuudent Name", text: $studentName)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            HStack {
                Text("Guardian Name")
                TextField("Guardian Name", text: $guardianName)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            HStack {
                Text("Contact Email")
                TextField("Contact EMail", text: $contactEmail)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            HStack {
                Text("Contact Phone")
                TextField("Contact Phone", text: $contactPhone)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            Button(action: {
                studentMgmtVM.addNewStudent(referenceData: referenceData, studentName: studentName, guardianName: guardianName, contactEmail: contactEmail, contactPhone: contactPhone)
            }){
                Text("Add Student")
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
