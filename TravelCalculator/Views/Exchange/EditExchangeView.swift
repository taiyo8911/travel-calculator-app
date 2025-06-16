//
//  EditExchangeView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/06.
//

import SwiftUI

struct EditExchangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: TravelCalculatorViewModel

    var trip: Trip
    var exchange: ExchangeRecord

    @State private var date: Date
    @State private var jpyAmount: String
    @State private var foreignAmount: String

    // 新しいレート入力方式
    @State private var selectedRateType: RateInputType
    @State private var rateValue1: String
    @State private var rateValue2: String

    // 計算結果のプレビュー用変数
    @State private var calculatedDisplayRate: Double = 0

    // イニシャライザ
    init(trip: Trip, exchange: ExchangeRecord) {
        self.trip = trip
        self.exchange = exchange

        // 基本情報の初期値
        _date = State(initialValue: exchange.date)
        _jpyAmount = State(initialValue: String(format: "%.0f", exchange.jpyAmount))
        _foreignAmount = State(initialValue: String(format: "%.2f", exchange.foreignAmount))

        // レート入力方式の初期値を設定
        let inputType = exchange.rateInputType ?? .legacy
        _selectedRateType = State(initialValue: inputType)

        // 入力値の初期設定
        switch inputType {
        case .legacy:
            _rateValue1 = State(initialValue: String(format: "%.3f", exchange.displayRate))
            _rateValue2 = State(initialValue: "")

        case .exchangeOffice:
            _rateValue1 = State(initialValue: String(format: "%.0f", exchange.inputValue1 ?? 100))
            _rateValue2 = State(initialValue: String(format: "%.0f", exchange.inputValue2 ?? 0))

        case .perYen:
            _rateValue1 = State(initialValue: String(format: "%.3f", exchange.inputValue1 ?? 0))
            _rateValue2 = State(initialValue: "")

        case .perForeign:
            _rateValue1 = State(initialValue: String(format: "%.3f", exchange.inputValue1 ?? exchange.displayRate))
            _rateValue2 = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                rateInputSection
                calculationPreviewSection
            }
            .navigationBarTitle("両替履歴を編集", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveExchangeRecord()
                }
                .disabled(!isFormValid)
            )
            .onAppear {
                recalculateRates()
            }
            .onChange(of: selectedRateType) { _ in recalculateRates() }
            .onChange(of: rateValue1) { _ in recalculateRates() }
            .onChange(of: rateValue2) { _ in recalculateRates() }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section(header: Text("基本情報")) {
            DatePicker("日付", selection: $date, displayedComponents: .date)

            HStack {
                Text("日本円")
                Spacer()
                TextField("日本円", text: $jpyAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("円")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("\(trip.currency.code)金額")
                Spacer()
                TextField("外貨金額", text: $foreignAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text(trip.currency.code)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var rateInputSection: some View {
        Section(header: Text("両替レート")) {
            // 入力方式選択（既存データの場合は従来方式も表示）
            Picker("入力方式", selection: $selectedRateType) {
                ForEach(availableRateTypes, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 4)

            // 既存データの場合の説明
            if exchange.rateInputType == nil || exchange.rateInputType == .legacy {
                Text("既存データは従来方式で保存されています。他の方式に変更して保存することもできます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            // 選択された方式に応じた入力フィールド
            Group {
                switch selectedRateType {
                case .legacy:
                    legacyInputView
                case .exchangeOffice:
                    exchangeOfficeInputView
                case .perYen:
                    perYenInputView
                case .perForeign:
                    perForeignInputView
                }
            }
        }
    }

    private var legacyInputView: some View {
        HStack {
            Text("1\(trip.currency.code) =")
                .foregroundColor(.secondary)

            TextField("レート", text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Text("円")
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var exchangeOfficeInputView: some View {
        HStack {
            TextField("円", text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 80)

            Text("円 =")
                .foregroundColor(.secondary)

            TextField("外貨", text: $rateValue2)
                .keyboardType(.decimalPad)
                .frame(width: 80)

            Text(trip.currency.code)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var perYenInputView: some View {
        HStack {
            Text("1円 =")
                .foregroundColor(.secondary)

            TextField("レート", text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Text(trip.currency.code)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var perForeignInputView: some View {
        HStack {
            Text("1\(trip.currency.code) =")
                .foregroundColor(.secondary)

            TextField("レート", text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Text("円")
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var calculationPreviewSection: some View {
        Group {
            if calculatedDisplayRate > 0 {
                Section(header: Text("レート確認")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("表示レート:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDisplayRate())
                                .fontWeight(.medium)
                        }

                        // 統一形式での表示
                        HStack {
                            Text("統一レート:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("1\(trip.currency.code) = \(String(format: "%.3f", calculatedDisplayRate))円")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // 他の形式での参考表示
                        if selectedRateType != .perYen {
                            HStack {
                                Text("参考 - 1円あたり:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(String(format: "%.3f", calculatedDisplayRate > 0 ? 1.0/calculatedDisplayRate : 0))\(trip.currency.code)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties and Methods

    private var availableRateTypes: [RateInputType] {
        var types: [RateInputType] = [.exchangeOffice, .perYen, .perForeign]

        // 既存データの場合は従来方式も含める
        if exchange.rateInputType == nil || exchange.rateInputType == .legacy {
            types.insert(.legacy, at: 0)
        }

        return types
    }

    private var isFormValid: Bool {
        let validation = RateCalculationUtility.validateInput(
            inputType: selectedRateType,
            value1: rateValue1,
            value2: rateValue2,
            jpyAmount: jpyAmount,
            foreignAmount: foreignAmount,
            currencyCode: trip.currency.code
        )
        return validation.isValid
    }

    private func isRateInputValid() -> Bool {
        return RateCalculationUtility.isValidInput(
            inputType: selectedRateType,
            value1: rateValue1,
            value2: rateValue2
        )
    }

    private func formatDisplayRate() -> String {
        switch selectedRateType {
        case .legacy:
            return "1\(trip.currency.code) = \(rateValue1)円"
        case .exchangeOffice:
            return "\(rateValue1)円 = \(rateValue2)\(trip.currency.code)"
        case .perYen:
            return "1円 = \(rateValue1)\(trip.currency.code)"
        case .perForeign:
            return "1\(trip.currency.code) = \(rateValue1)円"
        }
    }

    private func recalculateRates() {
        guard isRateInputValid() else {
            calculatedDisplayRate = 0
            return
        }

        // 共通ユーティリティを使用してレートを計算
        calculatedDisplayRate = RateCalculationUtility.calculateDisplayRate(
            inputType: selectedRateType,
            value1: Double(rateValue1) ?? 0,
            value2: Double(rateValue2)
        )
    }

    private func saveExchangeRecord() {
        guard let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount),
              isRateInputValid() else {
            return
        }

        let inputValue1 = Double(rateValue1) ?? 0
        let inputValue2 = selectedRateType == .exchangeOffice ? Double(rateValue2) : nil

        // 更新された記録を作成
        let updatedRecord = ExchangeRecord(
            id: exchange.id,
            date: date,
            jpyAmount: jpyValue,
            foreignAmount: foreignValue,
            rateInputType: selectedRateType,
            inputValue1: inputValue1,
            inputValue2: inputValue2
        )

        // ViewModelの更新メソッドを呼び出す
        viewModel.updateExchangeRecord(updatedRecord, inTripWithId: trip.id)

        // 画面を閉じる
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview("既存データ") {
    let viewModel = TravelCalculatorViewModel()
    let currency = Currency(code: "KRW", name: "韓国ウォン")
    let trip = Trip(name: "韓国旅行", country: "韓国", currency: currency)

    let legacyExchange = ExchangeRecord(
        date: Date(),
        jpyAmount: 10000.0,
        displayRate: 0.109,
        foreignAmount: 91700.0
    )

    return EditExchangeView(trip: trip, exchange: legacyExchange)
        .environmentObject(viewModel)
}

#Preview("新形式データ") {
    let viewModel = TravelCalculatorViewModel()
    let currency = Currency(code: "KRW", name: "韓国ウォン")
    let trip = Trip(name: "韓国旅行", country: "韓国", currency: currency)

    let newExchange = ExchangeRecord(
        date: Date(),
        jpyAmount: 10000.0,
        foreignAmount: 91700.0,
        rateInputType: .exchangeOffice,
        inputValue1: 100.0,
        inputValue2: 917.0
    )

    return EditExchangeView(trip: trip, exchange: newExchange)
        .environmentObject(viewModel)
}
