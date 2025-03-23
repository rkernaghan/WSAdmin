//
//  TutorAvailabilityView.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2025-03-21.
//

import SwiftUI

struct TutorAvailabilityView: View {

	var tutorAvailabilityArray: [TutorAvailabilityRow]
	
	
	var body: some View {
		
		VStack {
			
			
			Table(tutorAvailabilityArray) {
				Group {
					TableColumn("Tutor Name", value: \TutorAvailabilityRow.tutorName)
						.width(min: 70, ideal: 100, max: 170)
					
					TableColumn("Take\nMore", value: \.tutorAvailability)
						.width(min: 30, ideal: 40, max: 50)
					
					TableColumn("Student\nCount") {data in
						Text(String(data.tutorStudentCount))
							.frame(maxWidth: .infinity, alignment: .center)
					}
					.width(min: 30, ideal: 45, max: 60)
				}
				
				Group {
					TableColumn("Monday\nAvailability") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.mondayAvailability)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
					TableColumn("Monday\nLocation") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.mondayLocation)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)

				}
				
				Group {
					TableColumn("Tuesday\nAvailability") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.tuesdayAvailability)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
					TableColumn("Tuesday\nLocation") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.tuesdayLocation)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
				}
				
				Group {
					TableColumn("Wednesday\nAvailability") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.wednesdayAvailability)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
					TableColumn("Wednesday\nLocation") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.wednesdayLocation)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
				}
				
				Group {
					TableColumn("Thursday\nAvailability") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.thursdayAvailability)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
					TableColumn("Thursday\nLocation") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.thursdayLocation)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
				}
				
				Group {
					TableColumn("Friday\nAvailability") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.fridayAvailability)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
					TableColumn("Friday\nLocation") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.fridayLocation)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
				}
				
				Group {
					TableColumn("Saturday\nAvailability") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.saturdayAvailability)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
					TableColumn("Saturday\nLocation") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.saturdayLocation)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
				}
				
				Group {
					TableColumn("Sunday\nAvailability") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.sundayAvailability)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
					TableColumn("Sunday\nLocation") { (row: TutorAvailabilityRow)  in
						Text(String("\(row.sundayLocation)"))
							.lineLimit(nil) // Allows text to wrap
							.fixedSize(horizontal: false, vertical: true) // Enables multi-line wrapping
					}
					.width(min: 70, ideal: 70, max: 300)
					
				}
				
//				Group {
					
	
					
//					TableColumn("Monday\nLocation", value: \.mondayLocation)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Tuesday\nAvailability", value: \.tuesdayAvailability)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Tuesday\nLocation", value: \.tuesdayLocation)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Wednesday\nAvailability", value: \.wednesdayAvailability)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Wednesday\nLocation", value: \.wednesdayLocation)
//						.width(min: 90, ideal: 100, max: 300)
//				}
				
//				Group {
					
//					TableColumn("Thursday\nAvailability", value: \TutorAvailabilityRow.thursdayAvailability)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Thursday\nLocation", value: \.thursdayLocation)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Friday\nAvailability", value: \.fridayAvailability)
//						.width(min: 90, ideal: 100, max: 300)

//					TableColumn("Friday\nLocation", value: \.fridayLocation)
//						.width(min: 90, ideal: 100, max: 300)
					
//				}
					
//				Group {
//					TableColumn("Saturday\nAvailability", value: \TutorAvailabilityRow.saturdayAvailability)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Saturday\nLocation", value: \.saturdayLocation)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Sunday\nAvailability", value: \.sundayAvailability)
//						.width(min: 90, ideal: 100, max: 300)
					
//					TableColumn("Sunday\nLocation", value: \.sundayLocation)
//						.width(min: 90, ideal: 100, max: 300)
//				}
			}
		
			
		}
	}
}



