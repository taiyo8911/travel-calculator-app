//
//  AddPurchaseView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct AddPurchaseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: TravelCalculatorViewModel
    var trip: Trip

    @State private var foreignAmount: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
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

    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                conversionPreviewSection

                if showValidationError, let errorMessage = formState.errorMessage {
                    validationErrorSection(errorMessage)
                }
            }
            .navigationTitle("買い物を追加")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    savePurchase()
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

            TextField("商品・サービス内容", text: $description)

            HStack {
                TextField("金額", text: $foreignAmount)
                    .keyboardType(.decimalPad)

                Text(trip.currency.code)
                    .foregroundColor(.secondary)
            }
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

    private func savePurchase() {
        // 最終バリデーション
        if !isFormValid {
            showValidationError = true
            return
        }

        guard let amount = Double(foreignAmount) else {
            showValidationError = true
            return
        }

        let newPurchase = PurchaseRecord(
            date: date,
            foreignAmount: amount,
            description: description
        )

        viewModel.addPurchaseRecord(newPurchase, toTripWithId: trip.id)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TravelCalculatorViewModel()
        let trip = Trip(
            name: "タイ旅行",
            country: "タイ",
            currency: Currency(code: "THB", name: "タイバーツ"),
            exchangeRecords: [
                ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500)
            ]
        )

        return AddPurchaseView(trip: trip)
            .environmentObject(viewModel)
    }
}
