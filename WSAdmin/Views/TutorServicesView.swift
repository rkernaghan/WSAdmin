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
	@State private var showAlert: Bool = false
	@State private var sortOrder = [KeyPathComparator(\TutorService.timesheetServiceName)]
	
	var body: some View {
		VStack {
			Table(referenceData.tutors.tutorsList[tutorNum].tutorServices, selection: $selectedServices, sortOrder: $sortOrder) {
				TableColumn("Timesheet Name", value: \.timesheetServiceName)
					.width(min:90, ideal: 120, max: 260)
				
				TableColumn("Invoice Name", value: \.invoiceServiceName)
					.width(min:90, ideal: 120, max: 260)
				
				TableColumn("Billing Type") {data in
					Text(data.billingType.rawValue)
				}
				.width(min:90, ideal: 120, max: 150)
				
				TableColumn("Cost 1", value: \.cost1) { data in
					Text(String(data.cost1.formatted(.number.precision(.fractionLength(2)))))
				}
				.width(min:30, ideal: 45, max: 50)
				
				TableColumn("Cost 2", value: \.cost1) { data in
					Text(String(data.cost2.formatted(.number.precision(.fractionLength(2)))))
				}
				.width(min:30, ideal: 45, max: 50)
				
				TableColumn("Cost 3", value: \.cost1) { data in
					Text(String(data.cost3.formatted(.number.precision(.fractionLength(2)))))
				}
				.width(min:30, ideal: 45, max: 50)
				
				TableColumn("Price 1", value: \.cost1) { data in
					Text(String(data.price1.formatted(.number.precision(.fractionLength(2)))))
				}
				.width(min:30, ideal: 45, max: 60)
				
				TableColumn("Price 2", value: \.cost1) { data in
					Text(String(data.price2.formatted(.number.precision(.fractionLength(2)))))
				}
				.width(min:30, ideal: 45, max: 60)
				
				TableColumn("Price 3", value: \.cost1) { data in
					Text(String(data.price3.formatted(.number.precision(.fractionLength(2)))))
				}
				.width(min:30, ideal: 45, max: 60)
				
				TableColumn("Total Price", value: \.cost1) { data in
					Text(String(data.totalPrice.formatted(.number.precision(.fractionLength(2)))))
				}
				.width(min:30, ideal: 50, max: 70)
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
						
						//						Button {
						//							Task {
						//								for objectID in items {
						//									if let idx = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
						//										tutorServiceNum = idx
						//										let (unassignResult, unassignMessage) = await tutorMgmtVM.unassignTutorServiceSet(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData)
						//										if unassignResult {
						//
						//											dismiss()
						//										} else {
						//											showAlert = true
						//											buttonErrorMsg = unassignMessage
						//										}
						//									}
						//								}
						//							}
						//						} label: {
						//							Label("Unassign Service from Tutor \(referenceData.tutors.tutorsList[tutorNum].tutorName)", systemImage: "square.and.arrow.up")
						//						}
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
						
						//						Button {
						//							Task {
						//								for objectID in items {
						//									if let idx = referenceData.tutors.tutorsList[tutorNum].tutorServices.firstIndex(where: {$0.id == objectID} ) {
						//										tutorServiceNum = idx
						//										let (unassignResult, unassignMessage) = await tutorMgmtVM.unassignTutorServiceSet(tutorNum: tutorNum, tutorServiceNum: tutorServiceNum, referenceData: referenceData)
						//										if !unassignResult {
						//											showAlert = true
						//											buttonErrorMsg = unassignMessage
						//										} else {
						//											dismiss()
						//										}
						//									}
						//								}
						//							}
						//						} label: {
						//							Label("Unassign Tutor Services", systemImage: "square.and.arrow.up")
						//						}
					}
				}
			} primaryAction: { items in
				//              store.favourite(items)
			}
		}
		.navigationTitle("\(referenceData.tutors.tutorsList[tutorNum].tutorName) Tutor Services List")
		
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
		
		// Guarded with bounds checks on BOTH tutorNum and tutorServiceNum.
		// SwiftUI (particularly on macOS) can evaluate a
		// `.navigationDestination(isPresented:)` closure to establish view
		// identity before `isPresented` is actually true, so this closure's
		// body can run even when editTutorService == false and
		// tutorServiceNum is still its default (0). Without this guard,
		// tutorServices[0] on an empty (not-yet-loaded) array crashes with
		// an index-out-of-range error, regardless of whether the user
		// actually tapped "Edit Tutor Service".
		.navigationDestination(isPresented: $editTutorService) {
			if referenceData.tutors.tutorsList.indices.contains(tutorNum),
			   referenceData.tutors.tutorsList[tutorNum].tutorServices.indices.contains(tutorServiceNum) {
				let service = referenceData.tutors.tutorsList[tutorNum].tutorServices[tutorServiceNum]
				TutorServiceView(
					tutorNum: $tutorNum,
					tutorServiceNum: $tutorServiceNum,
					referenceData: referenceData,
					timesheetName: service.timesheetServiceName,
					invoiceName: service.invoiceServiceName,
					billingType: service.billingType,
					cost1: service.cost1,
					cost2: service.cost2,
					cost3: service.cost3,
					price1: service.price1,
					price2: service.price2,
					price3: service.price3
				)
			}
		}
	}
}

// #Preview {
//    TutorStudentsView()
// }
