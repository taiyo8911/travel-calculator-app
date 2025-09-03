//
//  CommonFormValidation.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/06/16.
//

import Foundation

/// 共通フォームバリデーション機能
struct CommonFormValidation {

    // MARK: - Exchange Form Validation

    /// 両替フォームのバリデーション状態
    struct ExchangeFormState {
        let jpyAmount: String
        let foreignAmount: String
        let rateInputType: RateInputType
        let rateValue1: String
        let rateValue2: String
        let currencyCode: String

        /// フォームが有効かどうか
        var isValid: Bool {
            return CommonFormValidation.validateExchangeForm(self).isValid
        }

        /// エラーメッセージ
        var errorMessage: String? {
            return CommonFormValidation.validateExchangeForm(self).errorMessage
        }

        /// 計算されたレート
        var calculatedRate: Double {
            guard isValid else { return 0 }
            let val1 = Double(rateValue1) ?? 0
            let val2 = rateInputType == .exchangeOffice ? Double(rateValue2) : nil
            return RateCalculationUtility.calculateDisplayRate(
                inputType: rateInputType,
                value1: val1,
                value2: val2
            )
        }
    }

    /// 両替フォームのバリデーション
    static func validateExchangeForm(_ state: ExchangeFormState) -> ValidationResult {
        return RateCalculationUtility.validateInput(
            inputType: state.rateInputType,
            value1: state.rateValue1,
            value2: state.rateValue2,
            jpyAmount: state.jpyAmount,
            foreignAmount: state.foreignAmount,
            currencyCode: state.currencyCode
        )
    }

    /// 両替フォームのクイックバリデーション（リアルタイム用）
    static func validateExchangeFormQuick(_ state: ExchangeFormState) -> Bool {
        return RateCalculationUtility.validateQuick(
            inputType: state.rateInputType,
            value1: state.rateValue1,
            value2: state.rateValue2,
            jpyAmount: state.jpyAmount,
            foreignAmount: state.foreignAmount
        )
    }

    // MARK: - Purchase Form Validation

    /// 買い物フォームのバリデーション状態
    struct PurchaseFormState {
        let foreignAmount: String
        let description: String
        let currencyCode: String

        /// フォームが有効かどうか
        var isValid: Bool {
            return CommonFormValidation.validatePurchaseForm(self).isValid
        }

        /// エラーメッセージ
        var errorMessage: String? {
            return CommonFormValidation.validatePurchaseForm(self).errorMessage
        }
    }

    /// 買い物フォームのバリデーション
    static func validatePurchaseForm(_ state: PurchaseFormState) -> ValidationResult {
        // 金額のバリデーション
        let trimmedAmount = state.foreignAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedAmount.isEmpty {
            return .invalid("金額を入力してください")
        }

        guard let amount = Double(trimmedAmount) else {
            return .invalid("正しい金額を入力してください")
        }

        if amount <= 0 {
            return .invalid("金額は0より大きい値を入力してください")
        }

        let currencyLimits = CurrencyLimits.getLimits(for: state.currencyCode)
        if amount < currencyLimits.minAmount || amount > currencyLimits.maxAmount {
            return .invalid(ValidationConstants.ErrorMessages.invalidAmountForCurrency(state.currencyCode))
        }

        // 説明のバリデーション（必須入力）
        return ValidationConstants.validatePurchaseDescription(state.description)
    }

    // MARK: - Trip Form Validation

    /// 旅行フォームのバリデーション状態
    struct TripFormState {
        let name: String
        let country: String
        let startDate: Date
        let endDate: Date

        /// フォームが有効かどうか
        var isValid: Bool {
            return CommonFormValidation.validateTripForm(self).isValid
        }

        /// エラーメッセージ
        var errorMessage: String? {
            return CommonFormValidation.validateTripForm(self).errorMessage
        }
    }

    /// 旅行フォームのバリデーション
    static func validateTripForm(_ state: TripFormState) -> ValidationResult {
        // 旅行名のバリデーション
        let nameValidation = ValidationConstants.validateTripName(state.name)
        if !nameValidation.isValid {
            return nameValidation
        }

        // 国名のバリデーション
        let countryValidation = ValidationConstants.validateCountryName(state.country)
        if !countryValidation.isValid {
            return countryValidation
        }

        // 日付範囲のバリデーション
        return ValidationConstants.validateDateRange(startDate: state.startDate, endDate: state.endDate)
    }

    // MARK: - Helper Methods

    /// レート入力方式に応じたプレースホルダーを取得
    static func getPlaceholderTexts(for inputType: RateInputType, currencyCode: String) -> (value1: String, value2: String?) {
        return RateCalculationUtility.getPlaceholderText(for: inputType, currencyCode: currencyCode)
    }

    /// レート入力方式に応じた説明文を取得
    static func getInputDescription(for inputType: RateInputType, currencyCode: String) -> String {
        return RateCalculationUtility.getInputDescription(for: inputType, currencyCode: currencyCode)
    }

    /// 通貨フォーマットのヘルパー
    static func formatAmountForDisplay(_ amount: Double, currencyCode: String) -> String {
        return CurrencyFormatter.formatForeign(amount, currencyCode: currencyCode)
    }

    /// JPY金額フォーマット
    static func formatJPYForDisplay(_ amount: Double) -> String {
        return CurrencyFormatter.formatJPY(amount)
    }

    /// レートフォーマット
    static func formatRateForDisplay(_ rate: Double) -> String {
        return CurrencyFormatter.formatRate(rate)
    }
}

// MARK: - Validation Extensions

extension CommonFormValidation.ExchangeFormState {

    /// 計算プレビュー用の情報を取得
    func getCalculationPreview() -> ExchangeCalculationPreview? {
        guard isValid,
              let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount) else {
            return nil
        }

        let displayRate = calculatedRate
        let actualRate = jpyValue / foreignValue
        let feePercentage = ((actualRate - displayRate) / displayRate) * 100

        return ExchangeCalculationPreview(
            displayRate: displayRate,
            actualRate: actualRate,
            feePercentage: feePercentage,
            isHighFee: feePercentage > 3.0,
            displayRateString: RateCalculationUtility.formatDisplayRate(
                inputType: rateInputType,
                value1: rateValue1,
                value2: rateInputType == .exchangeOffice ? rateValue2 : nil,
                currencyCode: currencyCode
            )
        )
    }
}

extension CommonFormValidation.PurchaseFormState {

    /// JPY換算プレビューを取得
    func getJPYConversionPreview(using rate: Double) -> PurchaseConversionPreview? {
        guard isValid,
              let amount = Double(foreignAmount),
              rate > 0 else {
            return nil
        }

        let jpyAmount = amount * rate

        return PurchaseConversionPreview(
            foreignAmount: amount,
            jpyAmount: jpyAmount,
            rate: rate,
            foreignAmountString: CommonFormValidation.formatAmountForDisplay(amount, currencyCode: currencyCode),
            jpyAmountString: CommonFormValidation.formatJPYForDisplay(jpyAmount),
            rateString: "1\(currencyCode) = \(CommonFormValidation.formatRateForDisplay(rate))円"
        )
    }
}

// MARK: - Preview Data Structures

/// 両替計算プレビューデータ
struct ExchangeCalculationPreview {
    let displayRate: Double
    let actualRate: Double
    let feePercentage: Double
    let isHighFee: Bool
    let displayRateString: String
}

/// 買い物円換算プレビューデータ
struct PurchaseConversionPreview {
    let foreignAmount: Double
    let jpyAmount: Double
    let rate: Double
    let foreignAmountString: String
    let jpyAmountString: String
    let rateString: String
}
