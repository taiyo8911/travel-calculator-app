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
            // 最初のページ
            context.beginPage()
            drawTripHeader(trip: trip, pageRect: pageRect)
            
            // 両替情報
            var yPosition = drawExchangeInfo(trip: trip, pageRect: pageRect, startYPosition: 200)
            
            // 次のセクションまでのスペース
            yPosition += 30
            
            // ページの残りスペースが足りない場合は新しいページを開始
            if yPosition > pageRect.height - 200 {
                context.beginPage()
                yPosition = 50
            }
            
            // 買い物情報
            drawPurchaseInfo(trip: trip, pageRect: pageRect, startYPosition: yPosition)
            
            // サマリーページ
            context.beginPage()
            drawTripSummary(trip: trip, pageRect: pageRect)
        }
        
        return data
    }
    
    // ヘッダー描画処理
    private static func drawTripHeader(trip: Trip, pageRect: CGRect) {
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
        
        // 旅行情報描画
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
        let currencyText = "通貨: \(trip.currency.name) (\(trip.currency.code))"
        
        // 情報描画
        periodText.draw(at: CGPoint(x: 50, y: 100), withAttributes: infoAttributes)
        currencyText.draw(at: CGPoint(x: 50, y: 120), withAttributes: infoAttributes)
        
        // 平均レート情報
        let rateText = "平均レート: 1\(trip.currency.code) = \(CurrencyFormatter.formatRate(trip.weightedAverageRate))円"
        rateText.draw(at: CGPoint(x: 50, y: 140), withAttributes: infoAttributes)
        
        // 区切り線
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 50, y: 170))
        path.addLine(to: CGPoint(x: pageRect.width - 50, y: 170))
        UIColor.lightGray.setStroke()
        path.lineWidth = 1
        path.stroke()
    }
    
    // 両替情報描画処理 - 返り値は次の描画開始Y位置
    private static func drawExchangeInfo(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) -> CGFloat {
        // セクションタイトル
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]
        
        let exchangeTitle = "両替履歴"
        exchangeTitle.draw(at: CGPoint(x: 50, y: startYPosition), withAttributes: sectionAttributes)
        
        // 両替レコードがない場合の表示
        if trip.exchangeRecords.isEmpty {
            let noDataFont = UIFont.italicSystemFont(ofSize: 14)
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: noDataFont,
                .foregroundColor: UIColor.gray
            ]
            "両替履歴はありません。".draw(at: CGPoint(x: 50, y: startYPosition + 30), withAttributes: noDataAttributes)
            return startYPosition + 50
        }
        
        // テーブルヘッダー
        let headerFont = UIFont.boldSystemFont(ofSize: 12)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let headerY = startYPosition + 30
        
        // カラムヘッダー
        "日付".draw(at: CGPoint(x: 50, y: headerY), withAttributes: headerAttributes)
        "日本円".draw(at: CGPoint(x: 150, y: headerY), withAttributes: headerAttributes)
        "表示レート".draw(at: CGPoint(x: 250, y: headerY), withAttributes: headerAttributes)
        "外貨金額".draw(at: CGPoint(x: 350, y: headerY), withAttributes: headerAttributes)
        "実質レート".draw(at: CGPoint(x: 450, y: headerY), withAttributes: headerAttributes)
        
        // 両替データ行
        let rowFont = UIFont.systemFont(ofSize: 12)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        // 各両替レコードをテーブル形式で描画
        var yPosition = headerY + 20
        for record in trip.exchangeRecords.sorted(by: { $0.date > $1.date }) {
            dateFormatter.string(from: record.date).draw(at: CGPoint(x: 50, y: yPosition), withAttributes: rowAttributes)
            CurrencyFormatter.formatJPY(record.jpyAmount).draw(at: CGPoint(x: 150, y: yPosition), withAttributes: rowAttributes)
            String(format: "%.2f", record.displayRate).draw(at: CGPoint(x: 250, y: yPosition), withAttributes: rowAttributes)
            CurrencyFormatter.formatForeign(record.foreignAmount, currencyCode: trip.currency.code)
                .draw(at: CGPoint(x: 350, y: yPosition), withAttributes: rowAttributes)
            String(format: "%.2f", record.actualRate).draw(at: CGPoint(x: 450, y: yPosition), withAttributes: rowAttributes)
            
            yPosition += 20
        }
        
        return yPosition
    }
    
    // 買い物情報描画処理
    private static func drawPurchaseInfo(trip: Trip, pageRect: CGRect, startYPosition: CGFloat) {
        // セクションタイトル
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.black
        ]
        
        let purchaseTitle = "買い物履歴"
        purchaseTitle.draw(at: CGPoint(x: 50, y: startYPosition), withAttributes: sectionAttributes)
        
        // 買い物レコードがない場合の表示
        if trip.purchaseRecords.isEmpty {
            let noDataFont = UIFont.italicSystemFont(ofSize: 14)
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: noDataFont,
                .foregroundColor: UIColor.gray
            ]
            "買い物履歴はありません。".draw(at: CGPoint(x: 50, y: startYPosition + 30), withAttributes: noDataAttributes)
            return
        }
        
        // テーブルヘッダー
        let headerFont = UIFont.boldSystemFont(ofSize: 12)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let headerY = startYPosition + 30
        
        // カラムヘッダー
        "日付".draw(at: CGPoint(x: 50, y: headerY), withAttributes: headerAttributes)
        "内容".draw(at: CGPoint(x: 150, y: headerY), withAttributes: headerAttributes)
        "外貨金額".draw(at: CGPoint(x: 300, y: headerY), withAttributes: headerAttributes)
        "日本円換算".draw(at: CGPoint(x: 400, y: headerY), withAttributes: headerAttributes)
        
        // 買い物データ行
        let rowFont = UIFont.systemFont(ofSize: 12)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        // 各買い物レコードをテーブル形式で描画
        var yPosition = headerY + 20
        for record in trip.purchaseRecords.sorted(by: { $0.date > $1.date }) {
            dateFormatter.string(from: record.date).draw(at: CGPoint(x: 50, y: yPosition), withAttributes: rowAttributes)
            
            // 内容のテキスト (長いテキストを省略)
            let description = record.description
            let maxWidth: CGFloat = 130
            let descriptionAttr = NSAttributedString(string: description, attributes: rowAttributes)
            let descriptionSize = descriptionAttr.size()
            
            if descriptionSize.width > maxWidth {
                // テキストが長すぎる場合は省略
                // 修正後:
                let shortenedDesc = String(description.prefix(20)) + "..."
                shortenedDesc.draw(at: CGPoint(x: 150, y: yPosition), withAttributes: rowAttributes)
            } else {
                description.draw(at: CGPoint(x: 150, y: yPosition), withAttributes: rowAttributes)
            }
            
            CurrencyFormatter.formatForeign(record.foreignAmount, currencyCode: trip.currency.code)
                .draw(at: CGPoint(x: 300, y: yPosition), withAttributes: rowAttributes)
            
            CurrencyFormatter.formatJPY(record.jpyAmount(using: trip.weightedAverageRate))
                .draw(at: CGPoint(x: 400, y: yPosition), withAttributes: rowAttributes)
            
            yPosition += 20
        }
    }
    
    // 旅行サマリー描画処理
    private static func drawTripSummary(trip: Trip, pageRect: CGRect) {
        // タイトル
        let titleFont = UIFont.boldSystemFont(ofSize: 28)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let title = "旅行サマリー"
        let titleStringSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageRect.width - titleStringSize.width) / 2,
            y: 50,
            width: titleStringSize.width,
            height: titleStringSize.height
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // 旅行名
        let subTitleFont = UIFont.boldSystemFont(ofSize: 22)
        let subTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subTitleFont,
            .foregroundColor: UIColor.black
        ]
        
        trip.name.draw(at: CGPoint(x: 50, y: 100), withAttributes: subTitleAttributes)
        
        // サマリー情報
        let infoFont = UIFont.systemFont(ofSize: 16)
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: infoFont,
            .foregroundColor: UIColor.black
        ]
        
        let boldFont = UIFont.boldSystemFont(ofSize: 16)
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: UIColor.black
        ]
        
        // 日付フォーマット
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        
        var yPosition: CGFloat = 150
        
        // 期間情報
        "期間:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        let periodText = "\(dateFormatter.string(from: trip.startDate)) 〜 \(dateFormatter.string(from: trip.endDate))"
        periodText.draw(at: CGPoint(x: 150, y: yPosition), withAttributes: infoAttributes)
        yPosition += 25
        
        "滞在日数:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        "\(trip.tripDuration)日間".draw(at: CGPoint(x: 150, y: yPosition), withAttributes: infoAttributes)
        yPosition += 25
        
        "通貨:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        "\(trip.currency.name) (\(trip.currency.code))".draw(at: CGPoint(x: 150, y: yPosition), withAttributes: infoAttributes)
        yPosition += 40
        
        // 両替情報
        "両替レート (平均):".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        "1\(trip.currency.code) = \(CurrencyFormatter.formatRate(trip.weightedAverageRate))円".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        yPosition += 25
        
        "両替総額:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        let totalJPY = trip.exchangeRecords.reduce(0) { $0 + $1.jpyAmount }
        CurrencyFormatter.formatJPY(totalJPY).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        yPosition += 25
        
        "取得外貨総額:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        let totalForeign = trip.exchangeRecords.reduce(0) { $0 + $1.foreignAmount }
        CurrencyFormatter.formatForeign(totalForeign, currencyCode: trip.currency.code).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        yPosition += 40
        
        // 買い物情報
        "買い物回数:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        "\(trip.purchaseRecords.count)回".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        yPosition += 25
        
        "外貨総支出:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        let totalSpentForeign = trip.purchaseRecords.reduce(0) { $0 + $1.foreignAmount }
        CurrencyFormatter.formatForeign(totalSpentForeign, currencyCode: trip.currency.code).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        yPosition += 25
        
        "日本円換算総支出:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        CurrencyFormatter.formatJPY(trip.totalExpenseInJPY).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        yPosition += 40
        
        // 残りの外貨
        "残り外貨:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        let remainingForeign = totalForeign - totalSpentForeign
        let remainingText = CurrencyFormatter.formatForeign(remainingForeign, currencyCode: trip.currency.code)
        remainingText.draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        yPosition += 25
        
        "残り外貨 (円換算):".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: boldAttributes)
        let remainingJPY = remainingForeign * trip.weightedAverageRate
        CurrencyFormatter.formatJPY(remainingJPY).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: infoAttributes)
        
        // フッター
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
