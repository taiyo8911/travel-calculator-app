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

    var body: some View {
        NavigationView {
            Form {
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

                if let amount = Double(foreignAmount), amount > 0 {
                    Section(header: Text("日本円換算")) {
                        if trip.weightedAverageRate > 0 {
                            HStack {
                                Text("日本円:")
                                Spacer()
                                Text(CurrencyFormatter.formatJPY(calculateJPYAmount()))
                                    .fontWeight(.semibold)
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
        }
    }

    private var isFormValid: Bool {
        guard let amount = Double(foreignAmount) else {
            return false
        }
        return amount > 0
    }

    // 日本円換算額を計算
    private func calculateJPYAmount() -> Double {
        guard let amount = Double(foreignAmount) else {
            return 0
        }

        return amount * trip.weightedAverageRate
    }

    private func savePurchase() {
        guard let amount = Double(foreignAmount) else {
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
