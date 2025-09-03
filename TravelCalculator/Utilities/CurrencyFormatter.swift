//
//  CurrencyFormatter.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import Foundation

class CurrencyFormatter {
    static let jpyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.currencySymbol = "¥"
        return formatter
    }()

    static func formatJPY(_ value: Double) -> String {
        return jpyFormatter.string(from: NSNumber(value: value)) ?? "¥0"
    }

    static let foreignFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func formatForeign(_ value: Double, currencyCode: String) -> String {
        // 大きな数値の通貨は小数点なしで表示
        if currencyCode == "KRW" || currencyCode == "IDR" || currencyCode == "VND" {
            let wholeFormatter = NumberFormatter()
            wholeFormatter.numberStyle = .decimal
            wholeFormatter.maximumFractionDigits = 0
            let formatted = wholeFormatter.string(from: NSNumber(value: value)) ?? "0"
            return "\(formatted) \(currencyCode)"
        } else {
            let formatted = foreignFormatter.string(from: NSNumber(value: value)) ?? "0.00"
            return "\(formatted) \(currencyCode)"
        }
    }

    static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 3
        return formatter
    }()

    static func formatRate(_ value: Double) -> String {
        return rateFormatter.string(from: NSNumber(value: value)) ?? "0.00"
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}
