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

struct DataMgmtView: View {
    let options: [Option] = [
        .init(title: "Home", imageName: "house"),
        .init(title: "Tutors", imageName: "person"),
        .init(title: "Students", imageName: "graduationcap"),
        .init(title: "Services", imageName: "list.bullet"),
        .init(title: "cities", imageName: "building"),
        .init(title: "billing", imageName: "dollarsign")
    ]
    
    var body: some View {
        NavigationView {
            SideView(options: options)
            
            MainView()
        }
        .frame(minWidth: 600, minHeight: 400)
        
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
