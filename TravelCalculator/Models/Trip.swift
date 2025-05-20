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
    var currency: Currency // 旅行先通貨
    var exchangeRecords: [ExchangeRecord] = [] // この旅行での両替記録
    var purchaseRecords: [PurchaseRecord] = [] // この旅行での買い物記録

    // イニシャライザ
    init(id: UUID = UUID(), name: String, currency: Currency, exchangeRecords: [ExchangeRecord] = [], purchaseRecords: [PurchaseRecord] = []) {
        self.id = id
        self.name = name
        self.currency = currency
        self.exchangeRecords = exchangeRecords
        self.purchaseRecords = purchaseRecords
    }

    // 計算プロパティ - 加重平均レート
    var weightedAverageRate: Double {
        let totalJPY = exchangeRecords.reduce(0) { $0 + $1.jpyAmount }
        let totalForeign = exchangeRecords.reduce(0) { $0 + $1.foreignAmount }

        guard totalForeign > 0 else { return 0 }
        return totalJPY / totalForeign
    }

    // 計算プロパティ - 合計支出額（円換算）
    var totalExpenseInJPY: Double {
        return purchaseRecords.reduce(0) { $0 + $1.jpyAmount(using: weightedAverageRate) }
    }

    // 計算プロパティ - 最近の両替記録（最新3件）
    var recentExchangeRecords: [ExchangeRecord] {
        return Array(exchangeRecords.sorted(by: { $0.date > $1.date }).prefix(3))
    }

    // 計算プロパティ - 最近の買い物記録（最新3件）
    var recentPurchaseRecords: [PurchaseRecord] {
        return Array(purchaseRecords.sorted(by: { $0.date > $1.date }).prefix(3))
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
