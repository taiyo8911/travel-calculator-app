//
//  ExchangeRecord.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//


import Foundation

struct ExchangeRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var jpyAmount: Double // 両替した日本円金額
    var displayRate: Double // 両替所が表示していたレート
    var foreignAmount: Double // 受け取った外貨金額
    
    // イニシャライザ
    init(id: UUID = UUID(), date: Date, jpyAmount: Double, displayRate: Double, foreignAmount: Double) {
        self.id = id
        self.date = date
        self.jpyAmount = jpyAmount
        self.displayRate = displayRate
        self.foreignAmount = foreignAmount
    }
    
    // 計算プロパティ - 実質レート
    var actualRate: Double {
        return jpyAmount / foreignAmount
    }
    
    // 計算プロパティ - 手数料率（%）
    var feePercentage: Double {
        return ((actualRate - displayRate) / displayRate) * 100
    }
    
    // 計算プロパティ - 手数料が高いかどうか
    var isHighFee: Bool {
        return feePercentage > 3.0 // 3%以上を高手数料とみなす
    }
    
    // Equatableプロトコルの実装
    static func == (lhs: ExchangeRecord, rhs: ExchangeRecord) -> Bool {
        return lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        lhs.jpyAmount == rhs.jpyAmount &&
        lhs.displayRate == rhs.displayRate &&
        lhs.foreignAmount == rhs.foreignAmount
    }
}
