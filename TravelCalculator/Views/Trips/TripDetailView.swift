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
    private let tripId: UUID

    // シート表示状態
    @State private var showingAddExchangeSheet = false
    @State private var showingAddPurchaseSheet = false

    // 最新のTrip情報を取得（計算プロパティとして簡略化）
    private var currentTrip: Trip? {
        viewModel.trips.first(where: { $0.id == tripId })
    }

    init(trip: Trip) {
        self.tripId = trip.id
    }

    var body: some View {
        Group {
            if let trip = currentTrip {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        tripHeaderSection(trip: trip)
                        summaryCardsSection(trip: trip)
                        recentExchangesSection(trip: trip)
                        recentPurchasesSection(trip: trip)
                        actionButtonsSection(trip: trip)
                    }
                    .padding(.vertical)
                }
                .navigationTitle(trip.name)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { sharePDF(trip: trip) }) {
                            Image(systemName: "square.and.arrow.up")
                                .accessibilityLabel("PDF出力")
                        }
                    }
                }
                .sheet(isPresented: $showingAddExchangeSheet) {
                    AddExchangeView(trip: trip)
                }
                .sheet(isPresented: $showingAddPurchaseSheet) {
                    AddPurchaseView(trip: trip)
                }
            } else {
                // 旅行が見つからない場合のエラー表示
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("旅行データが見つかりません")
                        .font(.headline)

                    Text("旅行が削除されたか、データに問題がある可能性があります")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    // MARK: - 旅行ヘッダーセクション
    private func tripHeaderSection(trip: Trip) -> some View {
        ResponsiveCard {
            VStack(spacing: 12) {
                // 期間と状態
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("旅行期間")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Text(formattedDate(trip.startDate))
                                .font(.headline)

                            Text("〜")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(formattedDate(trip.endDate))
                                .font(.headline)
                        }

                        Text("\(trip.tripDuration)日間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    tripStatusBadge(trip: trip)
                }

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

                    Text(flagEmoji(for: trip.currency.code))
                        .font(.title2)

                    Text(trip.currency.code)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("(\(trip.currency.name))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - サマリーカードセクション
    private func summaryCardsSection(trip: Trip) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            // 平均レートカード
            SummaryCard(
                title: "平均レート",
                value: trip.weightedAverageRate > 0 ?
                "1\(trip.currency.code) = \(CurrencyFormatter.formatRate(trip.weightedAverageRate))円" : "両替記録がありません",
                icon: "arrow.left.arrow.right.circle.fill",
                color: trip.weightedAverageRate > 0 ? .blue : .orange
            )

            // 合計両替額カード
            SummaryCard(
                title: "合計両替額",
                value: CurrencyFormatter.formatJPY(trip.totalExchangeJPYAmount),
                icon: "yensign.circle.fill",
                color: .orange
            )

            // 合計支出額カード
            SummaryCard(
                title: "合計支出額",
                value: trip.weightedAverageRate > 0 ?
                CurrencyFormatter.formatJPY(trip.totalExpenseInJPY) : "計算不可",
                icon: "cart.circle.fill",
                color: trip.weightedAverageRate > 0 ? .green : .orange
            )

            // 残り外貨カード
            SummaryCard(
                title: "残り外貨",
                value: remainingForeignText(trip: trip),
                icon: "dollarsign.circle.fill",
                color: .purple
            )
        }
        .padding(.horizontal)
    }

    // MARK: - 最近の両替セクション
    private func recentExchangesSection(trip: Trip) -> some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.blue)

                    Text("最近の両替")
                        .font(.headline)

                    if !trip.exchangeRecords.isEmpty {
                        Text("(\(trip.exchangeRecords.count)件)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !trip.exchangeRecords.isEmpty {
                    NavigationLink(destination: ExchangeListView(trip: trip)) {
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

            if trip.exchangeRecords.isEmpty {
                EmptyStateView(
                    icon: "arrow.left.arrow.right.circle",
                    title: "両替記録がありません",
                    description: "最初の両替を記録しましょう",
                    actionTitle: "両替を追加",
                    action: { showingAddExchangeSheet = true }
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(trip.recentExchangeRecords) { exchange in
                            ResponsiveExchangeCard(exchange: exchange, currency: trip.currency)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - 最近の買い物セクション
    private func recentPurchasesSection(trip: Trip) -> some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cart")
                        .foregroundColor(.green)

                    Text("最近の買い物")
                        .font(.headline)

                    if !trip.purchaseRecords.isEmpty {
                        Text("(\(trip.purchaseRecords.count)件)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !trip.purchaseRecords.isEmpty {
                    NavigationLink(destination: PurchaseListView(trip: trip)) {
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

            if trip.purchaseRecords.isEmpty {
                EmptyStateView(
                    icon: "cart.circle",
                    title: "買い物記録がありません",
                    description: "最初の買い物を記録しましょう",
                    actionTitle: "買い物を追加",
                    action: { showingAddPurchaseSheet = true }
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(trip.recentPurchaseRecords) { purchase in
                            ResponsivePurchaseCard(
                                purchase: purchase,
                                currency: trip.currency,
                                weightedAverageRate: trip.weightedAverageRate
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - アクションボタンセクション
    private func actionButtonsSection(trip: Trip) -> some View {
        HStack(spacing: 12) {
            ResponsiveActionButton(
                title: "両替を追加",
                icon: "plus.circle.fill",
                color: .blue,
                action: { showingAddExchangeSheet = true }
            )

            ResponsiveActionButton(
                title: "買い物を追加",
                icon: "cart.badge.plus",
                color: .green,
                action: { showingAddPurchaseSheet = true }
            )
        }
        .padding(.horizontal)
    }

    // MARK: - ヘルパービュー

    // 旅行状態バッジ
    private func tripStatusBadge(trip: Trip) -> some View {
        let isActive = isTripActive(trip)
        let isUpcoming = isTripUpcoming(trip)
        let isPast = isTripPast(trip)

        return Group {
            if isActive {
                StatusBadge(text: "現在旅行中", color: .green)
            } else if isUpcoming {
                StatusBadge(text: "予定", color: .blue)
            } else if isPast {
                StatusBadge(text: "終了", color: .gray)
            }
        }
    }

    // MARK: - 計算プロパティ

    private func remainingForeignText(trip: Trip) -> String {
        if trip.totalForeignObtained <= 0 {
            return "データなし"
        }
        return CurrencyFormatter.formatForeign(trip.remainingForeign, currencyCode: trip.currency.code)
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

    private func sharePDF(trip: Trip) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        viewModel.sharePDF(for: trip, from: rootVC)
    }
}

// MARK: - 再利用可能なUI コンポーネント

/// レスポンシブなカードコンテナ
struct ResponsiveCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
    }
}

/// 統一されたステータスバッジ
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

/// 統一された空状態ビュー
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String, title: String, description: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
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
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(buttonColor(for: actionTitle))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    private func buttonColor(for actionTitle: String?) -> Color {
        guard let title = actionTitle else { return .blue }

        if title.contains("両替を追加") {
            return .blue
        } else if title.contains("買い物を追加") {
            return .green
        } else {
            return .blue // デフォルト
        }
    }
}

/// レスポンシブなアクションボタン
struct ResponsiveActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let disabled: Bool
    let action: () -> Void

    init(title: String, icon: String, color: Color, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
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
}

#Preview {
    NavigationView {
        TripDetailView(
            trip: Trip(
                name: "タイ旅行",
                country: "タイ",
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
