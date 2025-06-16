//
//  PDFGenerator.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/05/21.
//

import PDFKit
import SwiftUI

class PDFGenerator {
    // PDF生成メインメソッド
    static func generateTripPDF(trip: Trip) -> Data? {
        // PDFのページサイズを設定 (A4サイズ)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            // 1ページ目：両替情報ページ
            context.beginPage()
            drawExchangePage(trip: trip, pageRect: pageRect)

            // 2ページ目：支出情報ページ
            context.beginPage()
            drawPurchasePage(trip: trip, pageRect: pageRect)
        }

        return data
    }

    // 1ページ目：両替情報ページ描画
    private static func drawExchangePage(trip: Trip, pageRect: CGRect) {
        var yPosition = drawHeader(trip: trip, pageRect: pageRect)
        yPosition += 30

        yPosition = drawExchangeSummary(trip: trip, pageRect: pageRect, startYPosition: yPosition)
        yPosition += 20

        yPosition = drawExchangeAnalysis(trip: trip, pageRect: pageRect, startYPosition: yPosition)
        yPosition += 20

        yPosition = drawExchangeDetailTable(trip: trip, pageRect: pageRect, startYPosition: yPosition)

        drawFooter(pageRect: pageRect)
    }

    // 2ページ目：支出情報ページ描画
    private static func drawPurchasePage(trip: Trip, pageRect: CGRect) {
        var yPosition = drawHeader(trip: trip, pageRect: pageRect)
        yPosition += 30

        yPosition = drawPurchaseSummary(trip: trip, pageRect: pageRect, startYPosition: yPosition)
        yPosition += 20

        yPosition = drawPurchaseAnalysis(trip: trip, pageRect: pageRect, startYPosition: yPosition)
        yPosition += 20

        yPosition = drawPurchaseDetailTable(trip: trip, pageRect: pageRect, startYPosition: yPosition)

        drawFooter(pageRect: pageRect)
    }

    // ヘッダー描画処理
    private static func drawHeader(trip: Trip, pageRect: CGRect) -> CGFloat {
        // タイトル用の属性テキスト
        let titleFont = UIFont.boldSystemFont(ofSize: 28)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]

        // タイトル描画
        let title = trip.name
        let titleStringSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageRect.width - titleStringSize.width) / 2,
            y: 50,
            width: titleStringSize.width,
            height: titleStringSize.height
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)

        // 基本情報描画
        let infoFont = UIFont.systemFont(ofSize: 14)
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: infoFont,
            .foregroundColor: UIColor.darkGray
        ]

        // 日付フォーマット
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        // 基本情報テキスト
        let periodText = "期間: \(dateFormatter.string(from: trip.startDate)) 〜 \(dateFormatter.string(from: trip.endDate)) (\(trip.tripDuration)日間)"
        let countryText = "国名: \(trip.country)"
        let currencyText = "通貨: \(trip.currency.name) (\(trip.currency.code))"

        // 情報描画
        periodText.draw(at: CGPoint(x: 50, y: 100), withAttributes: infoAttributes)
        countryText.draw(at: CGPoint(x: 50, y: 120), withAttributes: infoAttributes)
        currencyText.draw(at: CGPoint(x: 50, y: 140), withAttributes: infoAttributes)

        // 区切り線
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 50, y: 170))
        path.addLine(to: CGPoint(x: pageRect.width - 50, y: 170))
        UIColor.lightGray.setStroke()
        path.lineWidth = 1
        path.stroke()

        return 170
    }

    // 両替サマリー描画処理
    private static func drawExchangeSummary(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) -> CGFloat {
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]

        let itemFont = UIFont.systemFont(ofSize: 14)
        let itemAttributes: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: UIColor.black
        ]

        let valueFont = UIFont.boldSystemFont(ofSize: 14)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.black
        ]

        var yPosition = startYPosition + 20

        "両替サマリー".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 30

        // 両替総額
        let totalJPY = trip.exchangeRecords.reduce(0) { $0 + $1.jpyAmount }
        "両替総額:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        CurrencyFormatter.formatJPY(totalJPY).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        yPosition += 20

        // 取得外貨総額
        let totalForeign = trip.exchangeRecords.reduce(0) { $0 + $1.foreignAmount }
        "取得外貨総額:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        CurrencyFormatter.formatForeign(totalForeign, currencyCode: trip.currency.code).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        yPosition += 20

        // 両替回数
        "両替回数:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        "\(trip.exchangeRecords.count)回".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        yPosition += 20

        // 加重平均レート
        "加重平均レート:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        if trip.weightedAverageRate > 0 {
            "1\(trip.currency.code) = \(CurrencyFormatter.formatRate(trip.weightedAverageRate))円".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        } else {
            "データなし".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        }
        yPosition += 20

        return yPosition
    }

    // 両替分析描画処理
    private static func drawExchangeAnalysis(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) -> CGFloat {
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]

        let itemFont = UIFont.systemFont(ofSize: 14)
        let itemAttributes: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: UIColor.black
        ]

        let valueFont = UIFont.boldSystemFont(ofSize: 14)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.black
        ]

        var yPosition = startYPosition + 10

        "両替分析".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 30

        if trip.exchangeRecords.isEmpty {
            "両替記録がありません".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
            yPosition += 20
        } else {
            let rates = trip.exchangeRecords.map { $0.actualRate }
            let maxRate = rates.max() ?? 0
            let minRate = rates.min() ?? 0

            // 最高実質レート
            "最高実質レート:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
            "1\(trip.currency.code) = \(CurrencyFormatter.formatRate(maxRate))円".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
            yPosition += 20

            // 最低実質レート
            "最低実質レート:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
            "1\(trip.currency.code) = \(CurrencyFormatter.formatRate(minRate))円".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
            yPosition += 20

            // 入力方式の内訳
            let inputTypeBreakdown = Dictionary(grouping: trip.exchangeRecords) { $0.rateInputType ?? .legacy }
            "入力方式の内訳:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
            yPosition += 15

            for (inputType, records) in inputTypeBreakdown.sorted(by: { $0.value.count > $1.value.count }) {
                "  \(inputType.displayName): \(records.count)回".draw(at: CGPoint(x: 90, y: yPosition), withAttributes: itemAttributes)
                yPosition += 15
            }
        }

        return yPosition
    }

    // 両替履歴詳細テーブル描画処理
    private static func drawExchangeDetailTable(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) -> CGFloat {
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]

        var yPosition = startYPosition + 10

        "両替履歴詳細".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 30

        if trip.exchangeRecords.isEmpty {
            let noDataFont = UIFont.italicSystemFont(ofSize: 14)
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: noDataFont,
                .foregroundColor: UIColor.gray
            ]
            "両替履歴はありません。".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: noDataAttributes)
            return yPosition + 20
        }

        // テーブルヘッダー
        let headerFont = UIFont.boldSystemFont(ofSize: 10)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray
        ]

        "日付".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
        "入力方式".draw(at: CGPoint(x: 120, y: yPosition), withAttributes: headerAttributes)
        "日本円".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: headerAttributes)
        "外貨金額".draw(at: CGPoint(x: 280, y: yPosition), withAttributes: headerAttributes)
        "実質レート".draw(at: CGPoint(x: 360, y: yPosition), withAttributes: headerAttributes)
        yPosition += 20

        // データ行
        let rowFont = UIFont.systemFont(ofSize: 10)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for record in trip.exchangeRecords.sorted(by: { $0.date > $1.date }) {
            dateFormatter.string(from: record.date).draw(at: CGPoint(x: 50, y: yPosition), withAttributes: rowAttributes)
            (record.rateInputType ?? .legacy).displayName.draw(at: CGPoint(x: 120, y: yPosition), withAttributes: rowAttributes)
            String(format: "%.0f円", record.jpyAmount).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: rowAttributes)
            String(format: "%.2f", record.foreignAmount).draw(at: CGPoint(x: 280, y: yPosition), withAttributes: rowAttributes)
            String(format: "%.3f", record.actualRate).draw(at: CGPoint(x: 360, y: yPosition), withAttributes: rowAttributes)
            yPosition += 15
        }

        return yPosition
    }

    // 支出サマリー描画処理
    private static func drawPurchaseSummary(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) -> CGFloat {
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]

        let itemFont = UIFont.systemFont(ofSize: 14)
        let itemAttributes: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: UIColor.black
        ]

        let valueFont = UIFont.boldSystemFont(ofSize: 14)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.black
        ]

        var yPosition = startYPosition + 20

        "支出サマリー".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 30

        // 支出総額（外貨）
        let totalForeignSpent = trip.purchaseRecords.reduce(0) { $0 + $1.foreignAmount }
        "支出総額（外貨）:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        CurrencyFormatter.formatForeign(totalForeignSpent, currencyCode: trip.currency.code).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        yPosition += 20

        // 支出総額（日本円換算）
        "支出総額（円換算）:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        if trip.weightedAverageRate > 0 {
            CurrencyFormatter.formatJPY(trip.totalExpenseInJPY).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        } else {
            "計算不可（両替記録なし）".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        }
        yPosition += 20

        // 買い物回数
        "買い物回数:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        "\(trip.purchaseRecords.count)回".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        yPosition += 20

        return yPosition
    }

    // 支出分析描画処理
    private static func drawPurchaseAnalysis(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) -> CGFloat {
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]

        let itemFont = UIFont.systemFont(ofSize: 14)
        let itemAttributes: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: UIColor.black
        ]

        let valueFont = UIFont.boldSystemFont(ofSize: 14)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.black
        ]

        var yPosition = startYPosition + 10

        "支出分析".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 30

        if trip.purchaseRecords.isEmpty {
            "買い物記録がありません".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
            yPosition += 20
        } else {
            let amounts = trip.purchaseRecords.map { $0.foreignAmount }
            let maxAmount = amounts.max() ?? 0
            let minAmount = amounts.min() ?? 0

            // 最高額の買い物
            if let maxPurchase = trip.purchaseRecords.first(where: { $0.foreignAmount == maxAmount }) {
                "最高額の買い物:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
                let maxText = "\(CurrencyFormatter.formatForeign(maxAmount, currencyCode: trip.currency.code))（\(maxPurchase.description)）"
                maxText.draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
                yPosition += 20
            }

            // 最低額の買い物
            if let minPurchase = trip.purchaseRecords.first(where: { $0.foreignAmount == minAmount }) {
                "最低額の買い物:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
                let minText = "\(CurrencyFormatter.formatForeign(minAmount, currencyCode: trip.currency.code))（\(minPurchase.description)）"
                minText.draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
                yPosition += 20
            }
        }

        // 残り外貨
        let totalForeignObtained = trip.exchangeRecords.reduce(0) { $0 + $1.foreignAmount }
        let totalForeignSpent = trip.purchaseRecords.reduce(0) { $0 + $1.foreignAmount }
        let remainingForeign = totalForeignObtained - totalForeignSpent

        "残り外貨:".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: itemAttributes)
        CurrencyFormatter.formatForeign(remainingForeign, currencyCode: trip.currency.code).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: valueAttributes)
        yPosition += 20

        return yPosition
    }

    // 買い物履歴詳細テーブル描画処理
    private static func drawPurchaseDetailTable(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) -> CGFloat {
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]

        var yPosition = startYPosition + 10

        "買い物履歴詳細".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
        yPosition += 30

        if trip.purchaseRecords.isEmpty {
            let noDataFont = UIFont.italicSystemFont(ofSize: 14)
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: noDataFont,
                .foregroundColor: UIColor.gray
            ]
            "買い物履歴はありません。".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: noDataAttributes)
            return yPosition + 20
        }

        // テーブルヘッダー
        let headerFont = UIFont.boldSystemFont(ofSize: 12)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray
        ]

        "日付".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
        "内容".draw(at: CGPoint(x: 150, y: yPosition), withAttributes: headerAttributes)
        "外貨金額".draw(at: CGPoint(x: 300, y: yPosition), withAttributes: headerAttributes)
        "日本円換算".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: headerAttributes)
        yPosition += 20

        // データ行
        let rowFont = UIFont.systemFont(ofSize: 12)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for record in trip.purchaseRecords.sorted(by: { $0.date > $1.date }) {
            dateFormatter.string(from: record.date).draw(at: CGPoint(x: 50, y: yPosition), withAttributes: rowAttributes)

            // 内容のテキスト（長いテキストを省略）
            let description = record.description
            let shortenedDesc = description.count > 20 ? String(description.prefix(20)) + "..." : description
            shortenedDesc.draw(at: CGPoint(x: 150, y: yPosition), withAttributes: rowAttributes)

            CurrencyFormatter.formatForeign(record.foreignAmount, currencyCode: trip.currency.code)
                .draw(at: CGPoint(x: 300, y: yPosition), withAttributes: rowAttributes)

            if trip.weightedAverageRate > 0 {
                CurrencyFormatter.formatJPY(record.jpyAmount(using: trip.weightedAverageRate))
                    .draw(at: CGPoint(x: 400, y: yPosition), withAttributes: rowAttributes)
            } else {
                "計算不可".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: rowAttributes)
            }

            yPosition += 20
        }

        return yPosition
    }

    // フッター描画処理
    private static func drawFooter(pageRect: CGRect) {
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]

        let footerText = "Travel Calculator App - 出力日時: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
        let footerStringSize = footerText.size(withAttributes: footerAttributes)
        footerText.draw(at: CGPoint(x: (pageRect.width - footerStringSize.width) / 2, y: pageRect.height - 40), withAttributes: footerAttributes)
    }
}
