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
    @State private var displayRate: String = ""
    @State private var date: Date = Date()

    // 計算結果のプレビュー用変数
    @State private var actualRate: Double = 0
    @State private var feePercentage: Double = 0
    @State private var feeAmount: Double = 0

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("両替情報")) {
                    DatePicker("日付", selection: $date, displayedComponents: .date)

                    HStack {
                        TextField("表示レート (1\(trip.currency.code)あたりの円)", text: $displayRate)
                            .keyboardType(.decimalPad)
                            .onChange(of: displayRate) { _ in calculateRates() }

                        Text("円")
                            .foregroundColor(.secondary)
                    }

                    TextField("両替する日本円", text: $jpyAmount)
                        .keyboardType(.decimalPad)
                        .onChange(of: jpyAmount) { _ in calculateRates() }

                    HStack {
                        TextField("受け取った\(trip.currency.name)", text: $foreignAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: foreignAmount) { _ in calculateRates() }

                        Text(trip.currency.code)
                            .foregroundColor(.secondary)
                    }
                }

                if actualRate > 0 && foreignAmount.isEmpty == false && jpyAmount.isEmpty == false {
                    Section(header: Text("計算結果")) {
                        HStack {
                            Text("実質レート:")
                            Spacer()
                            Text("1\(trip.currency.code) = \(CurrencyFormatter.formatRate(actualRate))円")
                        }

                        HStack {
                            Text("手数料:")
                            Spacer()
                            HStack(spacing: 4) {
                                Text(CurrencyFormatter.formatPercent(feePercentage))
                                Text("(\(CurrencyFormatter.formatJPY(feeAmount)))")
                                    .font(.footnote)
                            }
                            .foregroundColor(feePercentage > 3.0 ? .red : .green)
                        }

                        if feePercentage > 3.0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("手数料が高めです！別の両替所も検討してください")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
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
        }
    }

    private var isFormValid: Bool {
        guard let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount),
              let rateValue = Double(displayRate) else {
            return false
        }

        return jpyValue > 0 && foreignValue > 0 && rateValue > 0
    }

    private func calculateRates() {
        guard let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount),
              jpyValue > 0,
              foreignValue > 0 else {
            actualRate = 0
            feePercentage = 0
            feeAmount = 0
            return
        }

        actualRate = jpyValue / foreignValue

        if let displayRateValue = Double(displayRate), displayRateValue > 0 {
            feePercentage = ((actualRate - displayRateValue) / displayRateValue) * 100

            // 手数料額を計算
            let theoreticalJPY = foreignValue * displayRateValue
            feeAmount = jpyValue - theoreticalJPY
        } else {
            feePercentage = 0
            feeAmount = 0
        }
    }

    private func saveExchange() {
        guard let jpyValue = Double(jpyAmount),
              let foreignValue = Double(foreignAmount),
              let displayRateValue = Double(displayRate) else {
            return
        }

        let newExchange = ExchangeRecord(
            date: date,
            jpyAmount: jpyValue,
            displayRate: displayRateValue,
            foreignAmount: foreignValue
        )

        viewModel.addExchangeRecord(newExchange, toTripWithId: trip.id)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TravelCalculatorViewModel()
        let trip = Trip(
            name: "タイ旅行",
            country: "タイ",
            currency: Currency(code: "THB", name: "タイバーツ")
        )

        return AddExchangeView(trip: trip)
            .environmentObject(viewModel)
    }
}
