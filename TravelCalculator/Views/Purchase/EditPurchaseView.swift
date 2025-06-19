//
//  EditPurchaseView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/06.
//

import SwiftUI

struct EditPurchaseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: TravelCalculatorViewModel

    var trip: Trip
    var purchase: PurchaseRecord

    @State private var date: Date
    @State private var foreignAmount: String
    @State private var description: String
    @State private var showValidationError: Bool = false

    // フォーム状態を計算プロパティとして定義
    private var formState: CommonFormValidation.PurchaseFormState {
        CommonFormValidation.PurchaseFormState(
            foreignAmount: foreignAmount,
            description: description,
            currencyCode: trip.currency.code
        )
    }

    // フォームの有効性
    private var isFormValid: Bool {
        return formState.isValid
    }

    // JPY換算プレビューデータ
    private var conversionPreview: PurchaseConversionPreview? {
        return formState.getJPYConversionPreview(using: trip.weightedAverageRate)
    }

    // イニシャライザ
    init(trip: Trip, purchase: PurchaseRecord) {
        self.trip = trip
        self.purchase = purchase

        // 初期値を設定
        _date = State(initialValue: purchase.date)
        _foreignAmount = State(initialValue: String(format: "%.2f", purchase.foreignAmount))
        _description = State(initialValue: purchase.description)
    }

    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                conversionPreviewSection

                if showValidationError, let errorMessage = formState.errorMessage {
                    validationErrorSection(errorMessage)
                }
            }
            .navigationBarTitle("買い物履歴を編集", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    savePurchaseRecord()
                }
                .disabled(!isFormValid)
            )
            .onChange(of: foreignAmount) { _ in updateValidationState() }
            .onChange(of: description) { _ in updateValidationState() }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section(header: Text("買い物情報")) {
            DatePicker("日付", selection: $date, displayedComponents: .date)

            HStack {
                Text("\(trip.currency.code)金額")
                Spacer()
                TextField("外貨金額", text: $foreignAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }

            TextField("買い物メモ", text: $description)
        }
    }

    private var conversionPreviewSection: some View {
        Group {
            if let preview = conversionPreview {
                Section(header: Text("日本円換算")) {
                    HStack {
                        Text("外貨金額:")
                        Spacer()
                        Text(preview.foreignAmountString)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("日本円換算:")
                        Spacer()
                        Text(preview.jpyAmountString)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("適用レート:")
                        Spacer()
                        Text(preview.rateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if !foreignAmount.isEmpty {
                Section(header: Text("日本円換算")) {
                    if trip.weightedAverageRate > 0 {
                        // 無効な金額の場合
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("正しい金額を入力してください")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    } else {
                        // 両替記録がない場合
                        noExchangeRateWarning
                    }
                }
            } else if trip.weightedAverageRate <= 0 {
                Section(header: Text("日本円換算")) {
                    noExchangeRateWarning
                }
            }
        }
    }

    private var noExchangeRateWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading) {
                Text("両替記録が無いため計算できません")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                Text("両替を記録すると自動的に日本円換算されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func validationErrorSection(_ errorMessage: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    // MARK: - Helper Methods

    private func updateValidationState() {
        // 入力中はバリデーションエラーを隠す
        if showValidationError {
            showValidationError = false
        }
    }

    private func savePurchaseRecord() {
        // 最終バリデーション
        if !isFormValid {
            showValidationError = true
            return
        }

        guard let foreignValue = Double(foreignAmount) else {
            showValidationError = true
            return
        }

        // 更新された記録を作成
        let updatedRecord = PurchaseRecord(
            id: purchase.id,
            date: date,
            foreignAmount: foreignValue,
            description: description
        )

        // ViewModelの更新メソッドを呼び出す
        viewModel.updatePurchaseRecord(updatedRecord, inTripWithId: trip.id)

        // 画面を閉じる
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    let viewModel = TravelCalculatorViewModel()

    // サンプルのCurrency
    let currency = Currency(code: "USD", name: "US Dollar")

    // サンプルのTrip
    let trip = Trip(name: "アメリカ旅行", country: "アメリカ", currency: currency)

    // サンプルの買い物記録
    let purchase = PurchaseRecord(
        date: Date(),
        foreignAmount: 50.0,
        description: "お土産"
    )

    EditPurchaseView(trip: trip, purchase: purchase)
        .environmentObject(viewModel)
}
