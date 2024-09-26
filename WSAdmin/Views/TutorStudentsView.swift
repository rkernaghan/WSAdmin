//
//  TutorStudentsView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-21.
//

import SwiftUI

struct TutorStudentsView: View {
  @Binding var tutorNum: Int
//    var tutorIndex: Set<Tutor.ID>
    var referenceData: ReferenceData
    
    var body: some View {
//        ForEach(tutorIndex) {tutor in
//            if let tutorNum = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == tutorIndex} ) {
                Table(referenceData.tutors.tutorsList[tutorNum].tutorStudents) {
                    TableColumn("Student Name", value: \.studentName)
                    TableColumn("Phone", value: \.clientName)
                    TableColumn("Email", value: \.clientEmail)
                    TableColumn("Status", value: \.clientPhone)
  //              }
  //          }
        }
    }
}

// #Preview {
//    TutorStudentsView()
// }
