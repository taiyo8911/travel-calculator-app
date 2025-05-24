//
//  AddTripView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.



import SwiftUI
import Foundation

struct AddTripView: View {
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel

    // 新しい旅行の詳細を管理するプライベートステート
    @State private var tripName = ""
    @State private var country = ""
    @State private var selectedCurrencyIndex = 0
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(60*60*24*7) // デフォルトは1週間後

    // 日付バリデーション
    private var isDateRangeValid: Bool {
        return startDate <= endDate
    }

    // フォームバリデーション
    private var isFormValid: Bool {
        return !tripName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isDateRangeValid
    }

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

                // 国名入力セクション
                Section(header: Text("国名")) {
                    TextField("国名を入力", text: $country)
                        .font(.headline)
                }

                // 旅行期間セクション
                Section(header: Text("旅行期間")) {
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { newValue in
                            // 開始日が終了日より後の場合は、終了日を開始日に合わせる
                            if newValue > endDate {
                                endDate = newValue
                            }
                        }

                    DatePicker("終了日", selection: $endDate, in: startDate..., displayedComponents: .date)

                    // 旅行日数を表示
                    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0 + 1
                    Text("旅行日数: \(days)日")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                .disabled(!isFormValid)
        )
    }

    // 旅行を作成するプライベートメソッド
    private func createTrip() {
        guard isFormValid else { return }

        let newTrip = Trip(
            name: tripName.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            currency: availableCurrencies[selectedCurrencyIndex],
            startDate: startDate,
            endDate: endDate
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
