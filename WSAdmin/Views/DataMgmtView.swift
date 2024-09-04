//
//  DataMgmtView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-02.
//

import SwiftUI

struct Option: Hashable {
    let title: String
    let imageName: String
}

class FileData {
    var referenceDataFile: String = " "
    var tutorDataFile: String = " "
    var tutorBillingFile: String = " "
    var studentBillingFile: String = " "
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
    var totalCities: Int = 0
    var highestCityKey: Int = 0
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
    var cities = CitiesList()
}

struct DataMgmtView: View {
    @State var currentOption = 0
    let options: [Option] = [
        .init(title: "Home", imageName: "house"),
        .init(title: "Tutors", imageName: "person"),
        .init(title: "Students", imageName: "graduationcap"),
        .init(title: "Services", imageName: "list.bullet"),
        .init(title: "cities", imageName: "building"),
        .init(title: "billing", imageName: "dollarsign")
    ]
    @Environment(RefDataModel.self) var refDataModel: RefDataModel
    
    var fileIDs = FileData()
    var dataCounts = DataCounts()
    var referenceData = ReferenceData()
    
    var body: some View {
        NavigationView {
            SideView(options: options, currentSelection: $currentOption)
            
            switch currentOption {
            case 0:
                TutorsView(referenceData: referenceData)
            case 1:
                StudentsView(referenceData: referenceData)
            case 2:
                ServicesView(referenceData: referenceData)
            case 3:
                CitiesView(referenceData: referenceData)
            default:
               MainView(referenceData: referenceData)
            }
                
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: {
            print("Start OnAppear")
            let refDataFileName = "ReferenceData - TEST"
            refDataModel.readRefData(fileName: refDataFileName, fileIDs: fileIDs, dataCounts: dataCounts, referenceData: referenceData)
            })
    }
}

struct SideView: View {
    let options: [Option]
    @Binding var currentSelection: Int
    
    var body: some View {
        VStack {
            ForEach(options, id:\.self) {option in
                HStack {
                    Image(systemName: option.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                    
                    Text(option.title)
                    
                    Spacer()
                }
                .padding()
                .onTapGesture {
                    self.currentSelection = 2                }
            }
        }
    }
}

struct TutorsView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataModel.self) var refDataModel: RefDataModel
        
    var body: some View {
        if refDataModel.isTutorDataLoaded {
  
            Table(referenceData.tutors.tutorsList) {
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
        }
    }
}

struct StudentsView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataModel.self) var refDataModel: RefDataModel
        
    var body: some View {
        if refDataModel.isStudentDataLoaded {
  
            Table(referenceData.students.studentsList) {
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
                TableColumn("Location", value: \.studentCity)
 //               TableColumn("Sessions", value: \.studentSessions)
 //               TableColumn("Total Cost", value: \.studentTotalCost)
 //               TableColumn("Total Revenue", value: \.studentTotalPrice)
 //               TableColumn("Total Profit", value: \.studentTotalProfit)
            }
        }
    }
}

struct ServicesView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataModel.self) var refDataModel: RefDataModel
        
    var body: some View {
        if refDataModel.isServiceDataLoaded {
  
            Table(referenceData.services.servicesList) {
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
        }
    }
}

struct CitiesView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataModel.self) var refDataModel: RefDataModel
        
    var body: some View {
        if refDataModel.isCityDataLoaded {
  
            Table(referenceData.cities.citiesList) {
                TableColumn("Location Name", value: \.cityName)
  
//               TableColumn("Location Month Revenue", value: \.cityMonthRevenue)
//               TableColumn("Location Total Revenue", value: \.cityTotalRevenue)

            }
        }
    }
}

struct MainView: View {
    var referenceData: ReferenceData
    
    @Environment(RefDataModel.self) var refDataModel: RefDataModel
        
    var body: some View {
       
        Text(" Main View")
    }
}

#Preview {
    DataMgmtView()
}
