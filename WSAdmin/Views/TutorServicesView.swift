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
    
    @Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedServices: Set<Service.ID> = []
    @State private var tutorServiceNum: Int = 0
    @State private var editTutorService = false
    @State private var unassignTutorService = false
    @State private var sortOrder = [KeyPathComparator(\TutorService.timesheetServiceName)]
    
    var body: some View {
        VStack {
            Table(referenceData.tutors.tutorsList[tutorNum].tutorServices, selection: $selectedServices, sortOrder: $sortOrder) {
                TableColumn("Timesheet Name", value: \.timesheetServiceName)
                TableColumn("Invoice Name", value: \.invoiceServiceName)
                TableColumn("Billing Type") {data in
                    Text(data.billingType.rawValue)
                }
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
            .contextMenu(forSelectionType: Student.ID.self) { items in
                if items.count == 1 {
                    VStack {
                        
                        Button {
                            for objectID in items {
                                if let idx = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
                                    tutorServiceNum = idx
                                    editTutorService.toggle()
                                }
                            }
                        } label: {
                            Label("Edit Tutor Service for Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            for objectID in items {
                                if let idx = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
                                    tutorServiceNum = idx
                                    let (unassignResult, unassignMessage) = tutorMgmtVM.unassignTutorService(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData)
                                    if unassignResult {
                                        dismiss()
                                    }
                                }
                            }
                        } label: {
                            Label("Unassign Service from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } else {
                    VStack {
                        Button {
                            for objectID in items {
                                if let idx = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
                                    tutorServiceNum = idx
                                    editTutorService.toggle()
                                }
                            }
                        } label: {
                            Label("Edit Tutor Services", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            for objectID in items {
                                if let idx = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
                                    tutorServiceNum = idx
                                    let (unassignResult, unassignMessage) = tutorMgmtVM.unassignTutorService(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData)
                                    if unassignResult {
                                        //                                    dismiss()
                                    }
                                }
                            }
                        } label: {
                            Label("Unassign Tutor Services", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            } primaryAction: { items in
                //              store.favourite(items)
            }
         }
        .navigationDestination(isPresented: $editTutorService) {
//            TutorServiceView(tutorNum: $tutorNum, tutorServiceNum: $tutorServiceNum, referenceData: referenceData, timesheetName: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].timesheetServiceName, invoiceName: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].invoiceServiceName, billingType: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].billingType, cost1: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost1, cost2: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost2, cost3: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].cost3, price1: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price1, price2: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price2, price3: referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum].price3)
        }
    }
}

// #Preview {
//    TutorStudentsView()
// }
