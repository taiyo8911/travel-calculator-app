//
//  TripDetailView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct TripDetailView: View {
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel
    private let trip: Trip

    // シート表示状態
    @State private var showingAddExchangeSheet = false
    @State private var showingAddPurchaseSheet = false
    @State private var refreshID = UUID() // ビューの更新を強制するための変数
    @State private var selectedTab = 0 // TabView用のセレクション状態

    // 最新のTrip情報を取得
    private var currentTrip: Trip {
        viewModel.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    init(trip: Trip) {
        self.trip = trip
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label("概要", systemImage: "house") }
                .tag(0)

            ExchangeListView(trip: currentTrip)
                .tabItem { Label("両替履歴", systemImage: "arrow.left.arrow.right") }
                .tag(1)

            PurchaseListView(trip: currentTrip)
                .tabItem { Label("買い物履歴", systemImage: "cart") }
                .tag(2)
        }
        .id(refreshID) // このIDが変わるとビュー全体が再構築される
        .navigationTitle(currentTrip.name)
        .toolbar {
            // 現在選択されているタブに応じてボタンを切り替え
            ToolbarItem(placement: .navigationBarTrailing) {
                switch selectedTab {
                case 0: // 概要タブ
                    Button(action: { sharePDF() }) {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("PDF出力")
                    }
                case 1: // 両替履歴タブ
                    Button(action: { showingAddExchangeSheet = true }) {
                        Image(systemName: "plus")
                            .accessibilityLabel("両替を追加")
                    }
                case 2: // 買い物履歴タブ
                    Button(action: { showingAddPurchaseSheet = true }) {
                        Image(systemName: "plus")
                            .accessibilityLabel("買い物を追加")
                    }
                default:
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showingAddExchangeSheet) {
            refreshID = UUID()
        } content: {
            AddExchangeView(trip: currentTrip)
        }
        .sheet(isPresented: $showingAddPurchaseSheet) {
            refreshID = UUID()
        } content: {
            AddPurchaseView(trip: currentTrip)
        }
    }

    // ホームタブのコンテンツ
    private var homeTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                tripPeriodSection
                currencyHeader
                summarySection
                Spacer()
                actionButtons
            }
            .padding(.vertical)
        }
    }

    // 旅行期間セクション
    private var tripPeriodSection: some View {
        VStack(spacing: 10) {
            tripStatusBadge

            HStack {
                VStack(alignment: .leading) {
                    Text("開始日")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formattedDate(currentTrip.startDate))
                        .font(.headline)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("終了日")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formattedDate(currentTrip.endDate))
                        .font(.headline)
                }
            }

            Text("旅行期間: \(currentTrip.tripDuration)日間")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // 旅行状態バッジ
    private var tripStatusBadge: some View {
        let isActive = isTripActive(currentTrip)
        let isUpcoming = isTripUpcoming(currentTrip)
        let isPast = isTripPast(currentTrip)

        return HStack {
            if isActive {
                statusBadge(text: "現在旅行中", color: .green)
            } else if isUpcoming {
                statusBadge(text: "予定", color: .blue)
            } else if isPast {
                statusBadge(text: "終了", color: .gray)
            }

            Spacer()
        }
    }

    // ステータスバッジヘルパー
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

    // 通貨情報ヘッダー
    private var currencyHeader: some View {
        HStack(spacing: 8) {
            Text(flagEmoji(for: "JP"))
                .font(.title2)

            Text("日本円 (JPY)")
                .font(.headline)

            Image(systemName: "arrow.right.arrow.left")
                .foregroundColor(.blue)
                .padding(.horizontal, 4)

            Text(flagEmoji(for: currentTrip.currency.code))
                .font(.title2)

            Text("\(currentTrip.currency.name) (\(currentTrip.currency.code))")
                .font(.headline)
        }
        .padding(.horizontal)
    }

    // サマリーカード
    private var summarySection: some View {
        VStack(spacing: 16) {
            SummaryCard(
                title: "平均レート",
                value: currentTrip.weightedAverageRate > 0 ?
                    "1\(currentTrip.currency.code) = \(CurrencyFormatter.formatRate(currentTrip.weightedAverageRate))円" : "両替データがありません",
                icon: "arrow.left.arrow.right.circle.fill",
                color: .blue
            )

            SummaryCard(
                title: "合計支出額（円）",
                value: CurrencyFormatter.formatJPY(currentTrip.totalExpenseInJPY),
                icon: "yensign.circle.fill",
                color: .green
            )
        }
    }

    // アクションボタン
    private var actionButtons: some View {
        HStack(spacing: 12) {
            actionButton(
                title: "両替を追加",
                icon: "plus.circle",
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
        .padding(.horizontal)
    }

    // アクションボタンの共通部分
    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(10)
        }
    }

    // 日付をフォーマットするヘルパーメソッド
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // 旅行の状態を判定するヘルパーメソッド
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

    // PDF共有メソッド
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
                    ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500)
                ],
                purchaseRecords: [
                    PurchaseRecord(date: Date(), foreignAmount: 500, description: "お土産")
                ]
            )
        )
        .environmentObject(TravelCalculatorViewModel())
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
