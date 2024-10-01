//
//  TutorServiceView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-30.
//

import Foundation
import SwiftUI

struct TutorServiceView: View {
    @Binding var tutorNum: Int
    @Binding var tutorServiceNum: Int
    var referenceData: ReferenceData
    
    var timesheetName: String
    var invoiceName: String
    var billingType: String
    @State var cost1: String
    @State var cost2: String
    @State var cost3: String
    @State var price1: String
    @State var price2: String
    @State var price3: String
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var body: some View {
        
        VStack {
            HStack {
                Text("Timesheet Name")
                Text(timesheetName)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Invoice Name")
                Text(invoiceName)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
           
            HStack {
                Text("Billing Type")
                Text(billingType)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 1")
 //               TextField("Cost 1", text: String(cost1.formatted(.number.precision(.fractionLength(2)))))
                TextField("Cost 1", text: $cost1)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 2")
                TextField("Cost 2", text: $cost2)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 3")
                TextField("Cost 3", text: $cost3)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Price 1")
                TextField("Price 1", text: $price1)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Price 2")
                TextField("Price 2", text: $price2)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            HStack {
                Text("Price 3")
                TextField("Price 3", text: $price3)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }

            Button(action: {
                tutorMgmtVM.updateTutorService(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
            }){
                Text("Edit Service")
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


