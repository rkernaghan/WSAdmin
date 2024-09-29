//
//  AddLocation.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation
import SwiftUI

struct LocationView: View {
    var referenceData: ReferenceData
    
    @State var locationName: String
 
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(LocationMgmtVM.self) var locationMgmtVM: LocationMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var body: some View {
        
        Text("Add Location")
        
        VStack {
            HStack {
                Text("Location Name")
                TextField("Location Name", text: $locationName)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
             }
            
            Button(action: {
                locationMgmtVM.addNewLocation(referenceData: referenceData, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0)
            }){
                Text("Add Location")
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

