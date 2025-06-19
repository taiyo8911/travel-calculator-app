//
//  ExchangeRecord.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import Foundation

// レート入力方式の列挙型
enum RateInputType: String, Codable, CaseIterable {
    case legacy = "legacy"                    // 既存データ（1外貨=○円）
    case exchangeOffice = "exchangeOffice"    // 両替所表示（○円=○外貨）
    case perYen = "perYen"                   // 1円あたり（1円=○外貨）
    case perForeign = "perForeign"           // 1外貨あたり（1外貨=○円）

    var displayName: String {
        switch self {
        case .legacy:
            return "従来方式"
        case .exchangeOffice:
            return "両替所表示"
        case .perYen:
            return "1円あたり"
        case .perForeign:
            return "1外貨あたり"
        }
    }
}

struct ExchangeRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var jpyAmount: Double // 両替した日本円金額
    var displayRate: Double // 両替所が表示していたレート（計算で求められる）
    var foreignAmount: Double // 受け取った外貨金額

    // 新規フィールド - レート入力方式と値
    var rateInputType: RateInputType? // 入力方式（nilは既存データ）
    var inputValue1: Double? // 第1の値（円の値 or 1円あたりの値 or 1外貨あたりの値）
    var inputValue2: Double? // 第2の値（外貨の値、両替所表示用のみ使用）

    // イニシャライザ - 既存データ用（互換性維持）
    init(id: UUID = UUID(), date: Date, jpyAmount: Double, displayRate: Double, foreignAmount: Double) {
        self.id = id
        self.date = date
        self.jpyAmount = jpyAmount
        self.foreignAmount = foreignAmount
        self.rateInputType = .legacy
        self.inputValue1 = displayRate
        self.inputValue2 = nil

        // displayRateは渡された値をそのまま使用（既存データ互換性）
        self.displayRate = displayRate
    }

    // イニシャライザ - 新規入力用
    init(id: UUID = UUID(),
         date: Date,
         jpyAmount: Double,
         foreignAmount: Double,
         rateInputType: RateInputType,
         inputValue1: Double,
         inputValue2: Double? = nil) {

        self.id = id
        self.date = date
        self.jpyAmount = jpyAmount
        self.foreignAmount = foreignAmount
        self.rateInputType = rateInputType
        self.inputValue1 = inputValue1
        self.inputValue2 = inputValue2

        // RateCalculationUtilityを使用してdisplayRateを計算
        self.displayRate = RateCalculationUtility.calculateDisplayRate(
            inputType: rateInputType,
            value1: inputValue1,
            value2: inputValue2
        )
    }

    // 計算プロパティ - 実質レート（変更なし）
    var actualRate: Double {
        guard foreignAmount > 0 else { return 0 }
        return jpyAmount / foreignAmount
    }

    // 計算プロパティ - 手数料率（%）
    var feePercentage: Double {
        guard displayRate > 0, actualRate > 0 else { return 0 }
        return ((actualRate - displayRate) / displayRate) * 100
    }

    // 計算プロパティ - 手数料が高いかどうか
    var isHighFee: Bool {
        return feePercentage > 3.0 // 3%以上を高手数料とみなす
    }

    // 表示用のレート文字列を生成
    func displayRateString(currencyCode: String) -> String {
        guard let inputType = rateInputType else {
            // 既存データの場合
            return "1\(currencyCode) = \(String(format: "%.3f", displayRate))円"
        }

        switch inputType {
        case .legacy:
            return "1\(currencyCode) = \(String(format: "%.3f", displayRate))円"

        case .exchangeOffice:
            let value1 = inputValue1 ?? 100
            let value2 = inputValue2 ?? 0
            // 通貨によって適切な桁数で表示
            if currencyCode == "KRW" || currencyCode == "IDR" || currencyCode == "VND" {
                return "\(String(format: "%.0f", value1))円 = \(String(format: "%.0f", value2))\(currencyCode)"
            } else {
                return "\(String(format: "%.0f", value1))円 = \(String(format: "%.2f", value2))\(currencyCode)"
            }

        case .perYen:
            let value1 = inputValue1 ?? 0
            if currencyCode == "KRW" || currencyCode == "IDR" || currencyCode == "VND" {
                return "1円 = \(String(format: "%.1f", value1))\(currencyCode)"
            } else {
                return "1円 = \(String(format: "%.3f", value1))\(currencyCode)"
            }

        case .perForeign:
            let value1 = inputValue1 ?? 0
            return "1\(currencyCode) = \(String(format: "%.3f", value1))円"
        }
    }

    // Equatableプロトコルの実装
    static func == (lhs: ExchangeRecord, rhs: ExchangeRecord) -> Bool {
        return lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        lhs.jpyAmount == rhs.jpyAmount &&
        lhs.displayRate == rhs.displayRate &&
        lhs.foreignAmount == rhs.foreignAmount &&
        lhs.rateInputType == rhs.rateInputType &&
        lhs.inputValue1 == rhs.inputValue1 &&
        lhs.inputValue2 == rhs.inputValue2
    }
}
