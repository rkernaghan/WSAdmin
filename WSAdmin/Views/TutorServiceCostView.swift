//
//  TutorServiceCostView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-07.
//
import Foundation
import SwiftUI

struct TutorServiceCostView: View {
    @Binding var serviceNum: Int
    @Binding var serviceCostList: TutorServiceCostList
    var referenceData: ReferenceData
    
    @Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedServices: Set<Service.ID> = []
    @State private var tutorServiceNum: Int = 0
    @State private var editTutorService = false
    @State private var unassignTutorService = false
    @State private var sortOrder = [KeyPathComparator(\TutorServiceCost.tutorName)]
    
    var body: some View {
        VStack {
            Table(serviceCostList.tutorServiceCostList) {
                TableColumn("Tutor Name", value: \.tutorName)
                
                TableColumn("Cost 1") { data in
                    Text(String(data.cost1.formatted(.number.precision(.fractionLength(2)))))
                }
                TableColumn("Cost 2") { data in
                    Text(String(data.cost2.formatted(.number.precision(.fractionLength(2)))))
                }
                TableColumn("Cost 3") { data in
                    Text(String(data.cost3.formatted(.number.precision(.fractionLength(2)))))
                }
                TableColumn("Price 1") { data in
                    Text(String(data.price1.formatted(.number.precision(.fractionLength(2)))))
                }
                TableColumn("Price 2") { data in
                    Text(String(data.price2.formatted(.number.precision(.fractionLength(2)))))
                }
                TableColumn("Price 3") { data in
                    Text(String(data.price3.formatted(.number.precision(.fractionLength(2)))))
                }
                TableColumn("Total Price") { data in
                    Text(String(data.totalPrice.formatted(.number.precision(.fractionLength(2)))))
                }
            }
        }

    }
}

// #Preview {
//    TutorStudentsView()
// }

