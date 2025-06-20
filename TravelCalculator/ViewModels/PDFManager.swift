//
//  PDFManager.swift
//  TravelCalculator
//
//  Created by Refactoring on 2025/06/20.
//

import Foundation
import UIKit
import PDFKit

protocol PDFManagerProtocol {
    func generateTripPDF(trip: Trip) -> Data?
    func sharePDF(for trip: Trip, from viewController: UIViewController)
}

class PDFManager: PDFManagerProtocol {

    // MARK: - PDF Generation

    func generateTripPDF(trip: Trip) -> Data? {
        return PDFGenerator.generateTripPDF(trip: trip)
    }

    func sharePDF(for trip: Trip, from viewController: UIViewController) {
        guard let pdfData = generateTripPDF(trip: trip) else {
            print("PDFの生成に失敗しました")
            return
        }

        // 一時ファイルとしてPDFを保存
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(trip.name)_旅行記録.pdf")

        do {
            try pdfData.write(to: tmpURL)

            // 共有シートを表示
            let activityVC = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)

            // iPad対応
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            viewController.present(activityVC, animated: true)
        } catch {
            print("PDF保存エラー: \(error)")
        }
    }
}
