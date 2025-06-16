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
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    summaryHeaderView
                    exchangeListView
                }
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
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
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
    }

    // MARK: - Summary Header

    private var summaryHeaderView: some View {
        VStack(spacing: 12) {
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

            // 入力方式の内訳表示
            if hasMultipleInputTypes {
                inputTypeBreakdownView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // 入力方式の内訳表示
    private var inputTypeBreakdownView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("入力方式の内訳")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                ForEach(inputTypeBreakdown, id: \.type) { breakdown in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForInputType(breakdown.type))
                            .frame(width: 8, height: 8)

                        Text(breakdown.type.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("(\(breakdown.count))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if breakdown.type != inputTypeBreakdown.last?.type {
                        Text("・")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Exchange List

    private var exchangeListView: some View {
        List {
            ForEach(sortedExchangeRecords) { exchange in
                EnhancedExchangeRow(exchange: exchange, currency: currentTrip.currency)
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

    // MARK: - Helper Properties and Methods

    private var totalJPYAmount: Double {
        currentTrip.exchangeRecords.reduce(0) { $0 + $1.jpyAmount }
    }

    private var totalForeignAmount: Double {
        currentTrip.exchangeRecords.reduce(0) { $0 + $1.foreignAmount }
    }

    private var hasMultipleInputTypes: Bool {
        let types = Set(currentTrip.exchangeRecords.compactMap { $0.rateInputType ?? .legacy })
        return types.count > 1
    }

    private var inputTypeBreakdown: [(type: RateInputType, count: Int)] {
        let types = currentTrip.exchangeRecords.map { $0.rateInputType ?? .legacy }
        let groupedTypes = Dictionary(grouping: types) { $0 }

        return groupedTypes.map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private func colorForInputType(_ type: RateInputType) -> Color {
        switch type {
        case .legacy:
            return .gray
        case .exchangeOffice:
            return .blue
        case .perYen:
            return .green
        case .perForeign:
            return .orange
        }
    }
}

// MARK: - Enhanced Exchange Row

struct EnhancedExchangeRow: View {
    var exchange: ExchangeRecord
    var currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ヘッダー行
            HStack {
                HStack(spacing: 8) {
                    // 入力方式インジケーター
                    Circle()
                        .fill(colorForInputType(exchange.rateInputType ?? .legacy))
                        .frame(width: 8, height: 8)

                    Text(CurrencyFormatter.formatDate(exchange.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 入力方式表示
                Text((exchange.rateInputType ?? .legacy).displayName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorForInputType(exchange.rateInputType ?? .legacy))
                    .cornerRadius(4)
            }

            // レート表示セクション
            rateDisplaySection

            // 両替詳細セクション
            exchangeDetailsSection

            // 実質レートセクション
            actualRateSection
        }
        .padding(.vertical, 8)
    }

    // MARK: - Sub Views

    private var rateDisplaySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("入力レート:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("(\((exchange.rateInputType ?? .legacy).displayName))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorForInputType(exchange.rateInputType ?? .legacy).opacity(0.2))
                    .cornerRadius(4)

                Spacer()
            }

            Text(exchange.displayRateString(currencyCode: currency.code))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private var exchangeDetailsSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // 日本円
            VStack(alignment: .leading, spacing: 2) {
                Text("日本円")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(CurrencyFormatter.formatJPY(exchange.jpyAmount))
                    .font(.headline)
            }

            // 矢印
            Image(systemName: "arrow.right")
                .foregroundColor(.blue)
                .font(.title3)

            // 外貨
            VStack(alignment: .leading, spacing: 2) {
                Text(currency.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(CurrencyFormatter.formatForeign(exchange.foreignAmount, currencyCode: currency.code))
                    .font(.headline)
            }

            Spacer()
        }
    }

    private var actualRateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("実質レート")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("1\(currency.code) = \(CurrencyFormatter.formatRate(exchange.actualRate))円")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()
            }
        }
    }

    // MARK: - Helper Methods

    private func colorForInputType(_ type: RateInputType) -> Color {
        switch type {
        case .legacy:
            return .gray
        case .exchangeOffice:
            return .blue
        case .perYen:
            return .green
        case .perForeign:
            return .orange
        }
    }
}

struct ExchangeListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TravelCalculatorViewModel()

        // 異なる入力方式の両替記録を含むサンプルデータ
        let currency = Currency(code: "KRW", name: "韓国ウォン")
        let trip = Trip(
            name: "韓国旅行",
            country: "韓国",
            currency: currency,
            exchangeRecords: [
                // 既存データ（従来方式）
                ExchangeRecord(
                    date: Date().addingTimeInterval(-172800), // 2日前
                    jpyAmount: 10000,
                    displayRate: 0.109,
                    foreignAmount: 91700
                ),
                // 新データ（両替所表示方式）
                ExchangeRecord(
                    date: Date().addingTimeInterval(-86400), // 1日前
                    jpyAmount: 5000,
                    foreignAmount: 45000,
                    rateInputType: .exchangeOffice,
                    inputValue1: 100,
                    inputValue2: 900
                ),
                // 新データ（1円あたり方式）
                ExchangeRecord(
                    date: Date(),
                    jpyAmount: 3000,
                    foreignAmount: 27000,
                    rateInputType: .perYen,
                    inputValue1: 9.0,
                    inputValue2: nil
                )
            ]
        )

        return NavigationView {
            ExchangeListView(trip: trip)
                .environmentObject(viewModel)
        }
    }
}
