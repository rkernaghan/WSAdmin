//
//  AddService.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation
import SwiftUI

struct ServiceView: View {
    var updateServiceFlag: Bool
    var serviceNum: Int
    var referenceData: ReferenceData
    var serviceKey: String
    @State var timesheetName: String
    @State var invoiceName: String
    @State var serviceType: ServiceTypeOption
    @State var billingType: BillingTypeOption
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
                Text("Cost 1")
                TextField("Cost 1", value: $cost1, format: .number)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 2")
                TextField("Cost 2", value: $cost2, format: .number)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Cost 3")
                TextField("Cost 3", value: $cost3, format: .number)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Price 1")
                TextField("Price 1", value: $price1, format: .number)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Price 2")
                TextField("Price 2", value: $price2, format: .number)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Price 3")
                TextField("Price 3", value: $price3, format: .number)
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
                    ForEach(BillingTypeOption.allCases, id:\.self) { option in
                                Text(String(describing: option))
                            }
                        }
//                        .pickerStyle(.wheel)
            }

            Button(action: {
                if updateServiceFlag {
                    serviceMgmtVM.updateService(serviceNum: serviceNum, referenceData: referenceData, timesheetName: timesheetName, invoiceName: invoiceName, serviceType: String(describing: serviceType), billingType: String(describing: billingType), cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
                } else {
                    serviceMgmtVM.addNewService(referenceData: referenceData, timesheetName: timesheetName, invoiceName: invoiceName, serviceType: String(describing: serviceType), billingType: String(describing: billingType), cost1: cost1, cost2: cost2, cost3: cost3, price1: price1, price2: price2, price3: price3)
                }
            }){
                Text("Add/Update Service")
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

