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

    var sortedExchangeRecords: [ExchangeRecord] {
        return trip.exchangeRecords.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        VStack {
            if trip.exchangeRecords.isEmpty {
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
                List {
                    ForEach(sortedExchangeRecords) { exchange in
                        ExchangeRow(exchange: exchange, currency: trip.currency)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExchange = exchange
                            }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteExchangeRecord(at: indexSet, from: sortedExchangeRecords, inTripWithId: trip.id)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("両替履歴")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingAddExchangeSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExchangeSheet) {
            AddExchangeView(trip: trip)
        }
        .sheet(item: $selectedExchange) { exchange in
            EditExchangeView(trip: trip, exchange: exchange)
        }
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
