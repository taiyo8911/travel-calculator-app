//
//  TripListView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

// 旅行リスト全体のビュー
struct TripListView: View {
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel

    // 編集シート表示用ステート
    @State private var editingTrip: Trip? = nil
    // リフレッシュキー（編集後に強制更新するため）
    @State private var refreshKey = UUID()

    // 旅行のリストをIDでソート
    private var sortedTrips: [Trip] {
        viewModel.trips.sorted(by: { $0.id.uuidString > $1.id.uuidString })
    }

    var body: some View {
        VStack(spacing: 0) {
            // カスタムヘッダー
            customHeader

            // 旅行リスト
            List {
                ForEach(sortedTrips) { trip in
                    // 常に最新のtrip情報を取得
                    let currentTrip = viewModel.trips.first(where: { $0.id == trip.id }) ?? trip

                    NavigationLink(value: NavigationDestination.tripDetail(tripId: currentTrip.id)) {
                        TripRow(trip: currentTrip)
                    }
                    .contextMenu {
                        Button(action: {
                            editingTrip = currentTrip
                        }) {
                            Label("編集", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            viewModel.deleteTrip(withId: trip.id)
                        }) {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteTripAt(indexSet)
                }
            }
            .id(refreshKey) // refreshKeyを使ってリストを強制更新
            .listStyle(InsetGroupedListStyle())
        }
        .navigationBarHidden(true) // デフォルトのナビゲーションバーを非表示
        .sheet(item: $editingTrip) { trip in
            EditTripView(trip: trip)
                .onDisappear {
                    // 編集画面が閉じられた時にリフレッシュキーを更新
                    refreshKey = UUID()
                }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // カスタムヘッダー
    private var customHeader: some View {
        VStack(spacing: 16) {
            // セーフエリア対応
            Color.clear
                .frame(height: 0)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: SafeAreaPreferenceKey.self,
                            value: geometry.safeAreaInsets.top
                        )
                    }
                )

            // ロゴとアプリ名
            HStack(spacing: 12) {
                // アイコン - 飛行機と地球を組み合わせ
                // 飛行機
                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: 4, y: -2)

                // アプリ名
                Text("トラベルマネージャー")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal)

            // 旅行統計情報
            statisticsView

            // 区切り線
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .background(
            // ヘッダー背景のグラデーション
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // 統計情報ビュー
    private var statisticsView: some View {
        HStack(spacing: 20) {
            // 総旅行数
            StatisticItem(
                icon: "suitcase.fill",
                value: "\(sortedTrips.count)",
                label: "旅行",
                color: .blue
            )

            // 進行中の旅行
            StatisticItem(
                icon: "location.fill",
                value: "\(activeTripsCount)",
                label: "進行中",
                color: .green
            )

            // 予定の旅行
            StatisticItem(
                icon: "calendar",
                value: "\(upcomingTripsCount)",
                label: "予定",
                color: .orange
            )
        }
        .padding(.horizontal)
    }

    // 計算プロパティ
    private var activeTripsCount: Int {
        sortedTrips.filter { isTripActive($0) }.count
    }

    private var upcomingTripsCount: Int {
        sortedTrips.filter { isTripUpcoming($0) }.count
    }

    private func deleteTripAt(_ indexSet: IndexSet) {
        for index in indexSet {
            viewModel.deleteTrip(withId: sortedTrips[index].id)
        }
    }

    // ヘルパーメソッド
    private func isTripActive(_ trip: Trip) -> Bool {
        let currentDate = Date()
        return currentDate >= trip.startDate && currentDate <= trip.endDate
    }

    private func isTripUpcoming(_ trip: Trip) -> Bool {
        return Date() < trip.startDate
    }
}

// 統計アイテムコンポーネント
struct StatisticItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// SafeAreaの取得用
struct SafeAreaPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// それぞれの行を表示するビュー（国名表示機能を追加）
struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 行の上部 - 旅行名、国名と状態
            HStack {
                HStack(spacing: 8) {
                    Text(flagEmoji(for: trip.currency.code))
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.name)
                            .font(.headline)

                        Text(trip.country)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 旅行の状態バッジ
                tripStatusBadge
            }

            // 旅行期間
            HStack {
                Text(formattedDate(trip.startDate))
                    .font(.subheadline)

                Text("〜")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formattedDate(trip.endDate))
                    .font(.subheadline)

            }
        }
        .padding(.vertical, 6)
    }

    // 旅行状態バッジ
    private var tripStatusBadge: some View {
        Group {
            if isTripActive(trip) {
                statusBadge(text: "現在旅行中", color: .green)
            } else if isTripUpcoming(trip) {
                statusBadge(text: "予定", color: .blue)
            } else if isTripPast(trip) {
                statusBadge(text: "終了", color: .gray)
            }
        }
    }

    // ステータスバッジヘルパー
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    // 日付をフォーマットするヘルパーメソッド
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
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
}

#Preview {
    let viewModel = TravelCalculatorViewModel()
    // テストデータ
    viewModel.trips = [
        Trip(
            name: "タイ旅行",
            country: "タイ",
            currency: Currency(code: "THB", name: "タイバーツ"),
            startDate: Date(),
            endDate: Date().addingTimeInterval(60*60*24*5),
            exchangeRecords: [
                ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500)
            ],
            purchaseRecords: [
                PurchaseRecord(date: Date(), foreignAmount: 500, description: "お土産")
            ]
        ),
        Trip(
            name: "アメリカ旅行",
            country: "アメリカ",
            currency: Currency(code: "USD", name: "アメリカドル"),
            startDate: Date().addingTimeInterval(60*60*24*30), // 30日後
            endDate: Date().addingTimeInterval(60*60*24*40), // 40日後
            exchangeRecords: [
                ExchangeRecord(date: Date(), jpyAmount: 20000, displayRate: 110.0, foreignAmount: 181.82)
            ],
            purchaseRecords: [
                PurchaseRecord(date: Date(), foreignAmount: 100, description: "お土産")
            ]
        ),
        Trip(
            name: "ヨーロッパ旅行",
            country: "フランス",
            currency: Currency(code: "EUR", name: "ユーロ"),
            startDate: Date().addingTimeInterval(-60*60*24*10), // 10日前
            endDate: Date().addingTimeInterval(-60*60*24*3), // 3日前
            exchangeRecords: [],
            purchaseRecords: []
        )
    ]
    return NavigationView {
        TripListView()
            .environmentObject(viewModel)
    }
}
