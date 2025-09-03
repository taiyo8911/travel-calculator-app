//
//  Trip.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//


import Foundation

struct Trip: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String // 旅行名（例：「タイ旅行2023」）
    var country: String // 国名（例：「タイ」）
    var currency: Currency // 旅行先通貨
    var startDate: Date // 旅行開始日
    var endDate: Date // 旅行終了日
    var exchangeRecords: [ExchangeRecord] = [] // この旅行での両替記録
    var purchaseRecords: [PurchaseRecord] = [] // この旅行での買い物記録

    // イニシャライザ
    init(id: UUID = UUID(), name: String, country: String, currency: Currency, startDate: Date = Date(), endDate: Date = Date().addingTimeInterval(60*60*24*7), exchangeRecords: [ExchangeRecord] = [], purchaseRecords: [PurchaseRecord] = []) {
        self.id = id
        self.name = name
        self.country = country
        self.currency = currency
        self.startDate = startDate
        self.endDate = endDate
        self.exchangeRecords = exchangeRecords
        self.purchaseRecords = purchaseRecords
    }

    // 計算プロパティ - 旅行日数
    var tripDuration: Int {
        let components = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
        return max(1, (components.day ?? 0) + 1) // 最低1日、開始日と終了日を含める
    }

    // 計算プロパティ - 旅行が現在進行中かどうか
    var isActive: Bool {
        let currentDate = Date()
        return currentDate >= startDate && currentDate <= endDate
    }

    // 計算プロパティ - 加重平均レート（修正版）
    var weightedAverageRate: Double {
        // 有効な両替記録のみをフィルタリング
        let validExchanges = exchangeRecords.filter { exchange in
            exchange.jpyAmount > 0 && exchange.foreignAmount > 0
        }

        guard !validExchanges.isEmpty else { return 0 }

        let totalJPY = validExchanges.reduce(0) { $0 + $1.jpyAmount }
        let totalForeign = validExchanges.reduce(0) { $0 + $1.foreignAmount }

        // 両方が正の値であることを確認
        guard totalJPY > 0, totalForeign > 0 else { return 0 }

        return totalJPY / totalForeign
    }

    // 計算プロパティ - 合計支出額（円換算）
    var totalExpenseInJPY: Double {
        let rate = weightedAverageRate
        guard rate > 0 else { return 0 }

        return purchaseRecords.reduce(0) { result, purchase in
            guard purchase.foreignAmount > 0 else { return result }
            return result + purchase.jpyAmount(using: rate)
        }
    }

    // 計算プロパティ - 最近の両替記録（最新3件）
    var recentExchangeRecords: [ExchangeRecord] {
        return Array(exchangeRecords.sorted(by: { $0.date > $1.date }).prefix(3))
    }

    // 計算プロパティ - 最近の買い物記録（最新3件）
    var recentPurchaseRecords: [PurchaseRecord] {
        return Array(purchaseRecords.sorted(by: { $0.date > $1.date }).prefix(3))
    }

    // 計算プロパティ - 合計両替円額（安全性向上）
    var totalExchangeJPYAmount: Double {
        return exchangeRecords.filter { $0.jpyAmount > 0 }.reduce(0) { $0 + $1.jpyAmount }
    }

    // 計算プロパティ - 合計取得外貨額（安全性向上）
    var totalForeignObtained: Double {
        return exchangeRecords.filter { $0.foreignAmount > 0 }.reduce(0) { $0 + $1.foreignAmount }
    }

    // 計算プロパティ - 合計外貨支出額（安全性向上）
    var totalForeignSpent: Double {
        return purchaseRecords.filter { $0.foreignAmount > 0 }.reduce(0) { $0 + $1.foreignAmount }
    }

    // 計算プロパティ - 残り外貨（安全性向上）
    var remainingForeign: Double {
        return totalForeignObtained - totalForeignSpent
    }

    // ヘルパーメソッド - データの整合性チェック
    func validateData() -> [String] {
        var issues: [String] = []

        // 日付の整合性チェック
        if startDate > endDate {
            issues.append("開始日が終了日より後になっています")
        }

        // 両替記録の整合性チェック
        for (index, exchange) in exchangeRecords.enumerated() {
            if exchange.jpyAmount <= 0 {
                issues.append("両替記録\(index + 1): 日本円金額が無効です")
            }
            if exchange.foreignAmount <= 0 {
                issues.append("両替記録\(index + 1): 外貨金額が無効です")
            }
        }

        // 買い物記録の整合性チェック
        for (index, purchase) in purchaseRecords.enumerated() {
            if purchase.foreignAmount <= 0 {
                issues.append("買い物記録\(index + 1): 外貨金額が無効です")
            }
        }

        return issues
    }

    // Hashableプロトコルの実装
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Equatableプロトコルの実装（既存の実装と同じ）
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        return lhs.id == rhs.id
    }
}
