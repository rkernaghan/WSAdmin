//
//  ValidateDataIntegrityView 2.swift
//  WSAdmin
//
//  Created by Russell Kernaghan on 2026-08-10.
//


import SwiftUI
import AppKit
import PDFKit

struct ValidateDataIntegrityView2: View {

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
		let messages = validationMessages.windowMessageList
		guard !messages.isEmpty else { return }
		
		let pageWidth: CGFloat = 612    // US Letter
		let pageHeight: CGFloat = 792
		let margin: CGFloat = 40
		let contentHeight = pageHeight - margin * 2
		let fontSize: CGFloat = 12
		let lineSpacing: CGFloat = 4
		
		// Measure the actual rendered height of one line at this font size
		let sampleHost = NSHostingController(
			rootView: Text("Sample").font(.system(size: fontSize)).fixedSize()
		)
		let lineHeight = sampleHost.view.fittingSize.height + lineSpacing
		let linesPerPage = max(1, Int(contentHeight / lineHeight))
		
		// Split messages into page-sized chunks
		let pages = stride(from: 0, to: messages.count, by: linesPerPage).map {
			Array(messages[$0..<min($0 + linesPerPage, messages.count)])
		}
		
		let pdfData = NSMutableData()
		guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return }
		var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
		guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
		
		for pageMessages in pages {
			let pageContent = VStack(alignment: .leading, spacing: lineSpacing) {
				ForEach(pageMessages) { message in
					Text(message.windowLineText)
						.font(.system(size: fontSize))
						.fixedSize(horizontal: false, vertical: true)
				}
			}
				.padding(margin)
				.frame(width: pageWidth, height: pageHeight, alignment: .topLeading)
			
			let renderer = ImageRenderer(content: pageContent)
			renderer.render { _, renderFunction in
				pdfContext.beginPDFPage(nil)
				renderFunction(pdfContext)
				pdfContext.endPDFPage()
			}
		}
		pdfContext.closePDF()
		
		guard let pdfDocument = PDFDocument(data: pdfData as Data) else { return }
		
		let printInfo = NSPrintInfo.shared
		printInfo.horizontalPagination = .automatic
		printInfo.verticalPagination = .automatic
		printInfo.topMargin = 0     // margins already baked into each rendered page
		printInfo.bottomMargin = 0
		printInfo.leftMargin = 0
		printInfo.rightMargin = 0
		
		guard let printOperation = pdfDocument.printOperation(
			for: printInfo,
			scalingMode: .pageScaleNone,   // don't shrink — pages are already correctly sized
			autoRotate: true
		) else { return }
		
		DispatchQueue.main.async {
			printOperation.run()
		}
	}
}

