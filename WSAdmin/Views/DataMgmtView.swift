//
//  DataMgmtView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-02.
//
import Foundation
import SwiftUI

struct Option: Hashable {
    let title: String
    let imageName: String
}

class FileData {
    var fileID: String = " "
    var testTutorBillingFile: String = " "
    var testStudentBillingFile: String = " "
    
    var prodTutorBillingFile: String = " "
    var prodStudentBillingFile: String = " "
    }

class DataCounts {
    var totalStudents: Int = 0
    var activeStudents: Int = 0
    var highestStudentKey: Int = 0
    var totalTutors: Int = 0
    var activeTutors: Int = 0
    var highestTutorKey: Int = 0
    var totalServices: Int = 0
    var activeServices: Int = 0
    var highestServiceKey: Int = 0
    var totalLocations: Int = 0
    var highestLocationKey: Int = 0
}


enum ServiceTypes {
    case Base
    case Special
}

enum BillingTypes {
    case Fixed
    case Variable
}

class ReferenceData {
    var tutors = TutorsList()
    var students = StudentsList()
    var services = ServicesList()
    var locations = LocationsList()
}

struct DataMgmtView: View {

    @Environment(RefDataVM.self) var refDataVM: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var fileIDs = FileData()
    var dataCounts = DataCounts()
    var referenceData = ReferenceData()
    
    var body: some View {
        NavigationView {
            SideView(referenceData: referenceData)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: {
            print("Start OnAppear")
 //           let refDataFileName = PgmConstants.prodRefFileName
            let refDataFileName = PgmConstants.testRefFileName
            refDataVM.readRefData(fileName: refDataFileName, fileIDs: fileIDs, dataCounts: dataCounts, referenceData: referenceData)
            })
    }
}

struct SideView: View {
    var referenceData: ReferenceData
    @Environment(UserAuthVM.self) var userAuthVM: UserAuthVM
        
    var body: some View {
            
            List {
               
                NavigationLink {
                    TutorsView(referenceData: referenceData)
                } label: {
                  Label("Tutors", systemImage: "person")
                }
                
                NavigationLink {
                    StudentsView(referenceData: referenceData)
                } label: {
                  Label("Students", systemImage: "graduationcap")
                }
                
                NavigationLink {
                    ServicesView(referenceData: referenceData)
                } label: {
                  Label("Services", systemImage: "list.bullet")
                }
                
                NavigationLink {
                    LocationsView(referenceData: referenceData)
                } label: {
                  Label("Locations", systemImage: "building")
                }
                
                NavigationLink {
                    AddTutor(referenceData: referenceData, tutorName: " ", maxStudents: " ", contactPhone: " ", contactEmail: " ")
                } label: {
                  Label("Add Tutor", systemImage: "person")
                }
                
                NavigationLink {
                    AddStudent(referenceData: referenceData, studentName: " ", guardianName: " ", contactPhone: " ", contactEmail: " ")
                } label: {
                  Label("Add Student", systemImage: "graduationcap")
                }
                
                NavigationLink {
                    AddService(referenceData: referenceData, timesheetName: " ", invoiceName: " ", serviceType: " ", billingType: " ")
                } label: {
                  Label("Add Service", systemImage: "list.bullet")
                }
                
                NavigationLink {
                    AddLocation(referenceData: referenceData, locationName: " ")
                } label: {
                  Label("Add Location", systemImage: "building")
                
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Sidebar")
            
            Button(action: {
                userAuthVM.signOut()
                //                dismiss() }) {
            }) {
                    Text("Sign Out")
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct TutorsView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataVM.self) var refDataModel: RefDataVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @State private var selectedTutors = Set<Tutor.ID>()
        
    var body: some View {
        if refDataModel.isTutorDataLoaded {
            NavigationView {
                
                Table(referenceData.tutors.tutorsList, selection: $selectedTutors) {
                    TableColumn("Tutor Name", value: \.tutorName)
                    TableColumn("Phone", value: \.tutorPhone)
                    TableColumn("Email", value: \.tutorEmail)
                    //               TableColumn("Start Date") { student in
                    //                   Text(referenceData.studentsList.studentsList.studentStartDate, style: .date) }
                    //               TableColumn("End Date", value: \.studentEndData)
                    TableColumn("Status", value: \.tutorStatus)
                    //               TableColumn("Tutor Key", value: \.studentTutorKey)
                    //               TableColumn("Tutor Name", value: \.studentTutorName)
                    //               TableColumn("Sessions", value: \.studentSessions)
                    //               TableColumn("Total Cost", value: \.studentTotalCost)
                    //               TableColumn("Total Revenue", value: \.studentTotalPrice)
                    //               TableColumn("Total Profit", value: \.studentTotalProfit)
                }
                .contextMenu(forSelectionType: Tutor.ID.self) { items in
                    if items.isEmpty {
                        Button {
                            
                        } label: {
                            Label("New Tutor", systemImage: "plus")
                        }
                    } else if items.count == 1 {
                        VStack {
                            NavigationLink(destination: TutorStudentsView(referenceData: referenceData, tutorIndex: items)) {
                                Text("List Students")
                                Image(systemName: "square.and.pencil")
                            }
                            
                            //                   NavigationLink(destination: SegmentsEditView(timelineItem: visit)) {
                            //                            Text("Edit individual segments")
                            //                            Image(systemName: "ellipsis")
                            //                        }
                            
                            Button {
                                tutorMgmtVM.listTutorStudents(indexes: items, referenceData: referenceData)
                            } label: {
                                Label("List Tutor Students", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                TutorStudentsView(referenceData: referenceData, tutorIndex: items)
                                
                            } label: {
                                Label("List Tutor Costs", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                
                            } label: {
                                Label("Edit Tutor", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                
                            } label: {
                                Label("Assign Tutor", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(role: .destructive) {
                                tutorMgmtVM.deleteTutor(indexes: items, referenceData: referenceData)
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
                            
                        } label: {
                            Label("Delete Tutors", systemImage: "trash")
                        }
                    }
                } primaryAction: { items in
                    //              store.favourite(items)
                }
            }
        }
    }
}

struct TutorStudentsView: View {
    var referenceData: ReferenceData
    var tutorIndex: Set<Tutor.ID>
    
    var body: some View {
        
//        for objectID in tutorIndex {
//            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == tutorIndex} ) {
                Table(referenceData.tutors.tutorsList[0].tutorStudents) {
                    TableColumn("Student Name", value: \.studentName)
                    TableColumn("Phone", value: \.clientName)
                    TableColumn("Email", value: \.clientEmail)
                    TableColumn("Status", value: \.clientPhone)
                }
            }
//        }
//    }
}

struct StudentsView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataVM.self) var refDataModel: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    @State private var selectedStudents = Set<Student.ID>()
    
    var body: some View {
        if refDataModel.isStudentDataLoaded {
            
            Table(referenceData.students.studentsList, selection: $selectedStudents) {
                TableColumn("Student Name", value: \.studentName)
                TableColumn("Guardian", value: \.studentGuardian)
                TableColumn("Phone", value: \.studentPhone)
                TableColumn("Phone", value: \.studentGuardian)
                TableColumn("Phone", value: \.studentPhone)
                TableColumn("Email", value: \.studentEmail)
                //             TableColumn("Email", value: \.studentEmail) { student in
                //                 Text(referenceData.studentsList.studentsList[].studentEmail) }
                TableColumn("Type", value: \.studentType)
                //               TableColumn("Start Date") { student in
                //                   Text(referenceData.studentsList.studentsList.studentStartDate, style: .date) }
                //               TableColumn("End Date", value: \.studentEndData)
                TableColumn("Status", value: \.studentStatus)
                //               TableColumn("Tutor Key", value: \.studentTutorKey)
                //               TableColumn("Tutor Name", value: \.studentTutorName)
                TableColumn("Location", value: \.studentLocation)
                //               TableColumn("Sessions", value: \.studentSessions)
                //               TableColumn("Total Cost", value: \.studentTotalCost)
                //               TableColumn("Total Revenue", value: \.studentTotalPrice)
                //               TableColumn("Total Profit", value: \.studentTotalProfit)
            }
            .contextMenu(forSelectionType: Student.ID.self) { items in
                if items.isEmpty {
                    Button { } label: {
                      Label("New Student", systemImage: "plus")
                    }
                } else if items.count == 1 {
                    Button {
                        
                    } label: {
                      Label("Edit Student", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        
                    } label: {
                      Label("Assign Student", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        
                    } label: {
                      Label("UnAssign Student", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        
                    } label: {
                      Label("ReAssign Student", systemImage: "square.and.arrow.up")
                    }
                    
                    
                    Button(role: .destructive) {
                        studentMgmtVM.deleteStudent(indexes: items, referenceData: referenceData)
                    } label: {
                      Label("Delete Student", systemImage: "trash")
                    }
                    
                } else {
                    Button {} label: {
                      Label("Edit Students", systemImage: "heart")
                    }
                    Button(role: .destructive) {} label: {
                      Label("Delete Students", systemImage: "trash")
                    }
                }
            } primaryAction: { items in
  //              store.favourite(items)
              }
        }
    }
}

struct ServicesView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataVM.self) var refDataModel: RefDataVM
    @Environment(ServiceMgmtVM.self) var serviceMgmtVM: ServiceMgmtVM
    @State private var selectedServices = Set<Service.ID>()
        
    var body: some View {
        if refDataModel.isServiceDataLoaded {
  
            Table(referenceData.services.servicesList, selection: $selectedServices) {
                TableColumn("Timesheet Name", value: \.serviceTimesheetName)
                TableColumn("Invoice Name", value: \.serviceInvoiceName)
                TableColumn("Service Type", value: \.serviceType)
                TableColumn("Billing Type", value: \.serviceBillingType)
                TableColumn("Service Status", value: \.serviceStatus)
 //               TableColumn("Cost 1", value: \.serviceCost1)
//               TableColumn("Cost 2", value: \.serviceCost2)
//               TableColumn("Cost 3", value: \.serviceCost3)
 //               TableColumn("Price 1", value: \.servicePrice1)
//               TableColumn("Price 2", value: \.servicePrice2)
//               TableColumn("Price 3", value: \.servicePrice3)
            }
            .contextMenu(forSelectionType: Service.ID.self) { items in
                if items.isEmpty {
                    Button {
   //                     AddService(referenceData: referenceData, timesheetName: " ", invoiceName: " ", serviceType: " ", billingType: " ")
                    } label: {
                      Label("New Service", systemImage: "plus")
                    }
                } else if items.count == 1 {
                    Button {
                        
                    } label: {
                      Label("Edit Service", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        serviceMgmtVM.deleteService(indexes: items, referenceData: referenceData)
                    } label: {
                      Label("Delete Service", systemImage: "trash")
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
        }
    }
}

struct LocationsView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataVM.self) var refDataModel: RefDataVM
    @Environment(LocationMgmtVM.self) var locationMgmtVM: LocationMgmtVM
    @State private var selectedLocation = Set<Location.ID>()
        
    var body: some View {
        if refDataModel.isLocationDataLoaded {
  
            Table(referenceData.locations.locationsList, selection: $selectedLocation) {
                TableColumn("Location Name", value: \.locationName)
  
//               TableColumn("Location Month Revenue", value: \.locationMonthRevenue)
//               TableColumn("Location Total Revenue", value: \.locationTotalRevenue)
            }
            .contextMenu(forSelectionType: Location.ID.self) { items in
                if items.isEmpty {
                    Button {
  //                      let result = AddLocation(referenceData: referenceData, locationName: " ", locationMonthRevenue: 0.0, locationTotalRevenue: 0.0)
                    } label: {
                      Label("New Service", systemImage: "plus")
                    }
                } else if items.count == 1 {
                    Button {
                        
                    } label: {
                      Label("Edit Service", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        locationMgmtVM.deleteLocation(indexes: items, referenceData: referenceData)
                    } label: {
                      Label("Delete Service", systemImage: "trash")
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
        }
    }
}

struct MainView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataVM.self) var refDataVM: RefDataVM
        
    var body: some View {
       
        Text(" Main View")
    }
}

#Preview {
    DataMgmtView()
}
