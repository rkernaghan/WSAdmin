//
//  TutorStudentsView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-21.
//

import SwiftUI

struct TutorStudentsView: View {
    @Binding var tutorNum: Int
    var referenceData: ReferenceData
    
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @State private var selectedStudents: Set<Student.ID> = []
    
    var body: some View {
        VStack {
            Table(referenceData.tutors.tutorsList[tutorNum].tutorStudents, selection: $selectedStudents) {
                TableColumn("Student Name", value: \.studentName)
                TableColumn("Phone", value: \.clientName)
                TableColumn("Email", value: \.clientEmail)
                TableColumn("Status", value: \.clientPhone)
            }
            .contextMenu(forSelectionType: Student.ID.self) { items in
                if items.isEmpty {
                    Button { } label: {
                        Label("New Student", systemImage: "plus")
                    }
                } else if items.count == 1 {
                    VStack {
                        
                        Button {
                            studentMgmtVM.unassignTutorStudent(tutorStudentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
                        } label: {
                            Label("Unassign Student", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } else {
                    Button {
                        studentMgmtVM.unassignTutorStudent(tutorStudentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
                    } label: {
                        Label("Unassign Students", systemImage: "square.and.arrow.up")
                    }
                }
            } primaryAction: { items in
                //              store.favourite(items)
            }
        }
        
    }
    
}

// #Preview {
//    TutorStudentsView()
// }
