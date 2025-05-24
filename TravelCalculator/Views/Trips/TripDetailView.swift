//
//  TripDetailView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI
import Combine

struct TripDetailView: View {
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel
    private let trip: Trip

    // シート表示状態
    @State private var showingAddExchangeSheet = false
    @State private var showingAddPurchaseSheet = false

    // 最新のTrip情報を取得
    private var currentTrip: Trip {
        viewModel.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    // データ更新検知用
    private var dataKey: String {
        "\(currentTrip.exchangeRecords.count)-\(currentTrip.purchaseRecords.count)-\(currentTrip.weightedAverageRate)"
    }

    init(trip: Trip) {
        self.trip = trip
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                tripHeaderSection
                summaryCardsSection
                recentExchangesSection
                recentPurchasesSection
                actionButtonsSection
            }
            .padding(.vertical)
        }
        .id(dataKey) // データの変更を検知してビューを更新
        .navigationTitle(currentTrip.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { sharePDF() }) {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityLabel("PDF出力")
                }
            }
        }
        .sheet(isPresented: $showingAddExchangeSheet) {
            AddExchangeView(trip: currentTrip)
        }
        .sheet(isPresented: $showingAddPurchaseSheet) {
            AddPurchaseView(trip: currentTrip)
        }
        .onReceive(viewModel.$trips) { _ in
            // ViewModelのtripsが更新されたときに強制的にビューを更新
        }
    }

    // MARK: - 旅行ヘッダーセクション
    private var tripHeaderSection: some View {
        VStack(spacing: 12) {
            // 期間と状態
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("旅行期間")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Text(formattedDate(currentTrip.startDate))
                            .font(.headline)

                        Text("〜")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(formattedDate(currentTrip.endDate))
                            .font(.headline)
                    }

                    Text("\(currentTrip.tripDuration)日間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                tripStatusBadge
            }
            .padding(.horizontal)

            // 通貨情報
            HStack(spacing: 8) {
                Text(flagEmoji(for: "JP"))
                    .font(.title2)

                Text("JPY")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                    .padding(.horizontal, 4)

                Text(flagEmoji(for: currentTrip.currency.code))
                    .font(.title2)

                Text(currentTrip.currency.code)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("(\(currentTrip.currency.name))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - サマリーカードセクション
    private var summaryCardsSection: some View {
        VStack(spacing: 16) {
            // 平均レートカード
            SummaryCard(
                title: "平均レート",
                value: currentTrip.weightedAverageRate > 0 ?
                "1\(currentTrip.currency.code) = \(CurrencyFormatter.formatRate(currentTrip.weightedAverageRate))円" : "両替記録がありません",
                icon: "arrow.left.arrow.right.circle.fill",
                color: currentTrip.weightedAverageRate > 0 ? .blue : .orange
            )

            // 合計両替額カード
            SummaryCard(
                title: "合計両替額",
                value: CurrencyFormatter.formatJPY(totalExchangeAmount),
                icon: "yensign.circle.fill",
                color: .orange
            )

            // 合計支出額カード
            SummaryCard(
                title: "合計支出額",
                value: currentTrip.weightedAverageRate > 0 ?
                CurrencyFormatter.formatJPY(currentTrip.totalExpenseInJPY) : "計算不可",
                icon: "cart.circle.fill",
                color: currentTrip.weightedAverageRate > 0 ? .green : .orange
            )

            // 残り外貨カード
            SummaryCard(
                title: "残り外貨",
                value: remainingForeignText,
                icon: "dollarsign.circle.fill",
                color: .purple
            )
        }
    }

    // MARK: - 最近の両替セクション
    private var recentExchangesSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.blue)

                    Text("最近の両替")
                        .font(.headline)

                    if !currentTrip.exchangeRecords.isEmpty {
                        Text("(\(currentTrip.exchangeRecords.count)件)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !currentTrip.exchangeRecords.isEmpty {
                    NavigationLink(destination: ExchangeListView(trip: currentTrip)) {
                        HStack(spacing: 4) {
                            Text("すべて見る")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if currentTrip.exchangeRecords.isEmpty {
                emptyStateView(
                    icon: "arrow.left.arrow.right.circle",
                    title: "両替記録がありません",
                    description: "最初の両替を記録しましょう"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentTrip.recentExchangeRecords) { exchange in
                            ExchangeCard(exchange: exchange, currency: currentTrip.currency)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - 最近の買い物セクション
    private var recentPurchasesSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cart")
                        .foregroundColor(.green)

                    Text("最近の買い物")
                        .font(.headline)

                    if !currentTrip.purchaseRecords.isEmpty {
                        Text("(\(currentTrip.purchaseRecords.count)件)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !currentTrip.purchaseRecords.isEmpty {
                    NavigationLink(destination: PurchaseListView(trip: currentTrip)) {
                        HStack(spacing: 4) {
                            Text("すべて見る")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if currentTrip.purchaseRecords.isEmpty {
                emptyStateView(
                    icon: "cart.circle",
                    title: "買い物記録がありません",
                    description: "最初の買い物を記録しましょう"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentTrip.recentPurchaseRecords) { purchase in
                            PurchaseCard(
                                purchase: purchase,
                                currency: currentTrip.currency,
                                weightedAverageRate: currentTrip.weightedAverageRate
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - アクションボタンセクション
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                actionButton(
                    title: "両替を追加",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: { showingAddExchangeSheet = true }
                )

                actionButton(
                    title: "買い物を追加",
                    icon: "cart.badge.plus",
                    color: .green,
                    action: { showingAddPurchaseSheet = true }
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - ヘルパービュー

    // 旅行状態バッジ
    private var tripStatusBadge: some View {
        let isActive = isTripActive(currentTrip)
        let isUpcoming = isTripUpcoming(currentTrip)
        let isPast = isTripPast(currentTrip)

        return Group {
            if isActive {
                statusBadge(text: "現在旅行中", color: .green)
            } else if isUpcoming {
                statusBadge(text: "予定", color: .blue)
            } else if isPast {
                statusBadge(text: "終了", color: .gray)
            }
        }
    }

    // ステータスバッジ
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    // 空状態ビュー
    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // アクションボタン
    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(disabled ? Color.gray : color)
            .cornerRadius(12)
        }
        .disabled(disabled)
    }

    // MARK: - 計算プロパティ

    private var totalExchangeAmount: Double {
        currentTrip.exchangeRecords.reduce(0) { $0 + $1.jpyAmount }
    }

    private var totalForeignObtained: Double {
        currentTrip.exchangeRecords.reduce(0) { $0 + $1.foreignAmount }
    }

    private var totalForeignSpent: Double {
        currentTrip.purchaseRecords.reduce(0) { $0 + $1.foreignAmount }
    }

    private var remainingForeign: Double {
        totalForeignObtained - totalForeignSpent
    }

    private var remainingForeignText: String {
        if totalForeignObtained <= 0 {
            return "データなし"
        }
        return CurrencyFormatter.formatForeign(remainingForeign, currencyCode: currentTrip.currency.code)
    }

    // MARK: - ヘルパーメソッド

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func isTripActive(_ trip: Trip) -> Bool {
        let currentDate = Date()
        return currentDate >= trip.startDate && currentDate <= trip.endDate
    }

    private func isTripUpcoming(_ trip: Trip) -> Bool {
        return Date() < trip.startDate
    }

    private func isTripPast(_ trip: Trip) -> Bool {
        return Date() > trip.endDate
    }

    private func sharePDF() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        viewModel.sharePDF(for: currentTrip, from: rootVC)
    }
}

#Preview {
    NavigationView {
        TripDetailView(
            trip: Trip(
                name: "タイ旅行",
                currency: Currency(code: "THB", name: "タイバーツ"),
                startDate: Date(),
                endDate: Date().addingTimeInterval(60*60*24*5),
                exchangeRecords: [
                    ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500),
                    ExchangeRecord(date: Date().addingTimeInterval(-86400), jpyAmount: 5000, displayRate: 3.9, foreignAmount: 1200)
                ],
                purchaseRecords: [
                    PurchaseRecord(date: Date(), foreignAmount: 500, description: "お土産"),
                    PurchaseRecord(date: Date().addingTimeInterval(-43200), foreignAmount: 200, description: "ランチ")
                ]
            )
        )
        .environmentObject(TravelCalculatorViewModel())
    }
}
