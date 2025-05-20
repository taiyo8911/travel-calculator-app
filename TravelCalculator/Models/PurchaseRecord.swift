//
//  PurchaseRecord.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//


import Foundation

struct PurchaseRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var foreignAmount: Double // 外貨での支払金額
    var description: String // 買い物の説明
    
    // イニシャライザ
    init(id: UUID = UUID(), date: Date, foreignAmount: Double, description: String) {
        self.id = id
        self.date = date
        self.foreignAmount = foreignAmount
        self.description = description
    }
    
    // 計算メソッド - 日本円換算額
    func jpyAmount(using rate: Double) -> Double {
        return foreignAmount * rate
    }
    
    // Equatableプロトコルの実装
    static func == (lhs: PurchaseRecord, rhs: PurchaseRecord) -> Bool {
        return lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        lhs.foreignAmount == rhs.foreignAmount &&
        lhs.description == rhs.description
    }
}
