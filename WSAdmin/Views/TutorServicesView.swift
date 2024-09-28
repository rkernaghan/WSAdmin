//
//  TutorServicesView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-26.
//

import SwiftUI

struct TutorServicesView: View {
    @Binding var tutorNum: Int
    var referenceData: ReferenceData
    
    @State private var sortOrder = [KeyPathComparator(\TutorService.timesheetServiceName)]
    
    var body: some View {
        Table(referenceData.tutors.tutorsList[tutorNum].tutorServices, sortOrder: $sortOrder) {
            TableColumn("Timesheet Name", value: \.timesheetServiceName)
            TableColumn("Invoice Name", value: \.invoiceServiceName)
            TableColumn("Billing Type", value: \.billingType)
            TableColumn("Cost 1", value: \.cost1) { data in
                Text(String(data.cost1.formatted(.number.precision(.fractionLength(2)))))
            }
            TableColumn("Cost 2", value: \.cost1) { data in
                Text(String(data.cost2.formatted(.number.precision(.fractionLength(2)))))
            }
            TableColumn("Cost 3", value: \.cost1) { data in
                Text(String(data.cost3.formatted(.number.precision(.fractionLength(2)))))
            }
            TableColumn("Price 1", value: \.cost1) { data in
                Text(String(data.price1.formatted(.number.precision(.fractionLength(2)))))
            }
            TableColumn("Price 2", value: \.cost1) { data in
                Text(String(data.price2.formatted(.number.precision(.fractionLength(2)))))
            }
            TableColumn("Price 3", value: \.cost1) { data in
                Text(String(data.price3.formatted(.number.precision(.fractionLength(2)))))
            }
            TableColumn("Total Price", value: \.cost1) { data in
                Text(String(data.totalPrice.formatted(.number.precision(.fractionLength(2)))))
            }
         }
    }
}

// #Preview {
//    TutorStudentsView()
// }
