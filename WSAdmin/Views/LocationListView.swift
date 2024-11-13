//
//  LocationsView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-03.
//

import SwiftUI

struct LocationListView: View {
	var referenceData: ReferenceData
	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(LocationMgmtVM.self) var locationMgmtVM: LocationMgmtVM
	@State private var selectedLocations = Set<Location.ID>()
	@State private var sortOrder = [KeyPathComparator(\Location.locationName)]
	@State private var listStudents: Bool = false
	@State private var editLocation: Bool = false
	@State private var locationNumber: Int = 0
	@State private var showDeleted: Bool = false
	@State private var showAlert: Bool = false
	
	var body: some View {
		if referenceData.locations.isLocationDataLoaded {
			
			var locationArray: [Location] {
				if showDeleted {
					return referenceData.locations.locationsList
				} else {
					return referenceData.locations.locationsList.filter{$0.locationStatus != "Deleted"}
				}
			}
			
			VStack {
				Toggle("Show Deleted", isOn: $showDeleted)
				Text("     Location Count: ")
				Text(String(locationArray.count))
				
				Table(locationArray, selection: $selectedLocations, sortOrder: $sortOrder) {
					TableColumn("Location Name", value: \.locationName)
						.width(min: 60, ideal: 80, max: 120)
					
					TableColumn("Student\nCount") {data in
						Text(String(data.locationStudentCount))
							.frame(maxWidth: .infinity, alignment: .center)
					}
					.width(min: 40, ideal: 50, max: 60)
					
					TableColumn("Location\nMonth Revenue") { data in
						Text(String(data.locationMonthRevenue.formatted(.number.precision(.fractionLength(0)))))
							.frame(maxWidth: . infinity, alignment: .trailing)
					}
					.width(min: 50, ideal: 60, max: 80)
					
					TableColumn("Location\nTotal Revenue") { data in
						Text(String(data.locationTotalRevenue.formatted(.number.precision(.fractionLength(0)))))
							.frame(maxWidth: . infinity, alignment: .trailing)
					}
					.width(min: 50, ideal: 60, max: 80)
					
					TableColumn("Location\nStatus", value: \.locationStatus)
						.width(min: 50, ideal: 60, max: 70)
				}
				.contextMenu(forSelectionType: Location.ID.self) { items in
					if items.isEmpty {
						Button {
							//                       let result = AddLocation(referenceData: referenceData, locationName: " ", locationMonthRevenue: 0.0, locationTotalRevenue: 0.0)
						} label: {
							Label("New Service", systemImage: "plus")
						}
					} else if items.count == 1 {
						VStack {
							Button {
								Task {
									for objectID in items {
										if let idx = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
											locationNumber = idx
											editLocation.toggle()
										}
									}
								}
							} label: {
								Label("Edit Location", systemImage: "square.and.arrow.up")
							}
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await locationMgmtVM.deleteLocation(indexes: items, referenceData: referenceData)
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Delete Location", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								Task {
									let (unDeleteResult, unDeleteMessage) = await locationMgmtVM.undeleteLocation(indexes: items, referenceData: referenceData)
									if unDeleteResult == false {
										showAlert = true
										buttonErrorMsg = unDeleteMessage
									}
								}
							} label: {
								Label("Undelete Location", systemImage: "trash")
							}
						}
						
					} else {
						VStack {
							Button {
								
							} label: {
								Label("Edit Locations", systemImage: "heart")
							}
							Button(role: .destructive) {
								
							} label: {
								Label("Delete Selected Locations", systemImage: "trash")
							}
						}
					}
					
				} primaryAction: { items in
					//              store.favourite(items)
				}
				.alert(buttonErrorMsg, isPresented: $showAlert) {
					Button("OK", role: .cancel) { }
				}
				
				.navigationDestination(isPresented: $editLocation) {
					LocationView(updateLocationFlag: true, locationNum: locationNumber, originalLocationName: referenceData.locations.locationsList[locationNumber].locationName, referenceData: referenceData, locationName: referenceData.locations.locationsList[locationNumber].locationName )
				}
			}
		}
	}
}
