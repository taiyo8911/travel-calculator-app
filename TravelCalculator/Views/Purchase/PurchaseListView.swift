//
//  PurchaseListView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct PurchaseListView: View {
    @EnvironmentObject var viewModel: TravelCalculatorViewModel
    var trip: Trip

    @State private var showingAddPurchaseSheet = false
    @State private var selectedPurchase: PurchaseRecord? = nil

    // 最新のTrip情報を取得
    private var currentTrip: Trip {
        viewModel.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    var sortedPurchaseRecords: [PurchaseRecord] {
        return currentTrip.purchaseRecords.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        VStack {
            if currentTrip.purchaseRecords.isEmpty {
                // 買い物履歴がない場合の表示
                VStack(spacing: 20) {
                    Image(systemName: "cart.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("買い物履歴がありません")
                        .font(.headline)

                    Text("「追加」ボタンをタップして最初の買い物を記録しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        showingAddPurchaseSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("買い物を追加")
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                // 統計情報ヘッダー
                VStack(spacing: 8) {
                    if currentTrip.weightedAverageRate > 0 {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("合計支出額")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(CurrencyFormatter.formatJPY(currentTrip.totalExpenseInJPY))
                                    .font(.headline)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("外貨支出額")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(CurrencyFormatter.formatForeign(totalForeignSpent, currencyCode: currentTrip.currency.code))
                                    .font(.headline)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("適用レート")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("1\(currentTrip.currency.code) = \(CurrencyFormatter.formatRate(currentTrip.weightedAverageRate))円")
                                    .font(.subheadline)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("買い物回数")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(currentTrip.purchaseRecords.count)回")
                                    .font(.subheadline)
                            }
                        }
                    } else {
                        // 両替記録がない場合の警告表示
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("両替記録がないため日本円換算ができません")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                Spacer()
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("外貨支出額")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(CurrencyFormatter.formatForeign(totalForeignSpent, currencyCode: currentTrip.currency.code))
                                        .font(.headline)
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("買い物回数")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(currentTrip.purchaseRecords.count)回")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)

                List {
                    ForEach(sortedPurchaseRecords) { purchase in
                        PurchaseRow(
                            purchase: purchase,
                            currency: currentTrip.currency,
                            weightedAverageRate: currentTrip.weightedAverageRate
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPurchase = purchase
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deletePurchaseRecord(at: indexSet, from: sortedPurchaseRecords, inTripWithId: currentTrip.id)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("買い物履歴")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddPurchaseSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPurchaseSheet) {
            AddPurchaseView(trip: currentTrip)
        }
        .sheet(item: $selectedPurchase) { purchase in
            EditPurchaseView(trip: currentTrip, purchase: purchase)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // 計算プロパティ
    private var totalForeignSpent: Double {
        currentTrip.purchaseRecords.reduce(0) { $0 + $1.foreignAmount }
    }
}

struct PurchaseRow: View {
    var purchase: PurchaseRecord
    var currency: Currency
    var weightedAverageRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(CurrencyFormatter.formatDate(purchase.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }

            if !purchase.description.isEmpty {
                Text(purchase.description)
                    .font(.headline)
            }

            HStack {
                HStack {
                    Text(CurrencyFormatter.formatForeign(purchase.foreignAmount, currencyCode: currency.code))
                        .font(.headline)
                        .frame(minWidth: 100, alignment: .trailing)

                    Image(systemName: "equal")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    if weightedAverageRate > 0 {
                        Text(CurrencyFormatter.formatJPY(purchase.jpyAmount(using: weightedAverageRate)))
                            .font(.headline)
                            .frame(minWidth: 100, alignment: .leading)
                    } else {
                        Text("計算不可")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .frame(minWidth: 100, alignment: .leading)
                    }
                }

                Spacer()
            }

            // 適用レート情報
            if weightedAverageRate > 0 {
                HStack {
                    Text("レート: 1\(currency.code) = ")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(CurrencyFormatter.formatRate(weightedAverageRate))円")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("両替記録が無いため日本円換算できません")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct PurchaseListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TravelCalculatorViewModel()
        let trip = Trip(
            name: "タイ旅行",
            country: "タイ",
            currency: Currency(code: "THB", name: "タイバーツ"),
            exchangeRecords: [
                ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500)
            ],
            purchaseRecords: [
                PurchaseRecord(date: Date(), foreignAmount: 500, description: "お土産"),
                PurchaseRecord(date: Date().addingTimeInterval(-43200), foreignAmount: 200, description: "ランチ")
            ]
        )

        return NavigationView {
            PurchaseListView(trip: trip)
                .environmentObject(viewModel)
        }
    }
}
