//
//  TutorStudentsView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-21.
//

import SwiftUI

struct TutorStudentsView: View {
  var tutorNum: Int
    var referenceData: ReferenceData
    
    var body: some View {
        Table(referenceData.tutors.tutorsList[tutorNum].tutorStudents) {
            TableColumn("Student Name", value: \.studentName)
            TableColumn("Phone", value: \.clientName)
            TableColumn("Email", value: \.clientEmail)
            TableColumn("Status", value: \.clientPhone)
        }
    }
}

// #Preview {
//    TutorStudentsView()
// }
