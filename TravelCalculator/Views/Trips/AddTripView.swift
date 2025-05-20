//
//  AddTripView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//


import SwiftUI
import Foundation

struct AddTripView: View {
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel

    // 新しい旅行の詳細を管理するプライベートステート
    @State private var tripName = ""
    @State private var selectedCurrencyIndex = 0

    // 利用可能な通貨リスト
    private let availableCurrencies = Currency.availableCurrencies

    var body: some View {
        NavigationView {
            Form {
                // 旅行名入力セクション
                Section(header: Text("旅行名")) {
                    TextField("旅行名を入力", text: $tripName)
                        .font(.headline)
                }

                // 通貨選択セクション
                Section(header: Text("通貨")) {
                    // 通貨選択ピッカー
                    Picker("通貨", selection: $selectedCurrencyIndex) {
                        ForEach(0..<availableCurrencies.count, id: \.self) { index in
                            HStack(spacing: 6) {
                                Text(flagEmoji(for: availableCurrencies[index].code))
                                Text(availableCurrencies[index].name)
                                    .fontWeight(.medium)
                                Text("(\(availableCurrencies[index].code))")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                            .tag(index)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .onAppear {
                // デフォルトでUSDを選択
                selectedCurrencyIndex = availableCurrencies.firstIndex(where: { $0.code == "USD" }) ?? 0
            }
        }
        .navigationTitle("旅行を追加")
        .navigationBarItems(
            leading: Button("キャンセル") {
                viewModel.closeAddTripSheet()
            },
            trailing: Button("保存") {
                createTrip()
            }
                .disabled(tripName.isEmpty)
        )
    }

    // 旅行を作成するプライベートメソッド
    private func createTrip() {
        guard !tripName.isEmpty else { return }

        let newTrip = Trip(
            name: tripName,
            currency: availableCurrencies[selectedCurrencyIndex]
        )

        viewModel.addTrip(newTrip)
        viewModel.closeAddTripSheet()
    }
}



#Preview {
    NavigationStack {
        AddTripView()
            .environmentObject(TravelCalculatorViewModel())
    }
}
