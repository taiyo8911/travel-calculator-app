//
//  ExchangeListView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct ExchangeListView: View {
    @EnvironmentObject var viewModel: TravelCalculatorViewModel
    var trip: Trip

    @State private var showingAddExchangeSheet = false
    @State private var selectedExchange: ExchangeRecord? = nil

    // 最新のTrip情報を取得
    private var currentTrip: Trip {
        viewModel.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    var sortedExchangeRecords: [ExchangeRecord] {
        return currentTrip.exchangeRecords.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        VStack {
            if currentTrip.exchangeRecords.isEmpty {
                // 両替履歴がない場合の表示
                VStack(spacing: 20) {
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("両替履歴がありません")
                        .font(.headline)

                    Text("「追加」ボタンをタップして最初の両替を記録しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        showingAddExchangeSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("両替を追加")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                // 統計情報ヘッダー
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("合計両替額")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.formatJPY(totalJPYAmount))
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("取得外貨")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.formatForeign(totalForeignAmount, currencyCode: currentTrip.currency.code))
                                .font(.headline)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("平均レート")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("1\(currentTrip.currency.code) = \(CurrencyFormatter.formatRate(currentTrip.weightedAverageRate))円")
                                .font(.subheadline)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("両替回数")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(currentTrip.exchangeRecords.count)回")
                                .font(.subheadline)
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
                    ForEach(sortedExchangeRecords) { exchange in
                        ExchangeRow(exchange: exchange, currency: currentTrip.currency)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExchange = exchange
                            }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteExchangeRecord(at: indexSet, from: sortedExchangeRecords, inTripWithId: currentTrip.id)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("両替履歴")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddExchangeSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExchangeSheet) {
            AddExchangeView(trip: currentTrip)
        }
        .sheet(item: $selectedExchange) { exchange in
            EditExchangeView(trip: currentTrip, exchange: exchange)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    // 計算プロパティ
    private var totalJPYAmount: Double {
        currentTrip.exchangeRecords.reduce(0) { $0 + $1.jpyAmount }
    }

    private var totalForeignAmount: Double {
        currentTrip.exchangeRecords.reduce(0) { $0 + $1.foreignAmount }
    }
}

struct ExchangeRow: View {
    var exchange: ExchangeRecord
    var currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(CurrencyFormatter.formatDate(exchange.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if exchange.isHighFee {
                    Text("高手数料 \(CurrencyFormatter.formatPercent(exchange.feePercentage))")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                } else {
                    Text("手数料 \(CurrencyFormatter.formatPercent(exchange.feePercentage))")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("日本円")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(CurrencyFormatter.formatJPY(exchange.jpyAmount))
                        .font(.headline)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                    .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text(currency.name)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(CurrencyFormatter.formatForeign(exchange.foreignAmount, currencyCode: currency.code))
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("実質レート")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("1\(currency.code) = \(CurrencyFormatter.formatRate(exchange.actualRate))円")
                        .font(.headline)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct ExchangeListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TravelCalculatorViewModel()
        let trip = Trip(
            name: "タイ旅行",
            country: "タイ",
            currency: Currency(code: "THB", name: "タイバーツ"),
            exchangeRecords: [
                ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500),
                ExchangeRecord(date: Date().addingTimeInterval(-86400), jpyAmount: 5000, displayRate: 3.9, foreignAmount: 1200)
            ]
        )

        return NavigationView {
            ExchangeListView(trip: trip)
                .environmentObject(viewModel)
        }
    }
}
