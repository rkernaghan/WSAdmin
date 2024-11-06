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
    var billingType: BillingTypeOption
    @State var cost1: Float
    @State var cost2: Float
    @State var cost3: Float
    @State var price1: Float
    @State var price2: Float
    @State var price3: Float
    
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
                Text(billingType.rawValue)
                    .frame(width: 150)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 1")
                TextField("Cost 1", value: $cost1, format: .number)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 2")
                TextField("Cost 2", value: $cost2, format: .number)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 3")
                TextField("Cost 3", value: $cost3, format: .number)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Price 1")
                TextField("Price 1", value: $price1, format: .number)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Price 2")
                TextField("Price 2", value: $price2, format: .number)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
             }
            HStack {
                Text("Price 3")
                TextField("Price 3", value: $price3, format: .number)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
             }

            Button{
                Task {
                    await tutorMgmtVM.updateTutorService(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData, timesheetName: timesheetName, invoiceName: invoiceName, billingType: billingType, cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
                
                }
                } label: {
                    Label("Edit Service", systemImage: "square.and.arrow.up")
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


