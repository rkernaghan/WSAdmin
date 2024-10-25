//
//  BillClients.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-10-24.
//

class BillClient {
    
    var clientName: String
    var clientEmail: String
    var clientPhone: String
    var billItems = [BillItem]()
    
    init(clientName: String, clientEmail: String, clientPhone: String) {
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.clientPhone = clientPhone
    }
}
