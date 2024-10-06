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
    @State var referenceData = ReferenceData()
    
    var body: some View {

            SideView(referenceData: referenceData)

        .frame(minWidth: 100, minHeight: 100)
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
 //       NavigationStack {
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
                    TutorView(updateTutorFlag: false, tutorNum: 0, referenceData: referenceData, tutorName: " ", contactEmail: " ", contactPhone: " ", maxStudents: 0)
                } label: {
                    Label("Add Tutor", systemImage: "person")
                }
                
                NavigationLink {
                    StudentView(updateStudentFlag: false, referenceData: referenceData, studentKey: " ", studentName: " ", guardianName: " ", contactPhone: " ", contactEmail: " ", location: " ", studentType: .Minor)
                } label: {
                    Label("Add Student", systemImage: "graduationcap")
                }
                
                NavigationLink {
                    ServiceView(updateServiceFlag: false, serviceNum: 0, referenceData: referenceData, serviceKey: " ", timesheetName: " ", invoiceName: " ", serviceType: .Base, billingType: .Fixed, cost1: 0.0, cost2: 0.0, cost3: 0.0, price1: 0.0, price2: 0.0, price3: 0.0 )
                } label: {
                    Label("Add Service", systemImage: "list.bullet")
                }
                
                NavigationLink {
                    LocationView(updateLocationFlag: false, locationNum: 0, referenceData: referenceData, locationName: " ")
                } label: {
                    Label("Add Location", systemImage: "building")
                }
            }
//            .listStyle(SidebarListStyle())
            .navigationTitle("Sidebar")
            
           Button(action: {
                userAuthVM.signOut()
                //                dismiss() }) {
            }) {
                Text("Sign Out")
            }
            .padding()
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
//    }
}

struct TutorsView: View {
    @State var referenceData: ReferenceData
    
    @State private var selectedTutors: Set<Tutor.ID> = []
    @State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
    @State private var showAlert: Bool = false
    @State private var viewChange: Bool = false
    @State private var assignStudent:Bool = false
    @State private var unassignStudent: Bool = false
    @State private var listTutorStudents: Bool = false
    @State private var listTutorServices: Bool = false
    @State private var addService: Bool = false
    @State private var editService: Bool = false
    @State private var removeService: Bool = false
    @State private var editTutor: Bool = false
    
    @State private var tutorNumber: Int = 0
    @State private var showDeleted: Bool = false
    
    @Environment(RefDataVM.self) var refDataModel: RefDataVM
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    var body: some View {
        if referenceData.tutors.isTutorDataLoaded {

            var tutorArray: [Tutor] {
                if showDeleted {
                    return referenceData.tutors.tutorsList
                } else {
                    return referenceData.tutors.tutorsList.filter{$0.tutorStatus != "Deleted"}
                }
            }

            VStack {
                Toggle("Show Deleted", isOn: $showDeleted)
 
                Table(tutorArray,selection: $selectedTutors, sortOrder: $sortOrder) {
                    TableColumn("Tutor Name", value: \.tutorName)
                    TableColumn("Phone", value: \.tutorPhone)
                    TableColumn("Email", value: \.tutorEmail)
                    TableColumn("Start Date", value: \.tutorStartDate)
                    TableColumn("End Date", value: \.tutorEndDate)
                    TableColumn("Status", value: \.tutorStatus)
                    TableColumn("Max Students", value: \.tutorMaxStudents) { data in
                        Text(String(data.tutorMaxStudents))
                    }
                    TableColumn("Student Count", value: \.tutorStudentCount) {data in
                        Text(String(data.tutorStudentCount))
                    }
                    TableColumn("Service Count", value: \.tutorServiceCount) {data in
                        Text(String(data.tutorServiceCount))
                    }
                    //                    TableColumn("Total Cost", value: \.tutorTotalCost)
                    //                    TableColumn("Total Revenue", value: \.tutorTotalRevenue)
  //                  TableColumn("Total Profit", value: \.tutorTotalProfit) { data in
  //                      Text(String(data.tutorTotalProfit.formatted(.number.precision(.fractionLength(2)))))
  //                  }
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
                                for objectID in items {
                                    if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                                        tutorNumber = idx
                                        assignStudent = true
                                    }
                                }
                            }
                            
                            Button("Unassign Student from Tutor") {
                                self.unassignStudent.toggle()
                            }
                            
                            Button("List Tutor Students") {
                               for objectID in items {
                                    if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                                        tutorNumber = idx
                                        listTutorStudents.toggle()
                                    }
                                }
 //                               listStudents.toggle()
                            }
                            
                            Button("List Tutor Services") {
                                for objectID in items {
                                    if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                                        tutorNumber = idx
                                        listTutorServices.toggle()
                                    }
                                }
                            }
                            
 //                           Button("Add Service to Tutor") {
 //                               addService.toggle()
 //                           }
                            
                            Button("Edit Service Costs for Tutor") {
                                editService.toggle()
                            }
                            
                            Button("Remove Service from Tutor") {
                                removeService.toggle()
                            }

                            Button("Edit Tutor") {
                                for objectID in items {
                                    if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                                        tutorNumber = idx
                                        editTutor.toggle()
                                    }
                                }
                            }
                            
                            Button(role: .destructive) {
                                let result: Bool = tutorMgmtVM.deleteTutor(indexes: items, referenceData: referenceData)
                                if result == false {
                                    showAlert = true
                                    viewChange.toggle()
                                }
                            } label: {
                                Label("Delete Tutor", systemImage: "trash")
                            }
                            .alert(buttonErrorMsg, isPresented: $showAlert) {
                                Button("OK", role: .cancel) { }
                            }
                            
                            Button(role: .destructive) {
                                let result: Bool = tutorMgmtVM.unDeleteTutor(indexes: items, referenceData: referenceData)
                                if result == false {
                                    showAlert = true
                                    viewChange.toggle()
                                }
                            } label: {
                                Label("Undelete Tutor", systemImage: "trash")
                            }
                        }
                        
                    } else {
                        Button {
                            
                        } label: {
                            Label("Edit Tutors", systemImage: "heart")
                        }
                        
                        Button(role: .destructive) {
                            let result: Bool = tutorMgmtVM.deleteTutor(indexes: items, referenceData: referenceData)
                        } label: {
                            Label("Delete Tutors", systemImage: "trash")
                        }
                    }
                } primaryAction: { items in
                    //              store.favourite(items)
                }
            }
            .navigationDestination(isPresented: $assignStudent) {
                StudentSelectionView(tutorNum: $tutorNumber, referenceData: referenceData)
            }
            .navigationDestination(isPresented: $listTutorStudents) {
                TutorStudentsView(tutorNum: $tutorNumber, referenceData: referenceData)
            }
            .navigationDestination(isPresented: $listTutorServices) {
                TutorServicesView(tutorNum: $tutorNumber, referenceData: referenceData)
            }
            .navigationDestination(isPresented: $editTutor) {
                TutorView(updateTutorFlag: true, tutorNum: tutorNumber, referenceData: referenceData, tutorName: referenceData.tutors.tutorsList[tutorNumber].tutorName, contactEmail: referenceData.tutors.tutorsList[tutorNumber].tutorEmail, contactPhone: referenceData.tutors.tutorsList[tutorNumber].tutorPhone, maxStudents: referenceData.tutors.tutorsList[tutorNumber].tutorMaxStudents )
            }
        }
    }
}

struct TutorStudentsList: View {
    var referenceData: ReferenceData
    var tutorIndex: Set<Tutor.ID>
    
    var body: some View {
        
   //     for objectID in tutorIndex {
   //         if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == objectID} ) {
                Table(referenceData.tutors.tutorsList[0].tutorStudents) {
                    TableColumn("Student Name", value: \.studentName)
                    TableColumn("Phone", value: \.clientName)
                    TableColumn("Email", value: \.clientEmail)
                    TableColumn("Status", value: \.clientPhone)
                }
                
            }
        }
 //   }
// }


struct StudentSelectionView: View {
    @Binding var tutorNum: Int
    var referenceData: ReferenceData

    
    @Environment(TutorMgmtVM.self) var tutorMgmtVM: TutorMgmtVM
    
    @State private var selectedStudents = Set<Student.ID>()
    @State private var sortOrder = [KeyPathComparator(\Student.studentName)]
    @State private var showAlert = false
    @State private var viewChange: Bool = false

    var body: some View {
        
        //        for objectID in tutorIndex {
        //            if let idx = referenceData.tutors.tutorsList.firstIndex(where: {$0.id == tutorIndex} ) {
        VStack {
            Table(referenceData.students.studentsList.filter{$0.studentStatus != "Assigned"}, selection: $selectedStudents, sortOrder: $sortOrder) {
                
                TableColumn("Student Name", value: \.studentName)
                TableColumn("Status", value: \.studentStatus)
            }
            
            .contextMenu(forSelectionType: Tutor.ID.self) { items in
                if items.count == 1 {
                    VStack {
                        
                        Button {
                            tutorMgmtVM.assignStudent(studentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
                        } label: {
                            Label("Assign Student to Tutor", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } else {
                    Button {
                        tutorMgmtVM.assignStudent(studentIndex: items, tutorNum: tutorNum, referenceData: referenceData)
                    } label: {
                        Label("Assign Students to Tutor", systemImage: "square.and.arrow.up")
                    }
                }
                    
                } primaryAction: { items in
                    //              store.favourite(items)
                }
            }
        }
    }


struct StudentsView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataVM.self) var refDataModel: RefDataVM
    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    
    @State private var selectedStudents: Set<Student.ID> = []
    @State private var sortOrder = [KeyPathComparator(\Student.studentName)]
    @State private var showAlert = false
    var studentArray = [Student]()

    @State private var assignTutor = false
    @State private var unassignTutor = false
    @State private var editStudent = false
    @State private var showDeleted = false
    
    @State private var studentNumber: Int = 0
    
    var body: some View {
        if referenceData.students.isStudentDataLoaded {
            
            var studentArray: [Student] {
                if showDeleted {
                    return referenceData.students.studentsList
                } else {
                    return referenceData.students.studentsList.filter{$0.studentStatus != "Deleted"}
                }
            }
            
            VStack {
             
                Toggle("Show Deleted", isOn: $showDeleted)
                
                Table(studentArray, selection: $selectedStudents) {
                    //               Group {
                    TableColumn("Student Name", value: \Student.studentName)
                    TableColumn("Guardian", value: \Student.studentGuardian)
                    TableColumn("Phone", value: \Student.studentPhone)
                    TableColumn("EMail", value: \Student.studentEmail)
                    TableColumn("Student Type") {data in
                        Text(data.studentType.rawValue)
                    }
                    //             }
                    //           Group {
                    TableColumn("Start Date", value: \Student.studentStartDate)
                    TableColumn("End Date", value: \Student.studentEndDate)
                    TableColumn("Status", value: \Student.studentStatus)
                    //                   TableColumn("Tutor Key", value: \Student.studentTutorKey)
                    TableColumn("Tutor Name",value: \Student.studentTutorName)
                    TableColumn("Location", value: \Student.studentLocation)
//                  }
//                  TableColumn("Location", value: \.studentLocation)
//                  TableColumn("Sessions", value: \.studentSessions) {data in
//                  Text("\(data.studentTotalSessions)")
//                  }
//                  TableColumn("Total Cost", value: \.studentTotalCost)
//                  TableColumn("Total Revenue", value: \.studentTotalRevenue)
//                  TableColumn("Total Profit", value: \.studentTotalProfit)
//                  }
                }
                .contextMenu(forSelectionType: Student.ID.self) { items in
                    if items.isEmpty {
                        Button { } label: {
                            Label("New Student", systemImage: "plus")
                        }
                    } else if items.count == 1 {
                        VStack {

                            Button {
                                for objectID in items {
                                    if let idx = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                                        studentNumber = idx
                                        assignTutor.toggle()
                                    }
                                }
                            } label: {
                                Label("Assign Tutor to Student", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                studentMgmtVM.unassignStudent(studentIndex: items, referenceData: referenceData)
                            } label: {
                                Label("Unassign Student", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                for objectID in items {
                                    if let idx = referenceData.students.studentsList.firstIndex(where: {$0.id == objectID} ) {
                                        studentNumber = idx
                                        editStudent.toggle()
                                    }
                                }
                            } label: {
                                Label("Edit Student", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                
                            } label: {
                                Label("ReAssign Student", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(role: .destructive) {
                                let result: Bool = studentMgmtVM.deleteStudent(indexes: items, referenceData: referenceData)
                                if result == false {
                                    showAlert = true
                                }
                            } label: {
                                Label("Delete Student", systemImage: "trash")
                            }
                            .alert(buttonErrorMsg, isPresented: $showAlert) {
                                Button("OK", role: .cancel) { }
                            }
                            
                            Button(role: .destructive) {
                                let result: Bool = studentMgmtVM.undeleteStudent(indexes: items, referenceData: referenceData)
                                if result == false {
                                    showAlert = true
                                }
                            } label: {
                                Label("UnDelete Student", systemImage: "trash")
                            }
                            .alert(buttonErrorMsg, isPresented: $showAlert) {
                                Button("OK", role: .cancel) { }
                            }
                        }
                        
                    } else {
                        Button {} label: {
                            Label("Edit Students", systemImage: "heart")
                        }
                        
                        Button(role: .destructive) {} label: {
                            Label("Delete Students", systemImage: "trash")
                        }
                        
                        Button {
                            studentMgmtVM.unassignStudent(studentIndex: items, referenceData: referenceData)
                        } label: {
                            Label("Unassign Students", systemImage: "square.and.arrow.up")
                        }
                    }
                } primaryAction: { items in
                    //              store.favourite(items)
                }
                
            }
            .navigationDestination(isPresented: $assignTutor) {
                TutorSelectionView(studentNum: $studentNumber, referenceData: referenceData)
            }
            .navigationDestination(isPresented: $editStudent) {
                StudentView(updateStudentFlag: true, referenceData: referenceData, studentKey: referenceData.students.studentsList[studentNumber].studentKey, studentName: referenceData.students.studentsList[studentNumber].studentName, guardianName: referenceData.students.studentsList[studentNumber].studentGuardian, contactPhone: referenceData.students.studentsList[studentNumber].studentPhone, contactEmail: referenceData.students.studentsList[studentNumber].studentEmail, location: referenceData.students.studentsList[studentNumber].studentLocation,
                            studentType: referenceData.students.studentsList[studentNumber].studentType )
            }
        }
    }
}

struct TutorSelectionView: View {
    @Binding var studentNum: Int
    var referenceData: ReferenceData

    @Environment(StudentMgmtVM.self) var studentMgmtVM: StudentMgmtVM
    
    @State private var selectedTutor = Set<Tutor.ID>()
    @State private var sortOrder = [KeyPathComparator(\Tutor.tutorName)]
    @State private var showAlert = false
    @State private var viewChange: Bool = false

    var body: some View {
    
        VStack {
            Table(referenceData.tutors.tutorsList, selection: $selectedTutor, sortOrder: $sortOrder) {
                
                TableColumn("Tutor Name", value: \.tutorName)
                TableColumn("Tutor Status", value: \.tutorStatus)
            }
            
            .contextMenu(forSelectionType: Tutor.ID.self) { items in
                if items.count == 1 {
                    VStack {
                        
                        Button {
                            studentMgmtVM.assignStudent(studentNum: studentNum, tutorIndex: items, referenceData: referenceData)
                        } label: {
                            Label("Assign Tutor to Student", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } else {
                    Button {
                        studentMgmtVM.assignStudent(studentNum: studentNum, tutorIndex: items, referenceData: referenceData)
                    } label: {
                        Label("Assign Tutors Student", systemImage: "square.and.arrow.up")
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
    
    @State private var assignService: Bool = false
    @State private var editService: Bool = false
    @State private var showDeleted: Bool = false
    
    @State private var serviceNumber: Int = 0
//    @State private var serviceArray = [Service]()
    
    var body: some View {
        if referenceData.services.isServiceDataLoaded {

            var serviceArray: [Service] {
                if showDeleted {
                    return referenceData.services.servicesList
                } else {
                    return referenceData.services.servicesList.filter{$0.serviceStatus != "Deleted"}
                }
            }
 
            VStack {
                Toggle("Show Deleted", isOn: $showDeleted)
                
                
                Table(serviceArray, selection: $selectedServices, sortOrder: $sortOrder) {
                    //               Group {
                    TableColumn("Timesheet Name", value: \Service.serviceTimesheetName)
                    TableColumn("Invoice Name", value: \Service.serviceInvoiceName)
                    TableColumn("Service Type") {data in
                        Text(data.serviceType.rawValue)
                    }
                    TableColumn("Billing Type") {data in
                        Text(data.serviceBillingType.rawValue)
                    }
                    TableColumn("Service Status", value: \Service.serviceStatus)
                    
                    TableColumn("Cost 1") { data in
                        Text(String(data.serviceCost1.formatted(.number.precision(.fractionLength(2)))))
                    }

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
                                serviceMgmtVM.deleteService(indexes: items, referenceData: referenceData)
                            } label: {
                                Label("Delete Service", systemImage: "trash")
                            }
                            
                            Button(role: .destructive) {
                                let result = serviceMgmtVM.unDeleteService(indexes: items, referenceData: referenceData)
                            } label: {
                                Label("Undelete Service", systemImage: "trash")
                            }
                            
                            Button(role: .destructive) {
                                
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
                .navigationDestination(isPresented: $assignService) {
                    TutorServiceSelectionView(serviceNum: $serviceNumber, referenceData: referenceData)
                }
                .navigationDestination(isPresented: $editService) {
                    ServiceView(updateServiceFlag: true, serviceNum: serviceNumber, referenceData: referenceData, serviceKey: referenceData.services.servicesList[serviceNumber].serviceKey, timesheetName: referenceData.services.servicesList[serviceNumber].serviceTimesheetName, invoiceName:  referenceData.services.servicesList[serviceNumber].serviceInvoiceName, serviceType:  referenceData.services.servicesList[serviceNumber].serviceType, billingType:  referenceData.services.servicesList[serviceNumber].serviceBillingType, cost1:  referenceData.services.servicesList[serviceNumber].serviceCost1, cost2: referenceData.services.servicesList[serviceNumber].serviceCost2, cost3: referenceData.services.servicesList[serviceNumber].serviceCost3, price1: referenceData.services.servicesList[serviceNumber].servicePrice1, price2: referenceData.services.servicesList[serviceNumber].servicePrice2, price3: referenceData.services.servicesList[serviceNumber].servicePrice3)
                }
            }
        }
    }
}

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
                TableColumn("Tutor Status", value: \.tutorStatus)
            }
            
            .contextMenu(forSelectionType: Tutor.ID.self) { items in
                if items.count == 1 {
                    VStack {
                        
                        Button {
                            tutorMgmtVM.assignService(serviceNum: serviceNum, tutorIndex: items, referenceData: referenceData)
                        } label: {
                            Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } else {
                    Button {
                        tutorMgmtVM.assignService(serviceNum: serviceNum, tutorIndex: items, referenceData: referenceData)
                    } label: {
                        Label("Assign Service to Tutor", systemImage: "square.and.arrow.up")
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
    @State private var selectedLocations = Set<Location.ID>()
    @State private var sortOrder = [KeyPathComparator(\Location.locationName)]
    @State private var listStudents: Bool = false
    @State private var editLocation: Bool = false
    @State private var locationNumber: Int = 0
    @State private var showDeleted: Bool = false
    
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
                
                Table(locationArray, selection: $selectedLocations, sortOrder: $sortOrder) {
                    TableColumn("Location Name", value: \.locationName)
                    TableColumn("Student Count", value: \.locationStudentCount) {data in
                        Text(String(data.locationStudentCount))
                    }
                    TableColumn("Location Month Revenue", value: \Location.locationMonthRevenue) { data in
                        Text(String(data.locationMonthRevenue.formatted(.number.precision(.fractionLength(2)))))
                    }
                    TableColumn("Location Total Revenue", value: \Location.locationTotalRevenue) { data in
                        Text(String(data.locationTotalRevenue.formatted(.number.precision(.fractionLength(2)))))
                    }
                    TableColumn("Location Status", value: \.locationStatus)
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
                                for objectID in items {
                                    if let idx = referenceData.locations.locationsList.firstIndex(where: {$0.id == objectID} ) {
                                        locationNumber = idx
                                        editLocation.toggle()
                                    }
                                }
                            } label: {
                                Label("Edit Location", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(role: .destructive) {
                                locationMgmtVM.deleteLocation(indexes: items, referenceData: referenceData)
                            } label: {
                                Label("Delete Location", systemImage: "trash")
                            }
                            
                            Button(role: .destructive) {
                                locationMgmtVM.undeleteLocation(indexes: items, referenceData: referenceData)
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
                .navigationDestination(isPresented: $editLocation) {
                    LocationView(updateLocationFlag: true, locationNum: locationNumber, referenceData: referenceData, locationName: referenceData.locations.locationsList[locationNumber].locationName)
                }
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
