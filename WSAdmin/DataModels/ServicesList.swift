//
//  ServicesList.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-09-04.
//

import Foundation

class ServicesList {
    var servicesList = [Service]()
    
    func addService(newService: Service) {
        servicesList.append(newService)
    }
    
    func printAll() {
        for service in servicesList {
            print ("Service Name is \(service.serviceTimesheetName)")
        }
    }
    
}
