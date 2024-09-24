//
//  AddService.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation
import SwiftUI

struct AddService: View {
    var referenceData: ReferenceData
    
    @State var timesheetName: String
    @State var invoiceName: String
    @State var serviceType: ServiceTypeOption = .Base
    @State var billingType: BillingTypeOption = .Fixed
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
        
        Text("Add Service")
        
        VStack {
            HStack {
                Text("Timesheet Name")
                TextField("Timesheet Name", text: $timesheetName)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Invoice Name")
                TextField("Invoice Name", text: $invoiceName)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Picker("Service Type", selection: $serviceType) {
                            ForEach(ServiceTypeOption.allCases) { option in
                                Text(String(describing: option))
                            }
                        }
//                        .pickerStyle(.wheel)
            }
            
            HStack {
                Picker("Billing Type", selection: $billingType) {
                            ForEach(BillingTypeOption.allCases) { option in
                                Text(String(describing: option))
                            }
                        }
//                        .pickerStyle(.wheel)
            }
            HStack {
                Text("Cost 1")
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
                serviceMgmtVM.addNewService(referenceData: referenceData, timesheetName: timesheetName, invoiceName: invoiceName, serviceType: String(describing: serviceType), billingType: String(describing: billingType), cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
            }){
                Text("Add Service")
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

