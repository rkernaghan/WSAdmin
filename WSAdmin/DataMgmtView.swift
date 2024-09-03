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

class StudentData {
    var studentKey: String
    var studentName: String
    var studentGuardian: String
    var studentPhone: String
    var studentEmail: String
    var studentType: String
    var studentStartDate: Date
    var studentEndData: Date
    var studentStatus: String
    var studentTutorKey: String
    var studentTutorName: String
    var studentCity: String
    var studentSessions: Int
    var studentTotalCost: Float
    var studentTotalPrice: Float
    var studentTotalProfit: Float
    
    init(studentKey: String, studentName: String, studentGuardian: String, studentPhone: String, studentEmail: String, studentType: String, studentStartDate: Date, studentEndData: Date, studentStatus: String, studentTutorKey: String, studentTutorName: String, studentCity: String, studentSessions: Int, studentTotalCost: Float, studentTotalPrice: Float, studentTotalProfit: Float) {
        self.studentKey = studentKey
        self.studentName = studentName
        self.studentGuardian = studentGuardian
        self.studentPhone = studentPhone
        self.studentEmail = studentEmail
        self.studentType = studentType
        self.studentStartDate = studentStartDate
        self.studentEndData = studentEndData
        self.studentStatus = studentStatus
        self.studentTutorKey = studentTutorKey
        self.studentTutorName = studentTutorName
        self.studentCity = studentCity
        self.studentSessions = studentSessions
        self.studentTotalCost = studentTotalCost
        self.studentTotalPrice = studentTotalPrice
        self.studentTotalProfit = studentTotalProfit
    }
}

class TutorData {
    var tutorKey: String
    var tutorName: String
    var tutorEmail: String
    var tutorPhone: String
    var tutorStatus: String
    var tutorStartDate: Date
    var tutorEndDate: Date
    var tutorStudentCount: Int
    var tutorServiceCount: Int
    var tutorTotalSessions: Int
    var tutorTotalCost: Float
    var tutorTotalPrice: Float
    var tutorTotalProfit: Float
    
    init(tutorKey: String, tutorName: String, tutorEmail: String, tutorPhone: String, tutorStatus: String, tutorStartDate: Date, tutorEndDate: Date, tutorStudentCount: Int, tutorServiceCount: Int, tutorTotalSessions: Int, tutorTotalCost: Float, tutorTotalPrice: Float, tutorTotalProfit: Float) {
        self.tutorKey = tutorKey
        self.tutorName = tutorName
        self.tutorEmail = tutorEmail
        self.tutorPhone = tutorPhone
        self.tutorStatus = tutorStatus
        self.tutorStartDate = tutorStartDate
        self.tutorEndDate = tutorEndDate
        self.tutorStudentCount = tutorStudentCount
        self.tutorServiceCount = tutorServiceCount
        self.tutorTotalSessions = tutorTotalSessions
        self.tutorTotalCost = tutorTotalCost
        self.tutorTotalPrice = tutorTotalPrice
        self.tutorTotalProfit = tutorTotalProfit
    }
}

enum ServiceTypes {
    case base
    case special
}

enum BillingTypes {
    case fixed
    case Variable
}

class ServiceData {
    var serviceKey: String
    var serviceTimesheetName: String
    var serviceInvoiceName: String
    var serviceType: ServiceTypes
    var serviceBillingType: BillingTypes
    var serviceStatus: String
    var serviceCost1: Float
    var serviceCost2: Float
    var serviceCost3: Float
    var servicePrice1: Float
    var servicePrice2: Float
    var servicePrice3: Float
    
    init(serviceKey: String, serviceTimesheetName: String, serviceInvoiceName: String, serviceType: ServiceTypes, serviceBillingType: BillingTypes, serviceStatus: String, serviceCost1: Float, serviceCost2: Float, serviceCost3: Float, servicePrice1: Float, servicePrice2: Float, servicePrice3: Float) {
        self.serviceKey = serviceKey
        self.serviceTimesheetName = serviceTimesheetName
        self.serviceInvoiceName = serviceInvoiceName
        self.serviceType = serviceType
        self.serviceBillingType = serviceBillingType
        self.serviceStatus = serviceStatus
        self.serviceCost1 = serviceCost1
        self.serviceCost2 = serviceCost2
        self.serviceCost3 = serviceCost3
        self.servicePrice1 = servicePrice1
        self.servicePrice2 = servicePrice2
        self.servicePrice3 = servicePrice3
    }
}

class CityData {
    var cityKey: String
    var cityName: String
    var cityMonthRevenue: Float
    var cityTotalRevenue: Float
    
    init(cityKey: String, cityName: String, cityMonthRevenue: Float, cityTotalRevenue: Float) {
        self.cityKey = cityKey
        self.cityName = cityName
        self.cityMonthRevenue = cityMonthRevenue
        self.cityTotalRevenue = cityTotalRevenue
    }
}

class ReferenceData {
    var tutorList = [TutorData]()
    var studentList = [StudentData]()
    var serviceList = [ServiceData]()
    var cityList = [CityData]()
    
}

struct DataMgmtView: View {
    let options: [Option] = [
        .init(title: "Home", imageName: "house"),
        .init(title: "Tutors", imageName: "person"),
        .init(title: "Students", imageName: "graduationcap"),
        .init(title: "Services", imageName: "list.bullet"),
        .init(title: "cities", imageName: "building"),
        .init(title: "billing", imageName: "dollarsign")
    ]
    @Environment(RefDataModel.self) var refDataModel: RefDataModel
    
    var body: some View {
        NavigationView {
            SideView(options: options)
            
            MainView()
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: {
            print("Start OnAppear")
            let refDataFileName = "ReferenceData - TEST"
            refDataModel.readRefData(fileName: refDataFileName)
            })
    }
}

struct SideView: View {
    let options: [Option]
    
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
            }
        }
    }
}

struct MainView: View {
    var body: some View {
        Text("Hello Russell")
    }
}

#Preview {
    DataMgmtView()
}
