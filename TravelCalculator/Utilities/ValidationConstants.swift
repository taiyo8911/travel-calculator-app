//
//  ValidationConstants.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import Foundation

/// アプリ全体で使用するバリデーション定数とメッセージ
struct ValidationConstants {

    // MARK: - 金額制限

    /// 最小金額（円）
    static let minAmountJPY: Double = 1.0 // 1円

    /// 最大金額（円）
    static let maxAmountJPY: Double = 100_000_000.0 // 1億円

    // MARK: - レート制限

    /// 最小レート（1外貨あたりの円）
    static let minRate: Double = 0.001 // 0.1銭

    /// 最大レート（1外貨あたりの円）
    static let maxRate: Double = 10_000.0 // 1万円

    /// 両替所表示での最小単位（円）
    static let minExchangeOfficeYen: Double = 1.0 // 1円

    /// 両替所表示での最大単位（円）
    static let maxExchangeOfficeYen: Double = 100_000.0 // 10万円

    // MARK: - 文字列制限

    /// 旅行名の最大文字数
    static let maxTripNameLength: Int = 50

    /// 国名の最大文字数
    static let maxCountryNameLength: Int = 30

    /// 買い物説明の最大文字数
    static let maxPurchaseDescriptionLength: Int = 100

    // MARK: - エラーメッセージ

    struct ErrorMessages {

        // 金額関連
        static let invalidAmount = "金額は\(formatCurrency(ValidationConstants.minAmountJPY))以上、\(formatCurrency(ValidationConstants.maxAmountJPY))以下で入力してください"
        static let zeroAmount = "金額は0より大きい値を入力してください"
        static let tooLargeAmount = "金額が大きすぎます"
        static let negativeAmount = "負の値は入力できません"

        // レート関連
        static let invalidRate = "レートは\(ValidationConstants.minRate)円以上、\(formatCurrency(ValidationConstants.maxRate))以下で入力してください"
        static let zeroRate = "レートは0より大きい値を入力してください"
        static let cannotCalculateRate = "レートが計算できません"
        static let extremeRate = "レートが異常です"

        // 入力形式関連
        static let missingValue = "値を入力してください"
        static let invalidNumber = "正しい数値を入力してください"
        static let bothValuesRequired = "両方の値を入力してください"
        static let positiveValueRequired = "正の数を入力してください"

        // フィールド固有
        static let invalidTripName = "旅行名は\(ValidationConstants.maxTripNameLength)文字以内で入力してください"
        static let emptyTripName = "旅行名を入力してください"
        static let invalidCountryName = "国名は\(ValidationConstants.maxCountryNameLength)文字以内で入力してください"
        static let emptyCountryName = "国名を入力してください"
        static let invalidPurchaseDescription = "説明は\(ValidationConstants.maxPurchaseDescriptionLength)文字以内で入力してください"
        static let emptyPurchaseDescription = "買い物の内容を入力してください"

        // 日付関連
        static let invalidDateRange = "開始日は終了日より前に設定してください"
        static let futureDateRequired = "未来の日付を選択してください"
        static let pastDateRequired = "過去の日付を選択してください"

        // 通貨固有
        static func invalidAmountForCurrency(_ currencyCode: String) -> String {
            let limits = CurrencyLimits.getLimits(for: currencyCode)
            return "\(currencyCode)は\(formatAmount(limits.minAmount, currency: currencyCode))以上、\(formatAmount(limits.maxAmount, currency: currencyCode))以下で入力してください"
        }

        // 両替所表示用のエラーメッセージ
        static func invalidExchangeOfficeYen() -> String {
            return "円の値は\(formatCurrency(ValidationConstants.minExchangeOfficeYen))以上、\(formatCurrency(ValidationConstants.maxExchangeOfficeYen))以下で入力してください"
        }

        static func invalidExchangeOfficeForeign(_ currencyCode: String) -> String {
            let limits = CurrencyLimits.getLimits(for: currencyCode)
            return "外貨の値は\(formatAmount(limits.minAmount, currency: currencyCode))以上、\(formatAmount(limits.maxAmount, currency: currencyCode))以下で入力してください"
        }

        private static func formatCurrency(_ amount: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "JPY"
            formatter.currencySymbol = "¥"
            return formatter.string(from: NSNumber(value: amount)) ?? "¥\(amount)"
        }

        private static func formatAmount(_ amount: Double, currency: String) -> String {
            if currency == "JPY" {
                return formatCurrency(amount)
            } else {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = CurrencyLimits.getDecimalPlaces(for: currency)
                let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
                return "\(formatted) \(currency)"
            }
        }
    }

    // MARK: - バリデーションヘルパーメソッド

    /// 旅行名のバリデーション
    static func validateTripName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return .invalid(ErrorMessages.emptyTripName)
        }

        if trimmedName.count > maxTripNameLength {
            return .invalid(ErrorMessages.invalidTripName)
        }

        return .valid
    }

    /// 国名のバリデーション
    static func validateCountryName(_ country: String) -> ValidationResult {
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCountry.isEmpty {
            return .invalid(ErrorMessages.emptyCountryName)
        }

        if trimmedCountry.count > maxCountryNameLength {
            return .invalid(ErrorMessages.invalidCountryName)
        }

        return .valid
    }

    /// 買い物説明のバリデーション
    static func validatePurchaseDescription(_ description: String) -> ValidationResult {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedDescription.isEmpty {
            return .invalid(ErrorMessages.emptyPurchaseDescription)
        }

        if trimmedDescription.count > maxPurchaseDescriptionLength {
            return .invalid(ErrorMessages.invalidPurchaseDescription)
        }

        return .valid
    }

    /// 日付範囲のバリデーション
    static func validateDateRange(startDate: Date, endDate: Date) -> ValidationResult {
        if startDate > endDate {
            return .invalid(ErrorMessages.invalidDateRange)
        }

        return .valid
    }
}

/// 通貨別の制限値（統一版）
struct CurrencyLimits {
    let minAmount: Double
    let maxAmount: Double
    let decimalPlaces: Int
    let sampleRate: String
    let displayName: String

    /// 通貨コードに応じた制限値を取得
    static func getLimits(for currencyCode: String) -> CurrencyLimits {
        switch currencyCode {
        case "KRW":
            return CurrencyLimits(
                minAmount: 1.0,
                maxAmount: 100_000_000.0,
                decimalPlaces: 0,
                sampleRate: "917",
                displayName: "韓国ウォン"
            )
        case "IDR":
            return CurrencyLimits(
                minAmount: 1.0,
                maxAmount: 500_000_000.0,
                decimalPlaces: 0,
                sampleRate: "1500",
                displayName: "インドネシアルピア"
            )
        case "VND":
            return CurrencyLimits(
                minAmount: 1.0,
                maxAmount: 1_000_000_000.0,
                decimalPlaces: 0,
                sampleRate: "2700",
                displayName: "ベトナムドン"
            )
        case "JPY":
            return CurrencyLimits(
                minAmount: 1.0,
                maxAmount: 100_000_000.0,
                decimalPlaces: 0,
                sampleRate: "1",
                displayName: "日本円"
            )
        default:
            // USD, EUR, GBP など
            return CurrencyLimits(
                minAmount: 0.01,
                maxAmount: 1_000_000.0,
                decimalPlaces: 2,
                sampleRate: "6.5",
                displayName: "外貨"
            )
        }
    }

    /// 通貨の小数点桁数を取得
    static func getDecimalPlaces(for currencyCode: String) -> Int {
        return getLimits(for: currencyCode).decimalPlaces
    }

    /// 通貨のサンプルレートを取得
    static func getSampleRate(for currencyCode: String) -> String {
        return getLimits(for: currencyCode).sampleRate
    }

    /// 通貨の表示名を取得
    static func getDisplayName(for currencyCode: String) -> String {
        return getLimits(for: currencyCode).displayName
    }

    /// 通貨が大きな数値の通貨かどうか
    static func isLargeValueCurrency(_ currencyCode: String) -> Bool {
        return ["KRW", "IDR", "VND"].contains(currencyCode)
    }
}

/// フォーマット済みエラーメッセージを提供
extension ValidationConstants.ErrorMessages {

    /// 通貨に応じた金額エラーメッセージ
    static func getAmountErrorMessage(for currencyCode: String) -> String {
        if currencyCode == "JPY" {
            return invalidAmount
        } else {
            return invalidAmountForCurrency(currencyCode)
        }
    }

    /// 入力方式に応じたエラーメッセージ
    static func getInputErrorMessage(for inputType: RateInputType) -> String {
        switch inputType {
        case .exchangeOffice:
            return bothValuesRequired
        case .perYen, .perForeign, .legacy:
            return positiveValueRequired
        }
    }

    /// レート範囲のエラーメッセージ
    static func getRateRangeErrorMessage(for inputType: RateInputType, currencyCode: String) -> String {
        switch inputType {
        case .exchangeOffice:
            return "両替所表示の値が範囲外です"
        case .perYen:
            return "1円あたりのレートが範囲外です"
        case .perForeign, .legacy:
            return "1外貨あたりのレートが範囲外です"
        }
    }
}
