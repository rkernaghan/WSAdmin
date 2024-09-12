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
//    var fileID: String = " "
    var testTutorBillingFile: String = " "
    var testStudentBillingFile: String = " "
    
    var prodTutorBillingFile: String = " "
    var prodStudentBillingFile: String = " "
    }

// class DataCounts {
//    var totalStudents: Int = 0
//    var activeStudents: Int = 0
//    var highestStudentKey: Int = 0
//    var totalTutors: Int = 0
//    var activeTutors: Int = 0
//    var highestTutorKey: Int = 0
//    var totalServices: Int = 0
//    var activeServices: Int = 0
//    var highestServiceKey: Int = 0
//    var totalLocations: Int = 0
//    var highestLocationKey: Int = 0
// }


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
    var dataCounts = DataCounts()
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
            refDataVM.loadReferenceData(referenceData: referenceData)
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
                    AddStudent(referenceData: referenceData, studentName: " ", guardianName: " ", contactPhone: " ", contactEmail: " ", location: " ")
                } label: {
                  Label("Add Student", systemImage: "graduationcap")
                }
                
                NavigationLink {
                    AddService(referenceData: referenceData, timesheetName: " ", invoiceName: " ", serviceType: " ", billingType: " ", cost1: "0.0", cost2: "0.0", cost3: "0.0", price1: "0.0", price2: "0.0", price3: "0.0" )
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
 //               .background(Color.orange)
 //               .foregroundColor(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct TutorsView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataVM.self) var refDataModel: RefDataVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    @State private var selectedTutors = Set<Tutor.ID>()
    @State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
        
    var body: some View {
        if referenceData.tutors.isTutorDataLoaded {
            NavigationView {
                
                Table(referenceData.tutors.tutorsList, selection: $selectedTutors, sortOrder: $sortOrder) {
                    TableColumn("Tutor Name", value: \.tutorName)
                    TableColumn("Phone", value: \.tutorPhone)
                    TableColumn("Email", value: \.tutorEmail)
                    TableColumn("Start Date", value: \.tutorStartDate)
                    TableColumn("End Date", value: \.tutorEndDate)
                    TableColumn("Status", value: \.tutorStatus)
                    TableColumn("Tutor Key", value: \.tutorMaxStudents) { data in
                        Text(String(data.tutorMaxStudents))
                    }
                    TableColumn("Tutor Name", value: \.tutorStudentCount) {data in
                        Text(String(data.tutorStudentCount))
                    }
                    TableColumn("Sessions", value: \.tutorServiceCount) {data in
                        Text(String(data.tutorServiceCount))
                    }
//                    TableColumn("Total Cost", value: \.tutorTotalCost)
//                    TableColumn("Total Revenue", value: \.tutorTotalRevenue)
                    TableColumn("Total Profit", value: \.tutorTotalProfit) { data in
                        Text(String(data.tutorTotalProfit.formatted(.number.precision(.fractionLength(2)))))
                        }
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
    @State private var sortOrder = [KeyPathComparator(\Student.studentName)]
    var studentArray = [Student]()
    
    var body: some View {
        if referenceData.students.isStudentDataLoaded {
            let studentArray = referenceData.students.studentsList
            
            Table(studentArray, selection: $selectedStudents) {
 //               Group {
                    TableColumn("Student Name", value: \Student.studentName)
                    TableColumn("Guardian", value: \Student.studentGuardian)
                    TableColumn("Phone", value: \Student.studentPhone)
                    TableColumn("EMail", value: \Student.studentEmail)
                    TableColumn("Student Type", value: \Student.studentType)
   //             }
     //           Group {
                    TableColumn("Start Date", value: \Student.studentStartDate)
                    TableColumn("End Date", value: \Student.studentEndDate)
                    TableColumn("Status", value: \Student.studentStatus)
 //                   TableColumn("Tutor Key", value: \Student.studentTutorKey)
                    TableColumn("Tutor Name",value: \Student.studentTutorName)
                    TableColumn("Location", value: \Student.studentLocation)
             //       }
 //                   TableColumn("Location", value: \.studentLocation)
                    //                TableColumn("Sessions", value: \.studentSessions) {data in
                    //                    Text("\(data.studentTotalSessions)")
                    //                }
                    //                              TableColumn("Total Cost", value: \.studentTotalCost)
                    //                              TableColumn("Total Revenue", value: \.studentTotalRevenue)
                    //                              TableColumn("Total Profit", value: \.studentTotalProfit)
               // }
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
    @State private var sortOrder = [KeyPathComparator(\Service.serviceTimesheetName)]
    
    var body: some View {
        if referenceData.services.isServiceDataLoaded {
            let serviceArray = referenceData.services.servicesList

            Table(serviceArray, selection: $selectedServices, sortOrder: $sortOrder) {
 //               Group {
                    TableColumn("Timesheet Name", value: \Service.serviceTimesheetName)
                    TableColumn("Invoice Name", value: \Service.serviceInvoiceName)
                    TableColumn("Service Type", value: \Service.serviceType)
                    TableColumn("Billing Type", value: \Service.serviceBillingType)
                    TableColumn("Service Status", value: \Service.serviceStatus)
                    
                    TableColumn("Cost 1", value: \Service.serviceCost1) { data in
                        Text(String(data.serviceCost1.formatted(.number.precision(.fractionLength(2)))))
                    }
 //               }
 //               Group {
                    TableColumn("Cost 2", value: \Service.serviceCost2) { data in
                        Text(String(data.serviceCost2.formatted(.number.precision(.fractionLength(2)))))
                    }
                    TableColumn("Cost 3", value: \Service.serviceCost3) { data in
                        Text(String(data.serviceCost3.formatted(.number.precision(.fractionLength(2)))))
                    }
                    TableColumn("Price 1", value: \Service.servicePrice1) { data in
                        Text(String(data.servicePrice1.formatted(.number.precision(.fractionLength(2)))))
                    }
                    TableColumn("Price 2", value: \Service.servicePrice2) { data in
                        Text(String(data.servicePrice2.formatted(.number.precision(.fractionLength(2)))))
                    }
 //                   TableColumn("Price 3", value: \Service.servicePrice3) { data in
 //                       Text(String(data.servicePrice3.formatted(.number.precision(.fractionLength(2)))))
 //                   }
 //               }

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
        if referenceData.locations.isLocationDataLoaded {
  
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
