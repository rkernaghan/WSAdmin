//
//  FinanceSummary.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2024-12-11.
//
import Foundation
import SwiftUI

struct FinanceSummary: View {
	
	var financeSummaryArray: [FinanceSummaryRow]
	
	var body: some View {
		VStack {
			Table(financeSummaryArray) {
				TableColumn("Year", value: \.year)
					.width(min: 30, ideal: 40, max: 50)
				
				TableColumn("Month", value: \.month)
					.width(min: 30, ideal: 40, max: 50)

				TableColumn("Active\nTutors") {data in
					Text(String(data.activeTutorsForMonth))
						.frame(maxWidth: .infinity, alignment: .trailing)
					     }
					.width(min: 30, ideal: 40, max: 50)

				TableColumn("Billed\nTutors") { data in
					Text(String(data.billedTutorsForMonth))
						.frame(maxWidth: .infinity, alignment: .trailing)
				}
					.width(min: 30, ideal: 40, max: 50)
				
				TableColumn("Month\nSessions") {data in
					Text(String(data.monthSessions))
						.frame(maxWidth: .infinity, alignment: .trailing)
				}
					.width(min: 30, ideal: 40, max: 60)
				
				TableColumn("Month\nProfit") {data in
					Text(String(data.monthProfit.formatted(.number.precision(.fractionLength(0)))))
						.frame(maxWidth: .infinity, alignment: .trailing)
				}
					.width(min: 35, ideal: 45, max: 60)

				TableColumn("Year\nSessions") {data in
					Text(String(data.yearSessions))
						.frame(maxWidth: .infinity, alignment: .trailing)
				}
					.width(min: 30, ideal: 40, max: 60)
				
				TableColumn("Year\nProfit") {data in
					Text(String(data.yearProfit.formatted(.number.precision(.fractionLength(0)))))
						.frame(maxWidth: .infinity, alignment: .trailing)
				}
				.width(min: 35, ideal: 50, max: 60)

				TableColumn("Total\nSessions") {data in
					Text(String(data.totalSessions))
						.frame(maxWidth: .infinity, alignment: .trailing)
				}
					.width(min: 30, ideal: 40, max: 60)
				
				TableColumn("Total\nProfit") {data in
					Text(String(data.totalProfit.formatted(.number.precision(.fractionLength(0)))))
						.frame(maxWidth: .infinity, alignment: .trailing)
				}
				.width(min: 35, ideal: 45, max: 60)

			}
		}
		
	}
}

// #Preview {
//    TutorStudentsView()
// }

