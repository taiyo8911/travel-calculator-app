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

    // フォームのバリデーション
    private var isFormValid: Bool {
        guard let foreignValue = Double(foreignAmount), foreignValue > 0 else {
            return false
        }
        return !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                // プレビューセクション
                if isFormValid, let foreignValue = Double(foreignAmount) {
                    Section(header: Text("日本円換算")) {
                        if trip.weightedAverageRate > 0 {
                            let jpyValue = foreignValue * trip.weightedAverageRate

                            HStack {
                                Text("日本円換算額:")
                                Spacer()
                                Text(CurrencyFormatter.formatJPY(jpyValue))
                            }

                            HStack {
                                Text("適用レート:")
                                Spacer()
                                Text("1\(trip.currency.code) = \(CurrencyFormatter.formatRate(trip.weightedAverageRate))円")
                            }
                        } else {
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
                    }
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
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func savePurchaseRecord() {
        guard let foreignValue = Double(foreignAmount) else {
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

    // サンプルのTrip - country引数を追加
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
