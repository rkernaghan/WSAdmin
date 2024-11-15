//
//  AddLocation.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-05.
//

import Foundation
import SwiftUI

struct LocationView: View {
	var updateLocationFlag: Bool
	var locationNum: Int
	var originalLocationName: String
	var referenceData: ReferenceData
	
	@State var locationName: String
	@State private var showAlert: Bool = false
	
	@Environment(RefDataVM.self) var refDataVM: RefDataVM
	@Environment(LocationMgmtVM.self) var locationMgmtVM: LocationMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		
		VStack {
			HStack {
				Text("Location Name")
				TextField("Location Name", text: $locationName)
					.frame(width: 200)
					.textFieldStyle(.roundedBorder)
			}
			
			Button(action: {
				Task {
					let locationName = locationName.trimmingCharacters(in: .whitespaces)

					let (locationValidationResult, validationMessage) = locationMgmtVM.validateNewLocation(referenceData: referenceData, locationName: locationName)
					if locationValidationResult {
						if updateLocationFlag {
							let (updateResult, updateMessage) = await locationMgmtVM.updateLocation(locationNum: locationNum, referenceData: referenceData, newLocationName: locationName, originalLocationName: originalLocationName)
							if !updateResult {
								showAlert.toggle()
								buttonErrorMsg = updateMessage
							} else {
								dismiss()
							}
						} else {
							let (addResult, addMessage) = await locationMgmtVM.addNewLocation(referenceData: referenceData, locationName: locationName, locationMonthRevenue: 0.0, locationTotalRevenue: 0.0)
							if !addResult {
								showAlert.toggle()
								buttonErrorMsg = addMessage
							} else {
								dismiss()
							}
						}
					} else {
						buttonErrorMsg = validationMessage
						showAlert = true
					}
				}
				
			}){
				if updateLocationFlag {
					Text("Save Location Name Change")
				} else {
					Text("Add New Location")
				}
			}
//			.alert(buttonErrorMsg, isPresented: $showAlert) {
//				Button("OK", role: .cancel) { }
//			}
			.padding()
			//            .background(Color.orange)
			//            .foregroundColor(Color.white)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			
			Spacer()
			
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
	}
}

//#Preview {
//    AddStudent()
//}

