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

/// レート計算に関する共通ユーティリティ（統一版）
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

    // MARK: - Comprehensive Validation Methods

    /// 包括的な入力バリデーション（統一版）
    static func validateInput(
        inputType: RateInputType,
        value1: String,
        value2: String,
        jpyAmount: String,
        foreignAmount: String,
        currencyCode: String
    ) -> ValidationResult {

        // 金額のバリデーション
        let amountValidation = validateAmounts(
            jpyAmount: jpyAmount,
            foreignAmount: foreignAmount,
            currencyCode: currencyCode
        )
        if !amountValidation.isValid {
            return amountValidation
        }

        // レート入力のバリデーション
        let rateValidation = validateRateInput(
            inputType: inputType,
            value1: value1,
            value2: value2,
            currencyCode: currencyCode
        )
        if !rateValidation.isValid {
            return rateValidation
        }

        // 計算されたレートの妥当性チェック
        let rateCheck = validateCalculatedRate(
            inputType: inputType,
            value1: value1,
            value2: value2
        )
        if !rateCheck.isValid {
            return rateCheck
        }

        return .valid
    }

    /// 簡易バリデーション（フォームの即座チェック用）
    static func validateQuick(
        inputType: RateInputType,
        value1: String,
        value2: String,
        jpyAmount: String,
        foreignAmount: String
    ) -> Bool {
        // 基本的な数値チェックのみ
        guard let jpyValue = Double(jpyAmount), jpyValue > 0,
              let foreignValue = Double(foreignAmount), foreignValue > 0 else {
            return false
        }

        return isValidInput(inputType: inputType, value1: value1, value2: value2)
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

        return jpyValue >= ValidationConstants.minAmountJPY &&
               jpyValue <= ValidationConstants.maxAmountJPY &&
               foreignValue >= 0.01 && foreignValue <= 100_000_000.0
    }

    // MARK: - Helper Methods

    /// 通貨コードに応じた桁数取得
    static func getDecimalPlaces(for currencyCode: String) -> (integer: Int, decimal: Int) {
        let limits = CurrencyLimits.getLimits(for: currencyCode)
        return (integer: 6, decimal: limits.decimalPlaces)
    }

    /// プレースホルダーテキスト生成
    static func getPlaceholderText(for inputType: RateInputType, currencyCode: String) -> (value1: String, value2: String?) {
        switch inputType {
        case .legacy, .perForeign:
            return ("例: 150.0", nil)

        case .exchangeOffice:
            let sampleForeign = CurrencyLimits.getSampleRate(for: currencyCode)
            return ("100", sampleForeign)

        case .perYen:
            let sampleRate = CurrencyLimits.getSampleRate(for: currencyCode)
            if CurrencyLimits.isLargeValueCurrency(currencyCode) {
                return (sampleRate, nil)
            } else {
                return ("0.0067", nil)
            }
        }
    }

    /// 入力方式に応じた説明文を取得
    static func getInputDescription(for inputType: RateInputType, currencyCode: String) -> String {
        switch inputType {
        case .legacy:
            return "従来の入力方式です"
        case .exchangeOffice:
            return "両替所の表示通りに入力してください"
        case .perYen:
            return "1円でいくら\(currencyCode)に両替できるかを入力してください"
        case .perForeign:
            return "1\(currencyCode)が何円かを入力してください"
        }
    }

    // MARK: - Private Validation Methods

    /// 金額の詳細バリデーション
    private static func validateAmounts(
        jpyAmount: String,
        foreignAmount: String,
        currencyCode: String
    ) -> ValidationResult {

        // 空文字チェック
        let trimmedJpy = jpyAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedForeign = foreignAmount.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedJpy.isEmpty || trimmedForeign.isEmpty {
            return .invalid(ValidationConstants.ErrorMessages.missingValue)
        }

        // 数値変換チェック
        guard let jpyValue = Double(trimmedJpy) else {
            return .invalid("日本円の金額を正しく入力してください")
        }
        guard let foreignValue = Double(trimmedForeign) else {
            return .invalid("外貨の金額を正しく入力してください")
        }

        // 負の値・ゼロチェック
        if jpyValue <= 0 {
            return .invalid("日本円の金額は0より大きい値を入力してください")
        }
        if foreignValue <= 0 {
            return .invalid("外貨の金額は0より大きい値を入力してください")
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
    private static func validateRateInput(
        inputType: RateInputType,
        value1: String,
        value2: String,
        currencyCode: String
    ) -> ValidationResult {

        // 空文字チェック
        let trimmedValue1 = value1.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue1.isEmpty {
            return .invalid("レートの値を入力してください")
        }

        // 数値変換チェック
        guard let val1 = Double(trimmedValue1) else {
            return .invalid("レートの値を正しく入力してください")
        }

        // 負の値・ゼロチェック
        if val1 <= 0 {
            return .invalid("レートは正の数を入力してください")
        }

        // 両替所表示の場合の第2値チェック
        if inputType == .exchangeOffice {
            let trimmedValue2 = value2.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedValue2.isEmpty {
                return .invalid("外貨の値も入力してください")
            }

            guard let val2 = Double(trimmedValue2) else {
                return .invalid("外貨の値を正しく入力してください")
            }

            if val2 <= 0 {
                return .invalid("外貨の値は正の数を入力してください")
            }

            // 両替所表示の範囲チェック
            if val1 < ValidationConstants.minExchangeOfficeYen || val1 > ValidationConstants.maxExchangeOfficeYen {
                return .invalid(ValidationConstants.ErrorMessages.invalidExchangeOfficeYen())
            }

            let currencyLimits = CurrencyLimits.getLimits(for: currencyCode)
            if val2 < currencyLimits.minAmount || val2 > currencyLimits.maxAmount {
                return .invalid(ValidationConstants.ErrorMessages.invalidExchangeOfficeForeign(currencyCode))
            }
        }

        return .valid
    }

    /// 計算されたレートの妥当性チェック
    private static func validateCalculatedRate(
        inputType: RateInputType,
        value1: String,
        value2: String
    ) -> ValidationResult {

        let val1 = Double(value1) ?? 0
        let val2 = inputType == .exchangeOffice ? Double(value2) : nil

        let calculatedRate = calculateDisplayRate(inputType: inputType, value1: val1, value2: val2)

        // レート計算可能性チェック
        if calculatedRate <= 0 {
            return .invalid("レートが計算できません。入力値を確認してください")
        }

        // レート範囲チェック
        if calculatedRate < ValidationConstants.minRate || calculatedRate > ValidationConstants.maxRate {
            return .invalid("計算されたレート（\(String(format: "%.3f", calculatedRate))円）が有効範囲外です")
        }

        return .valid
    }
}

// MARK: - Extension for Convenience

extension RateCalculationUtility {

    /// フォーム用の統合バリデーション
    static func validateForForm(
        inputType: RateInputType,
        rateValue1: String,
        rateValue2: String,
        jpyAmount: String,
        foreignAmount: String,
        currencyCode: String
    ) -> (isValid: Bool, errorMessage: String?) {
        let result = validateInput(
            inputType: inputType,
            value1: rateValue1,
            value2: rateValue2,
            jpyAmount: jpyAmount,
            foreignAmount: foreignAmount,
            currencyCode: currencyCode
        )
        return (result.isValid, result.errorMessage)
    }

    /// レート表示文字列の生成
    static func formatDisplayRate(
        inputType: RateInputType,
        value1: String,
        value2: String?,
        currencyCode: String
    ) -> String {
        switch inputType {
        case .legacy, .perForeign:
            return "1\(currencyCode) = \(value1)円"
        case .exchangeOffice:
            let val2 = value2 ?? "0"
            return "\(value1)円 = \(val2)\(currencyCode)"
        case .perYen:
            return "1円 = \(value1)\(currencyCode)"
        }
    }
}
