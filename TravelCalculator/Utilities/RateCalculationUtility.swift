//
//  RateCalculationUtility.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import Foundation

/// 入力バリデーションの結果
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?

    static let valid = ValidationResult(isValid: true, errorMessage: nil)

    static func invalid(_ message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorMessage: message)
    }
}

/// レート計算に関する共通ユーティリティ
struct RateCalculationUtility {

    // MARK: - Core Calculation Methods

    /// 入力方式から表示レートを計算
    static func calculateDisplayRate(
        inputType: RateInputType,
        value1: Double,
        value2: Double?
    ) -> Double {
        switch inputType {
        case .legacy, .perForeign:
            return value1

        case .exchangeOffice:
            guard let value2 = value2, value2 != 0 else { return 0 }
            return value1 / value2

        case .perYen:
            guard value1 != 0 else { return 0 }
            return 1.0 / value1
        }
    }

    // MARK: - Simple Validation Methods

    /// 基本的な入力値チェック
    static func isValidInput(
        inputType: RateInputType,
        value1: String,
        value2: String
    ) -> Bool {
        switch inputType {
        case .legacy, .perYen, .perForeign:
            guard let val1 = Double(value1), val1 > 0 else { return false }
            return true

        case .exchangeOffice:
            guard let val1 = Double(value1), val1 > 0,
                  let val2 = Double(value2), val2 > 0 else { return false }
            return true
        }
    }

    /// 基本的な金額チェック
    static func isValidAmounts(jpyAmount: String, foreignAmount: String) -> Bool {
        guard let jpyValue = Double(jpyAmount), jpyValue > 0,
              let foreignValue = Double(foreignAmount), foreignValue > 0 else {
            return false
        }

        let maxAmount = 100_000_000.0
        let minAmount = 0.01

        return jpyValue >= minAmount && jpyValue <= maxAmount &&
               foreignValue >= minAmount && foreignValue <= maxAmount
    }

    // MARK: - Advanced Validation Methods

    /// 包括的な入力バリデーション
    static func validateInput(
        inputType: RateInputType,
        value1: String,
        value2: String,
        jpyAmount: String,
        foreignAmount: String,
        currencyCode: String
    ) -> ValidationResult {

        // 金額の詳細バリデーション
        let amountValidation = validateAmounts(jpyAmount: jpyAmount, foreignAmount: foreignAmount, currencyCode: currencyCode)
        if !amountValidation.isValid {
            return amountValidation
        }

        // レート入力の詳細バリデーション
        let rateValidation = validateRateInput(inputType: inputType, value1: value1, value2: value2, currencyCode: currencyCode)
        if !rateValidation.isValid {
            return rateValidation
        }

        // レートの妥当性チェック
        let rateCheck = validateCalculatedRate(inputType: inputType, value1: value1, value2: value2)
        if !rateCheck.isValid {
            return rateCheck
        }

        return .valid
    }

    // MARK: - Helper Methods

    /// 通貨コードに応じた桁数取得
    static func getDecimalPlaces(for currencyCode: String) -> (integer: Int, decimal: Int) {
        switch currencyCode {
        case "KRW", "IDR", "VND":
            return (integer: 6, decimal: 0)
        case "JPY":
            return (integer: 8, decimal: 0)
        default:
            return (integer: 6, decimal: 2)
        }
    }

    /// プレースホルダーテキスト生成
    static func getPlaceholderText(for inputType: RateInputType, currencyCode: String) -> (value1: String, value2: String?) {
        switch inputType {
        case .legacy, .perForeign:
            return ("例: 150.0", nil)

        case .exchangeOffice:
            let sampleForeign = currencyCode == "KRW" ? "917" : "6.5"
            return ("100", sampleForeign)

        case .perYen:
            let sampleRate = currencyCode == "KRW" ? "9.17" : "0.0067"
            return (sampleRate, nil)
        }
    }

    // MARK: - Private Validation Methods

    /// 金額の詳細バリデーション
    private static func validateAmounts(jpyAmount: String, foreignAmount: String, currencyCode: String) -> ValidationResult {

        // 空文字チェック
        if jpyAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(ValidationConstants.ErrorMessages.missingValue)
        }
        if foreignAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(ValidationConstants.ErrorMessages.missingValue)
        }

        // 数値変換チェック
        guard let jpyValue = Double(jpyAmount) else {
            return .invalid(ValidationConstants.ErrorMessages.invalidNumber)
        }
        guard let foreignValue = Double(foreignAmount) else {
            return .invalid(ValidationConstants.ErrorMessages.invalidNumber)
        }

        // 負の値チェック
        if jpyValue < 0 {
            return .invalid(ValidationConstants.ErrorMessages.negativeAmount)
        }
        if foreignValue < 0 {
            return .invalid(ValidationConstants.ErrorMessages.negativeAmount)
        }

        // ゼロチェック
        if jpyValue <= 0 {
            return .invalid(ValidationConstants.ErrorMessages.zeroAmount)
        }
        if foreignValue <= 0 {
            return .invalid(ValidationConstants.ErrorMessages.zeroAmount)
        }

        // 円の制限チェック
        if jpyValue < ValidationConstants.minAmountJPY || jpyValue > ValidationConstants.maxAmountJPY {
            return .invalid(ValidationConstants.ErrorMessages.invalidAmount)
        }

        // 外貨の制限チェック
        let currencyLimits = CurrencyLimits.getLimits(for: currencyCode)
        if foreignValue < currencyLimits.minAmount || foreignValue > currencyLimits.maxAmount {
            return .invalid(ValidationConstants.ErrorMessages.invalidAmountForCurrency(currencyCode))
        }

        return .valid
    }

    /// レート入力の詳細バリデーション
    private static func validateRateInput(inputType: RateInputType, value1: String, value2: String, currencyCode: String) -> ValidationResult {

        // 空文字チェック
        if value1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(ValidationConstants.ErrorMessages.missingValue)
        }

        // 数値変換チェック
        guard let val1 = Double(value1) else {
            return .invalid(ValidationConstants.ErrorMessages.invalidNumber)
        }

        // 負の値・ゼロチェック
        if val1 <= 0 {
            return .invalid(ValidationConstants.ErrorMessages.positiveValueRequired)
        }

        // 両替所表示の場合の第2値チェック
        if inputType == .exchangeOffice {
            if value2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .invalid(ValidationConstants.ErrorMessages.bothValuesRequired)
            }

            guard let val2 = Double(value2) else {
                return .invalid(ValidationConstants.ErrorMessages.invalidNumber)
            }

            if val2 <= 0 {
                return .invalid(ValidationConstants.ErrorMessages.positiveValueRequired)
            }

            // 両替所表示の範囲チェック
            if val1 < ValidationConstants.minExchangeOfficeYen || val1 > ValidationConstants.maxExchangeOfficeYen {
                return .invalid("円の値は\(ValidationConstants.minExchangeOfficeYen)円以上、\(ValidationConstants.maxExchangeOfficeYen)円以下で入力してください")
            }

            let currencyLimits = CurrencyLimits.getLimits(for: currencyCode)
            if val2 < currencyLimits.minAmount || val2 > currencyLimits.maxAmount {
                return .invalid("外貨の値は適切な範囲で入力してください")
            }
        }

        return .valid
    }

    /// 計算されたレートの妥当性チェック
    private static func validateCalculatedRate(inputType: RateInputType, value1: String, value2: String) -> ValidationResult {

        let val1 = Double(value1) ?? 0
        let val2 = inputType == .exchangeOffice ? Double(value2) : nil

        let calculatedRate = calculateDisplayRate(inputType: inputType, value1: val1, value2: val2)

        // レート計算可能性チェック
        if calculatedRate <= 0 {
            return .invalid(ValidationConstants.ErrorMessages.cannotCalculateRate)
        }

        // レート範囲チェック
        if calculatedRate < ValidationConstants.minRate || calculatedRate > ValidationConstants.maxRate {
            return .invalid(ValidationConstants.ErrorMessages.invalidRate)
        }

        return .valid
    }
}
