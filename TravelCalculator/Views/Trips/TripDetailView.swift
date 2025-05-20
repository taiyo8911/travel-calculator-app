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
                currencyHeader
                summarySection
                Spacer()
                actionButtons
            }
            .padding(.vertical)
        }
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
}


#Preview {
    NavigationView {
        TripDetailView(
            trip: Trip(
                name: "タイ旅行",
                currency: Currency(code: "THB", name: "タイバーツ"),
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
