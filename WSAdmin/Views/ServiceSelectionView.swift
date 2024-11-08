//
//  ServiceSelectionView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-04.
//
import SwiftUI

struct ServiceSelectionView: View {
	@Binding var tutorNum: Int
	var referenceData: ReferenceData
	
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	@Environment(\.dismiss) var dismiss
	
	@State private var selectedServices = Set<Service.ID>()
	@State private var sortOrder = [KeyPathComparator(\Service.serviceTimesheetName)]
	@State private var showAlert = false
	@State private var viewChange: Bool = false
	
	var body: some View {
		
		VStack {
			Table(referenceData.services.servicesList.filter{$0.serviceType == .Special}, selection: $selectedServices, sortOrder: $sortOrder) {
				
				TableColumn("Timesheet Name", value: \.serviceTimesheetName)
					.width(min: 160, ideal: 240, max: 300)
				TableColumn("BillingType") {data in
					Text(data.serviceBillingType.rawValue)
				}
				.width(min: 50, ideal: 70, max: 80)
			}
			
			.contextMenu(forSelectionType: Tutor.ID.self) { items in
				if items.count == 1 {
					VStack {
						
						Button {
							Task {
								await tutorMgmtVM.assignService(serviceIndex: items, tutorNum: tutorNum, referenceData: referenceData)
								dismiss()
							}
						} label: {
							Label("Assign Service to \(referenceData.tutors.tutorsList[tutorNum].tutorName)", systemImage: "square.and.arrow.up")
						}
					}
					
				} else {
					Button {
						Task {
							await tutorMgmtVM.assignService(serviceIndex: items, tutorNum: tutorNum, referenceData: referenceData)
							dismiss()
						}
					} label: {
						Label("Assign Services to \(referenceData.tutors.tutorsList[tutorNum].tutorName)", systemImage: "square.and.arrow.up")
					}
				}
				
			} primaryAction: { items in
				//              store.favourite(items)
			}
		}
	}
}
