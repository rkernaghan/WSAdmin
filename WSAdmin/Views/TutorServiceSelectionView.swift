//
//  TutorServiceSelectionView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-04.
//
import SwiftUI

struct TutorServiceSelectionView: View {
	@Binding var serviceNum: Int
	var referenceData: ReferenceData
	
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	
	@State private var selectedTutor = Set<Tutor.ID>()
	@State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
	@State private var showAlert = false
	@State private var viewChange: Bool = false
	
	var body: some View {
		
		VStack {
			Table(referenceData.tutors.tutorsList, selection: $selectedTutor, sortOrder: $sortOrder) {
				
				TableColumn("Tutor Name", value: \.tutorName)
					.width(min: 120, ideal: 160, max: 200)
				TableColumn("Tutor Status", value: \.tutorStatus)
					.width(min: 100, ideal: 120, max: 200)
			}
			
			.contextMenu(forSelectionType: Tutor.ID.self) { items in
				if items.count == 1 {
					VStack {
						Button {
							Task {
								let (assignResult, assignMessage) = await tutorMgmtVM.assignTutorService(serviceNum: serviceNum, tutorIndex: items, referenceData: referenceData)
								if !assignResult {
									showAlert.toggle()
									buttonErrorMsg = assignMessage
								}
							}
							
						} label: {
							Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
						}
					}
					
					
				} else {
					Button {
						Task {
							await tutorMgmtVM.assignTutorService(serviceNum: serviceNum, tutorIndex: items, referenceData: referenceData)
						}
					} label: {
						Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
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
