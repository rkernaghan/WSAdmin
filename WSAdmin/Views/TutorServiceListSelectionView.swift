//
//  TutorServiceListSelectionView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-17.
//

//
import SwiftUI

struct TutorServiceListSelectionView: View {
	@Binding var tutorNum: Int
	var referenceData: ReferenceData
	
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	@State private var selectedService = Set<TutorService.ID>()
	@State private var sortOrder = [KeyPathComparator(\TutorService.timesheetServiceName)]
	@State private var showAlert = false
	@State private var viewChange: Bool = false
	
	var body: some View {
		let serviceList = referenceData.tutors.tutorsList[tutorNum].tutorServices
		VStack {
			Table(serviceList, selection: $selectedService, sortOrder: $sortOrder) {
				
				TableColumn("Service Name", value: \.timesheetServiceName)
					.width(min: 120, ideal: 160, max: 200)
				TableColumn("Invoice Name", value: \.invoiceServiceName)
					.width(min: 100, ideal: 120, max: 200)
			}
			
			.contextMenu(forSelectionType: TutorService.ID.self) { items in
				if items.count == 1 {
					VStack {
						Button {
							Task {
								let (unassignResult, unassignMessage) = await tutorMgmtVM.unassignTutorServiceSet(tutorNum: tutorNum, tutorServiceIndex: items, referenceData: referenceData)
								if !unassignResult {
									showAlert.toggle()
									buttonErrorMsg = unassignMessage
								} else {
									dismiss()
								}
							}
							
						} label: {
							Label("Unassign Service from Tutor", systemImage: "square.and.arrow.up")
						}
					}
					
					
				} else {
					Button {
						Task {
							let (unassignResult, unassignMessage) = await tutorMgmtVM.unassignTutorServiceSet(tutorNum: tutorNum, tutorServiceIndex: items, referenceData: referenceData)
							if !unassignResult {
								showAlert.toggle()
								buttonErrorMsg = unassignMessage
							} else {
								dismiss()
							}
						}
					} label: {
						Label("Assign Services from Tutor", systemImage: "square.and.arrow.up")
					}
				}
				
			} primaryAction: { items in
				//              store.favourite(items)
			}
			
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
	}
}

