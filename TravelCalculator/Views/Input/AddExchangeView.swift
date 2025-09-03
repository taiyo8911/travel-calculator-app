//
//  AddExchangeView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct AddExchangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: TravelCalculatorViewModel
    var trip: Trip

    @State private var jpyAmount: String = ""
    @State private var foreignAmount: String = ""
    @State private var date: Date = Date()

    // 新しいレート入力方式
    @State private var selectedRateType: RateInputType = .exchangeOffice
    @State private var rateValue1: String = "" // 第1の値
    @State private var rateValue2: String = "" // 第2の値（両替所表示用）

    // バリデーション状態
    @State private var showValidationError: Bool = false

    // フォーム状態を計算プロパティとして定義
    private var formState: CommonFormValidation.ExchangeFormState {
        CommonFormValidation.ExchangeFormState(
            jpyAmount: jpyAmount,
            foreignAmount: foreignAmount,
            rateInputType: selectedRateType,
            rateValue1: rateValue1,
            rateValue2: rateValue2,
            currencyCode: trip.currency.code
        )
    }

    // フォームの有効性
    private var isFormValid: Bool {
        return formState.isValid
    }

    // 計算プレビューデータ
    private var calculationPreview: ExchangeCalculationPreview? {
        return formState.getCalculationPreview()
    }

    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                rateInputSection
                calculationPreviewSection

                if showValidationError, let errorMessage = formState.errorMessage {
                    validationErrorSection(errorMessage)
                }
            }
            .navigationTitle("両替を追加")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveExchange()
                }
                .disabled(!isFormValid)
            )
            .onChange(of: selectedRateType) { _ in
                resetRateValues()
                showValidationError = false
            }
            .onChange(of: rateValue1) { _ in updateValidationState() }
            .onChange(of: rateValue2) { _ in updateValidationState() }
            .onChange(of: jpyAmount) { _ in updateValidationState() }
            .onChange(of: foreignAmount) { _ in updateValidationState() }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section(header: Text("基本情報")) {
            DatePicker("日付", selection: $date, displayedComponents: .date)

            HStack {
                TextField("両替する日本円", text: $jpyAmount)
                    .keyboardType(.decimalPad)
                Text("円")
                    .foregroundColor(.secondary)
            }

            HStack {
                TextField("受け取った\(trip.currency.name)", text: $foreignAmount)
                    .keyboardType(.decimalPad)
                Text(trip.currency.code)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var rateInputSection: some View {
        Section(header: Text("両替レート（いずれか1つの方式で入力）")) {
            // 入力方式選択
            Picker("入力方式", selection: $selectedRateType) {
                ForEach(RateInputType.allCases.filter { $0 != .legacy }, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 4)

            // 説明文
            Text(CommonFormValidation.getInputDescription(for: selectedRateType, currencyCode: trip.currency.code))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)

            // 選択された方式に応じた入力フィールド
            Group {
                switch selectedRateType {
                case .exchangeOffice:
                    exchangeOfficeInputView
                case .perYen:
                    perYenInputView
                case .perForeign:
                    perForeignInputView
                case .legacy:
                    EmptyView() // 新規入力では使用しない
                }
            }
        }
    }

    private var exchangeOfficeInputView: some View {
        let placeholders = CommonFormValidation.getPlaceholderTexts(for: .exchangeOffice, currencyCode: trip.currency.code)

        return HStack {
            TextField(placeholders.value1, text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 80)

            Text("円 =")
                .foregroundColor(.secondary)

            TextField(placeholders.value2 ?? "", text: $rateValue2)
                .keyboardType(.decimalPad)
                .frame(width: 80)

            Text(trip.currency.code)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var perYenInputView: some View {
        let placeholders = CommonFormValidation.getPlaceholderTexts(for: .perYen, currencyCode: trip.currency.code)

        return HStack {
            Text("1円 =")
                .foregroundColor(.secondary)

            TextField(placeholders.value1, text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Text(trip.currency.code)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var perForeignInputView: some View {
        let placeholders = CommonFormValidation.getPlaceholderTexts(for: .perForeign, currencyCode: trip.currency.code)

        return HStack {
            Text("1\(trip.currency.code) =")
                .foregroundColor(.secondary)

            TextField(placeholders.value1, text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Text("円")
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var calculationPreviewSection: some View {
        Group {
            if let preview = calculationPreview {
                Section(header: Text("レート確認")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("表示レート:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(preview.displayRateString)
                                .fontWeight(.medium)
                        }

                        // 統一形式での表示
                        HStack {
                            Text("統一レート:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("1\(trip.currency.code) = \(CommonFormValidation.formatRateForDisplay(preview.displayRate))円")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // 実質レートと手数料
                        HStack {
                            Text("実質レート:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("1\(trip.currency.code) = \(CommonFormValidation.formatRateForDisplay(preview.actualRate))円")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("手数料:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(String(format: "%.2f", preview.feePercentage))%")
                                .font(.caption)
                                .foregroundColor(preview.isHighFee ? .red : .secondary)
                        }

                        if preview.isHighFee {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("手数料が3%を超えています")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        // 他の形式での参考表示
                        if selectedRateType != .perYen {
                            HStack {
                                Text("参考 - 1円あたり:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(String(format: "%.3f", preview.displayRate > 0 ? 1.0/preview.displayRate : 0))\(trip.currency.code)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
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

    private func resetRateValues() {
        rateValue1 = ""
        rateValue2 = ""
    }

    private func updateValidationState() {
        // 入力中はバリデーションエラーを隠す
        if showValidationError {
            showValidationError = false
        }
    }

    private func saveExchange() {
        // 最終バリデーション
        if !isFormValid {
            showValidationError = true
            return
        }

        guard let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount) else {
            showValidationError = true
            return
        }

        let inputValue1 = Double(rateValue1) ?? 0
        let inputValue2 = selectedRateType == .exchangeOffice ? Double(rateValue2) : nil

        let newExchange = ExchangeRecord(
            date: date,
            jpyAmount: jpyValue,
            foreignAmount: foreignValue,
            rateInputType: selectedRateType,
            inputValue1: inputValue1,
            inputValue2: inputValue2
        )

        viewModel.addExchangeRecord(newExchange, toTripWithId: trip.id)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TravelCalculatorViewModel()
        let trip = Trip(
            name: "韓国旅行",
            country: "韓国",
            currency: Currency(code: "KRW", name: "韓国ウォン")
        )

        return AddExchangeView(trip: trip)
            .environmentObject(viewModel)
    }
}
