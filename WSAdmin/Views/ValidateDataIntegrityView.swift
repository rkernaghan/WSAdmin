
import SwiftUI
import AppKit

struct ValidateDataIntegrityView: View {
	
	var validationMessages: WindowMessages
	var referenceData: ReferenceData
	
	@Environment(RefDataVM.self) var refDataModel: RefDataVM
	
	@State private var showAlert: Bool = false
	
	var body: some View {
		VStack {
			List(validationMessages.windowMessageList) {
				Text($0.windowLineText)
			}
		}
		.toolbar {
			Button("Print") {
				printValidationMessages()
			}
		}
		.alert(buttonErrorMsg, isPresented: $showAlert) {
			Button("OK", role: .cancel) { }
		}
	}
	
	private func printValidationMessages() {
		let printContent = VStack(alignment: .leading, spacing: 4) {
			ForEach(validationMessages.windowMessageList) { message in
				Text(message.windowLineText)
			}
		}
			.padding()
			.frame(width: 600, alignment: .leading)
		
		let hostingController = NSHostingController(rootView: printContent)
		let fittingSize = hostingController.view.fittingSize
		hostingController.view.frame = CGRect(origin: .zero, size: fittingSize)
		
		let printInfo = NSPrintInfo.shared
		printInfo.horizontalPagination = .automatic
		printInfo.verticalPagination = .automatic
		printInfo.topMargin = 20
		printInfo.bottomMargin = 20
		printInfo.leftMargin = 20
		printInfo.rightMargin = 20
		
		let printOperation = NSPrintOperation(view: hostingController.view, printInfo: printInfo)
		printOperation.run()
	}
}
