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
    @State var serviceType: String
    @State var billingType: String
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var body: some View {
        
        Text("Add Student")
        
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
                Text("Service Type")
                TextField("Service Type", text: $serviceType)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            HStack {
                Text("Billing Type")
                TextField("Billing Type", text: $billingType)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            Button(action: {
                serviceMgmtVM.addNewService(referenceData: referenceData, timesheetName: timesheetName, invoiceName: invoiceName, serviceType: serviceType, billingType: billingType)
            }){
                Text("Add Student")
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

        }
    }
}

//#Preview {
//    AddStudent()
//}

