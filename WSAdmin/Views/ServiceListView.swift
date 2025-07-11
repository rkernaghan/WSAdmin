//
//  ServicesView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-11-03.
//

import SwiftUI

struct ServiceListView: View {
	var referenceData: ReferenceData
	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	
	@State private var selectedServices = Set<Service.ID>()
	@State private var sortOrder = [KeyPathComparator(\Service.serviceTimesheetName)]
	
	@State private var assignService: Bool = false
	@State private var editService: Bool = false
	@State private var listServiceCosts: Bool = false
	
	@State private var showAssigned: Bool = true
	@State private var showUnassigned: Bool = true
	@State private var showDeleted: Bool = false
	@State private var showAlert: Bool = false
	
	@State private var emptyArray = [Service]()
	@State private var serviceNumber: Int = 0
	@State private var serviceCostList = TutorServiceCostList()
	
	
	var body: some View {
		if referenceData.services.isServiceDataLoaded {
			
			var deletedArray: [Service] {
				if showDeleted  {
					return referenceData.services.servicesList.filter{$0.serviceStatus == "Deleted"}
				} else {
					return emptyArray
				}
			}
			
			var unassignedArray: [Service] {
				if showUnassigned {
					return referenceData.services.servicesList.filter{$0.serviceStatus == "Unassigned"}
				} else {
					return emptyArray
				}
			}

			var assignedArray: [Service] {
				if showAssigned {
					return referenceData.services.servicesList.filter{$0.serviceStatus == "Assigned"}
				} else {
					return emptyArray
				}
			}
			
			let serviceArray: [Service] = assignedArray + unassignedArray + deletedArray
			
			VStack {
				HStack {
					Toggle("Show Assigned", isOn: $showAssigned)
					Toggle("Show Unassigned", isOn: $showUnassigned)
					Toggle("Show Deleted", isOn: $showDeleted)
					Text("     Service Count: ")
					Text(String(serviceArray.count))
				}
				
				Table(serviceArray, selection: $selectedServices, sortOrder: $sortOrder) {
					Group {
						TableColumn("Timesheet Name", value: \Service.serviceTimesheetName)
							.width(min: 120, ideal: 160, max: 240)
						
						TableColumn("Invoice Name", value: \Service.serviceInvoiceName)
							.width(min: 120, ideal: 160, max: 240)
						
						TableColumn("Service\nType") { (data: Service) in
							Text(data.serviceType.rawValue)
						}
						.width(min: 40, ideal: 50, max: 60)
						
						TableColumn("Billing\nType") { (data: Service) in
							Text(data.serviceBillingType.rawValue)
						}
						.width(min: 40, ideal: 50, max: 60)
						
						TableColumn("Service\nStatus", value: \Service.serviceStatus)
							.width(min: 50, ideal: 70, max: 80)
						
						TableColumn("Assigned\nTutors" ) { (data: Service) in
							Text(String(data.serviceCount))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 60)
					}
					
					Group {
						
						TableColumn("Cost 1") { (data: Service) in
							Text(String(data.serviceCost1.formatted(.number.precision(.fractionLength(2)))))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)

						TableColumn("Cost 2") { (data: Service) in
							Text(String(data.serviceCost2.formatted(.number.precision(.fractionLength(2)))))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
						
						TableColumn("Cost 3") { (data: Service) in
							Text(String(data.serviceCost3.formatted(.number.precision(.fractionLength(2)))))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
						
						TableColumn("Total\nCost") { (data: Service) in
							Text(String(data.serviceTotalCost.formatted(.number.precision(.fractionLength(2))) ))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 60, max: 60)
					}
					
					Group {
						
						TableColumn("Price 1") { (data: Service) in
							Text(String(data.servicePrice1.formatted(.number.precision(.fractionLength(2)))))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
					
						TableColumn("Price 2") { (data: Service) in
							Text(String(data.servicePrice2.formatted(.number.precision(.fractionLength(2)))))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
						
						TableColumn("Price 3") { (data: Service) in
						       Text(String(data.servicePrice3.formatted(.number.precision(.fractionLength(2)))))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
						
						TableColumn("Total\nPrice") { (data: Service) in
							Text(String(data.serviceTotalPrice.formatted(.number.precision(.fractionLength(2))) ))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 60, max: 60)
					}
					
				}
				.contextMenu(forSelectionType: Service.ID.self) { items in
					if items.isEmpty {
						Button {
							//                     AddService(referenceData: referenceData, timesheetName: " ", invoiceName: " ", serviceType: " ", billingType: " ")
						} label: {
							Label("New Service", systemImage: "plus")
						}
					} else if items.count == 1 {
						VStack {
							Button {
								for objectID in items {
									if let idx = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
										serviceNumber = idx
										assignService.toggle()
									}
								}
							} label: {
								Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
							}
							
							Button {
								for objectID in items {
									if let idx = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
										serviceNumber = idx
										editService.toggle()
									}
								}
							} label: {
								Label("Edit Service", systemImage: "square.and.arrow.up")
							}
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await serviceMgmtVM.deleteService(indexes: items, referenceData: referenceData)
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Delete Service", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								Task {
									let (unDeleteResult, unDeleteMessage) = await serviceMgmtVM.unDeleteService(indexes: items, referenceData: referenceData)
									if unDeleteResult == false {
										showAlert = true
										buttonErrorMsg = unDeleteMessage
									}
								}
							} label: {
								Label("Undelete Service", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								for objectID in items {
									if let idx = referenceData.services.servicesList.firstIndex(where: {$0.id == objectID} ) {
										serviceNumber = idx
										listServiceCosts.toggle()
										serviceCostList = tutorMgmtVM.buildServiceCostArray(serviceNum: serviceNumber, referenceData: referenceData)
									}
								}
							} label: {
								Label("List Individual Tutor Costs", systemImage: "trash")
							}
						}
						
					} else {
						Button {
							
						} label: {
							Label("Edit Services", systemImage: "heart")
						}
						Button(role: .destructive) {
							
						} label: {
							Label("Delete Selected", systemImage: "trash")
						}
					}
					
				} primaryAction: { items in
					//              store.favourite(items)
				}
				.navigationTitle("Services List")
				
				.alert(buttonErrorMsg, isPresented: $showAlert) {
					Button("OK", role: .cancel) { }
				}
				
				.navigationDestination(isPresented: $assignService) {
					TutorServiceSelectionView(serviceNum: $serviceNumber, referenceData: referenceData)
				}
				.navigationDestination(isPresented: $editService) {
					if referenceData.services.servicesList.count > 0 {
						ServiceView(updateServiceFlag: true, serviceNum: serviceNumber, originalTimesheetName: referenceData.services.servicesList[serviceNumber].serviceTimesheetName, referenceData: referenceData, serviceKey: referenceData.services.servicesList[serviceNumber].serviceKey, timesheetName: referenceData.services.servicesList[serviceNumber].serviceTimesheetName,  invoiceName:  referenceData.services.servicesList[serviceNumber].serviceInvoiceName, serviceType:  referenceData.services.servicesList[serviceNumber].serviceType, billingType:  referenceData.services.servicesList[serviceNumber].serviceBillingType, serviceCount:  referenceData.services.servicesList[serviceNumber].serviceCount, cost1:  referenceData.services.servicesList[serviceNumber].serviceCost1, cost2: referenceData.services.servicesList[serviceNumber].serviceCost2, cost3: referenceData.services.servicesList[serviceNumber].serviceCost3, price1: referenceData.services.servicesList[serviceNumber].servicePrice1, price2: referenceData.services.servicesList[serviceNumber].servicePrice2, price3: referenceData.services.servicesList[serviceNumber].servicePrice3)
					}
				}
				.navigationDestination(isPresented: $listServiceCosts) {
					if $serviceCostList.tutorServiceCostList.count > 0 {
						ServiceCostByTutorView(serviceNum: $serviceNumber, serviceCostList: $serviceCostList, referenceData: referenceData)
					}
				}
			}
		}
	}
}

