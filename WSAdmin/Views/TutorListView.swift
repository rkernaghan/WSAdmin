import SwiftUI

// MARK: - Navigation destination

/// A single enum drives all of TutorListView's pushed destinations, keyed by
/// the tutor's stable Tutor.ID rather than a raw array index. This replaces
/// the previous five separate `@State private var ... = false` flags and
/// five chained `.navigationDestination(isPresented:)` modifiers, which is a
/// documented SwiftUI anti-pattern (multiple isPresented destinations on one
/// view can misfire or resolve against stale state).
enum TutorDestination: Identifiable, Hashable {
	case assignStudent(Tutor.ID)
	case listStudents(Tutor.ID)
	case listServices(Tutor.ID)
	case assignService(Tutor.ID)
	case unassignService(Tutor.ID)
	case editTutor(Tutor.ID)
	
	// Hashable enums can serve as their own Identifiable id, which is what
	// `.navigationDestination(item:)` needs.
	var id: Self { self }
}

struct TutorListView: View {
	@State var referenceData: ReferenceData
	
	@State private var selectedTutors: Set<Tutor.ID> = []
	@State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
	@State private var showAlert: Bool = false
	@State private var viewChange: Bool = false
	
	@State private var showAssigned: Bool = true
	@State private var showUnassigned: Bool = true
	@State private var showDeleted: Bool = true
	@State private var showSuspended: Bool = true
	
	@State private var emptyArray = [Tutor]()
	
	// Replaces tutorNumber + the six Bool flags. Setting this to non-nil
	// triggers the single `.navigationDestination(item:)` below.
	@State private var activeDestination: TutorDestination?
	
	// True while a tutor's details are being fetched on demand (see
	// showTutorDetails below), so the UI can show a spinner instead of
	// looking like the button click did nothing.
	@State private var isLoadingTutorDetails: Bool = false
	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	@Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
	
	var body: some View {
		if referenceData.tutors.isTutorDataLoaded {
			
			var deletedArray: [Tutor] {
				if showDeleted {
					return referenceData.tutors.tutorsList.filter { $0.tutorStatus == .TutorDeleted }
				} else {
					return emptyArray
				}
			}
			var unassignedArray: [Tutor] {
				if showUnassigned {
					return referenceData.tutors.tutorsList.filter { $0.tutorStatus == .TutorUnassigned }
				} else {
					return emptyArray
				}
			}
			var suspendedArray: [Tutor] {
				if showSuspended {
					return referenceData.tutors.tutorsList.filter { $0.tutorStatus == .TutorSuspended }
				} else {
					return emptyArray
				}
			}
			var assignedArray: [Tutor] {
				if showAssigned {
					return referenceData.tutors.tutorsList.filter { $0.tutorStatus == .TutorAssigned }
				} else {
					return emptyArray
				}
			}
			
			let tutorArray: [Tutor] = assignedArray + unassignedArray + suspendedArray + deletedArray
			
			VStack {
				if isLoadingTutorDetails {
					ProgressView("Loading tutor details…")
				}
				
				HStack {
					Toggle("Show Assigned", isOn: $showAssigned)
					Toggle("Show Unassigned", isOn: $showUnassigned)
					Toggle("Show Suspended", isOn: $showSuspended)
					Toggle("Show Deleted", isOn: $showDeleted)
					Text("     Tutor Count: ")
					Text(String(tutorArray.count))
				}
				
				Table(tutorArray, selection: $selectedTutors, sortOrder: $sortOrder) {
					Group {
						TableColumn("Tutor Name", value: \Tutor.tutorName)
							.width(min: 70, ideal: 100, max: 180)
						
						TableColumn("Tutor\nType") { (data: Tutor) in
							Text(String(describing: data.tutorType.rawValue))
						}
						.width(min: 50, ideal: 70, max: 90)
						
						TableColumn("Tutor\nStatus") { (data: Tutor) in
							Text(String(describing: data.tutorStatus.rawValue))
						}
						.width(min: 50, ideal: 70, max: 100)
						
						TableColumn("Student\nCount") { data in
							Text(String(data.tutorStudentCount))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
						
						TableColumn("Details\nLoaded") { data in
							Text(String(data.tutorDetailsLoaded))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
						
						TableColumn("Service\nCount") { data in
							Text(String(data.tutorServiceCount))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 40, ideal: 50, max: 50)
					}
					Group {
						TableColumn("Phone", value: \Tutor.tutorPhone)
							.width(min: 90, ideal: 100, max: 110)
						
						TableColumn("Email", value: \Tutor.tutorEmail)
							.width(min: 120, ideal: 160, max: 260)
						
						TableColumn("Start Date", value: \Tutor.tutorStartDate)
							.width(min: 60, ideal: 70, max: 90)
						
						TableColumn("End Date", value: \Tutor.tutorEndDate)
							.width(min: 60, ideal: 70, max: 90)
						
						TableColumn("Max\nStudents") { data in
							Text(String(data.tutorMaxStudents))
								.frame(maxWidth: .infinity, alignment: .center)
						}
						.width(min: 50, ideal: 60, max: 60)
						
						TableColumn("Total\nCost") { data in
							Text(String(data.tutorTotalCost.formatted(.number.precision(.fractionLength(0)))))
								.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.width(min: 40, ideal: 50, max: 60)
						
						TableColumn("Total\nSessions") { data in
							Text(String(data.tutorTotalSessions.formatted(.number.precision(.fractionLength(0)))))
								.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.width(min: 40, ideal: 50, max: 60)
						
						TableColumn("Total\nRevenue") { data in
							Text(String(data.tutorTotalRevenue.formatted(.number.precision(.fractionLength(0)))))
								.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.width(min: 40, ideal: 40, max: 60)
						
						TableColumn("Total\nProfit") { data in
							Text(String(data.tutorTotalProfit.formatted(.number.precision(.fractionLength(0)))))
								.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.width(min: 40, ideal: 50, max: 60)
					}
				}
				.contextMenu(forSelectionType: Tutor.ID.self) { items in
					if items.isEmpty {
						VStack {
							Button {
								print("empty selected Tutor")
							} label: {
								Label("New Tutor", systemImage: "plus")
							}
						}
					} else if items.count == 1 {
						VStack {
							
							Button("Assign Student to Tutor") {
								if let tutorID = items.first {
									activeDestination = .assignStudent(tutorID)
								}
							}
							
							Button("List Tutor Students") {
								if let tutorID = items.first {
									Task {
										await showTutorDetails(for: tutorID, destination: TutorDestination.listStudents)
									}
								}
							}
							
							Button("List Tutor Services") {
								if let tutorID = items.first {
									Task {
										await showTutorDetails(for: tutorID, destination: TutorDestination.listServices)
									}
								}
							}
							
							Button("Add Service to Tutor") {
								if let tutorID = items.first {
									activeDestination = .assignService(tutorID)
								}
							}
							
							Button("Remove Service from Tutor") {
								if let tutorID = items.first {
									activeDestination = .unassignService(tutorID)
								}
							}
							
							Button("Edit Tutor") {
								if let tutorID = items.first {
									activeDestination = .editTutor(tutorID)
								}
							}
							
							Button(role: .destructive) {
								Task {
									let (suspendResult, suspendMessage) = await tutorMgmtVM.suspendTutor(tutorIndex: items, referenceData: referenceData)
									if suspendResult == false {
										showAlert = true
										buttonErrorMsg = suspendMessage
									}
								}
							} label: {
								Label("Suspend Tutor", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								Task {
									let (unsuspendResult, unsuspendMessage) = await tutorMgmtVM.unsuspendTutor(tutorIndex: items, referenceData: referenceData)
									if unsuspendResult == false {
										showAlert = true
										buttonErrorMsg = unsuspendMessage
									}
								}
							} label: {
								Label("UnSuspend Tutor", systemImage: "trash")
							}
							
							Button(role: .destructive) {
								Task {
									let (deleteResult, deleteMessage) = await tutorMgmtVM.deleteTutor(indexes: items, referenceData: referenceData)
									
									if deleteResult == false {
										showAlert = true
										buttonErrorMsg = deleteMessage
									}
								}
							} label: {
								Label("Delete Tutor", systemImage: "trash")
							}
						}
						
					} else {
						Button {
							
						} label: {
							Label("Edit Tutors", systemImage: "heart")
						}
						
						Button(role: .destructive) {
							Task {
								let (deleteResult, deleteMessage) = await tutorMgmtVM.deleteTutor(indexes: items, referenceData: referenceData)
							}
						} label: {
							Label("Delete Tutors", systemImage: "trash")
						}
					}
				} primaryAction: { items in
					//              store.favourite(items)
				}
			}
			.navigationTitle("Tutors List")
			
			.alert(buttonErrorMsg, isPresented: $showAlert) {
				Button("OK", role: .cancel) { }
			}
			
			// A single item-driven destination replaces the previous five
			// `.navigationDestination(isPresented:)` modifiers. Each case looks
			// the tutor up fresh by its stable ID, so the destination can never
			// end up pointing at a stale or wrong index.
			.navigationDestination(item: $activeDestination) { destination in
				switch destination {
						
					case .assignStudent(let tutorID):
						StudentSelectionView(tutorNum: indexBinding(for: tutorID), referenceData: referenceData)
						
					case .listStudents(let tutorID):
						// Only show if this tutor's details have actually loaded —
						// same guard the original code had.
						if let tutor = referenceData.tutors.tutorsList.first(where: { $0.id == tutorID }),
						   tutor.tutorDetailsLoaded {
							TutorStudentsView(tutorNum: indexBinding(for: tutorID), referenceData: referenceData)
						}
						
					case .listServices(let tutorID):
						if let tutor = referenceData.tutors.tutorsList.first(where: { $0.id == tutorID }),
						   tutor.tutorDetailsLoaded {
							TutorServicesView(tutorNum: indexBinding(for: tutorID), referenceData: referenceData)
						}
						
					case .assignService(let tutorID):
						ServiceSelectionView(tutorNum: indexBinding(for: tutorID), referenceData: referenceData)
						
					case .unassignService(let tutorID):
						TutorServiceListSelectionView(tutorNum: indexBinding(for: tutorID), referenceData: referenceData)
						
					case .editTutor(let tutorID):
						if let idx = referenceData.tutors.tutorsList.firstIndex(where: { $0.id == tutorID }) {
							let tutor = referenceData.tutors.tutorsList[idx]
							TutorView(
								updateTutorFlag: true,
								tutorNum: idx,
								originalTutorName: tutor.tutorName,
								referenceData: referenceData,
								tutorName: tutor.tutorName,
								tutorEmail: tutor.tutorEmail,
								tutorPhone: tutor.tutorPhone,
								maxStudents: tutor.tutorMaxStudents,
								tutorType: tutor.tutorType
							)
						}
				}
			}
		}
	}
	
	/// Checks whether the given tutor's details are already loaded. If so,
	/// navigates immediately. If not, calls `ReferenceData.ensureTutorDetailsLoaded`
	/// first and only navigates once loading finishes successfully — so a click on
	/// an unloaded tutor never pushes a blank screen and never has to be tapped
	/// twice.
	///
	/// - Parameters:
	///   - tutorID: the tutor to show details for.
	///   - destination: which `TutorDestination` case to navigate to once
	///     details are available (e.g. `TutorDestination.listStudents` or
	///     `TutorDestination.listServices`).
	private func showTutorDetails(for tutorID: Tutor.ID, destination: @escaping (Tutor.ID) -> TutorDestination) async {
		guard let tutor = referenceData.tutors.tutorsList.first(where: { $0.id == tutorID }) else {
			return
		}

		if tutor.tutorDetailsLoaded {
			activeDestination = destination(tutorID)
			return
		}

		isLoadingTutorDetails = true
		let success = await referenceData.ensureTutorDetailsLoaded(tutorID: tutorID)
		isLoadingTutorDetails = false

		if success {
			activeDestination = destination(tutorID)
		} else {
			buttonErrorMsg = "Could not load details for \(tutor.tutorName)."
			showAlert = true
		}
	}
	
	/// Builds a `Binding<Int>` for a tutor's current array index, resolved
	/// fresh from its stable `Tutor.ID` every time the binding is read. This
	/// keeps the existing child-view signatures (`tutorNum: Binding<Int>`)
	/// working unchanged, while eliminating the old bug where an `Int` index
	/// captured at button-tap time could go stale (e.g. if the list is
	/// resorted, filtered, or mutated before the destination view reads it).
	///
	/// The setter is a no-op — none of the destination views were observed to
	/// write back into `tutorNumber` in the original code. If one of them
	/// does need to change which tutor is active, wire this setter to look up
	/// the tutor by the new index and update `activeDestination` accordingly.
	private func indexBinding(for tutorID: Tutor.ID) -> Binding<Int> {
		Binding(
			get: {
				referenceData.tutors.tutorsList.firstIndex(where: { $0.id == tutorID }) ?? 0
			},
			set: { _ in
				// See doc comment above — currently unused by callers.
			}
		)
	}
}
