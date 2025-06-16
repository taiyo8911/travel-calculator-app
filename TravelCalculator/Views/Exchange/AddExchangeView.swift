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

    // 計算結果のプレビュー用変数
    @State private var calculatedDisplayRate: Double = 0

    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                rateInputSection
                calculationPreviewSection
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
        return HStack {
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
        return HStack {
            Text("1円 =")
                .foregroundColor(.secondary)

            TextField("", text: $rateValue1)
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Text(trip.currency.code)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var perForeignInputView: some View {
        return HStack {
            Text("1\(trip.currency.code) =")
                .foregroundColor(.secondary)

            TextField("", text: $rateValue1)
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

                        // 他の形式での表示
                        if selectedRateType != .perForeign {
                            HStack {
                                Text("1\(trip.currency.code)あたり:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(String(format: "%.3f", calculatedDisplayRate))円")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if selectedRateType != .perYen {
                            HStack {
                                Text("1円あたり:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(String(format: "%.3f", 1.0/calculatedDisplayRate))\(trip.currency.code)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private var isFormValid: Bool {
        guard let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount),
              jpyValue > 0, foreignValue > 0 else {
            return false
        }

        return isRateInputValid()
    }

    private func isRateInputValid() -> Bool {
        switch selectedRateType {
        case .exchangeOffice:
            guard let value1 = Double(rateValue1),
                  let value2 = Double(rateValue2),
                  value1 > 0, value2 > 0 else {
                return false
            }
            return true

        case .perYen, .perForeign:
            guard let value1 = Double(rateValue1),
                  value1 > 0 else {
                return false
            }
            return true

        case .legacy:
            return false // 新規入力では使用しない
        }
    }

    private func formatDisplayRate() -> String {
        switch selectedRateType {
        case .exchangeOffice:
            return "\(rateValue1)円 = \(rateValue2)\(trip.currency.code)"
        case .perYen:
            return "1円 = \(rateValue1)\(trip.currency.code)"
        case .perForeign:
            return "1\(trip.currency.code) = \(rateValue1)円"
        case .legacy:
            return ""
        }
    }

    private func recalculateRates() {
        guard isRateInputValid() else {
            calculatedDisplayRate = 0
            return
        }

        // 表示レートを計算
        switch selectedRateType {
        case .exchangeOffice:
            let value1 = Double(rateValue1) ?? 0
            let value2 = Double(rateValue2) ?? 0
            calculatedDisplayRate = value2 != 0 ? value1 / value2 : 0

        case .perYen:
            let value1 = Double(rateValue1) ?? 0
            calculatedDisplayRate = value1 != 0 ? 1.0 / value1 : 0

        case .perForeign:
            calculatedDisplayRate = Double(rateValue1) ?? 0

        case .legacy:
            calculatedDisplayRate = 0
        }
    }

    private func saveExchange() {
        guard let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount),
              isRateInputValid() else {
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
