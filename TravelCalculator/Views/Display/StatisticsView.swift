//
//  StatisticsView.swift
//  TravelCalculator
//
//  Created by AI Assistant on 2025/06/23.
//

import SwiftUI

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel
    @State private var showResetConfirmation = false

    // 統計データの計算
    private var statisticsData: TripStatistics {
        let trips = viewModel.trips
        let currentDate = Date()

        let completedTrips = trips.filter { $0.endDate < currentDate }
        let activeTrips = trips.filter { currentDate >= $0.startDate && currentDate <= $0.endDate }
        let upcomingTrips = trips.filter { $0.startDate > currentDate }

        return TripStatistics(
            completed: completedTrips.count,
            active: activeTrips.count,
            upcoming: upcomingTrips.count,
            total: trips.count
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 統計カード
                    statisticsCardsSection

                    // データ管理セクション
                    dataManagementSection
                }
                .padding()
            }
            .navigationTitle("統計情報")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("すべてのデータをリセット", isPresented: $showResetConfirmation) {
                resetConfirmationButtons
            } message: {
                Text("すべての旅行データが削除されます。この操作は元に戻せません。")
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    // 削除：ヘッダーセクション

    // MARK: - 統計カードセクション

    private var statisticsCardsSection: some View {
        VStack(spacing: 16) {
            // 合計旅行数（大きく表示）
            totalTripsCard

            // 状態別統計（3つのカード）
            HStack(spacing: 12) {
                StatisticCard(
                    title: "終了",
                    value: "\(statisticsData.completed)",
                    subtitle: "回",
                    icon: "checkmark.circle.fill",
                    color: .gray,
                    isLarge: false
                )

                StatisticCard(
                    title: "進行中",
                    value: "\(statisticsData.active)",
                    subtitle: "回",
                    icon: "location.fill",
                    color: .green,
                    isLarge: false
                )

                StatisticCard(
                    title: "予定",
                    value: "\(statisticsData.upcoming)",
                    subtitle: "回",
                    icon: "calendar",
                    color: .orange,
                    isLarge: false
                )
            }
        }
    }

    private var totalTripsCard: some View {
        StatisticCard(
            title: "総旅行数",
            value: "\(statisticsData.total)",
            subtitle: "回の旅行",
            icon: "suitcase.fill",
            color: .blue,
            isLarge: true
        )
    }

    // MARK: - データ管理セクション

    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            // セクションタイトル
            HStack {
                Text("データ管理")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)

            // 削除ボタン
            Button(action: {
                showResetConfirmation = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)

                    Text("すべてのデータを削除")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                        .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .padding(.horizontal)

            // 注意文
            Text("この操作により、すべての旅行記録、両替記録、買い物記録が完全に削除されます。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - アラート確認ボタン

    private var resetConfirmationButtons: some View {
        Group {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                viewModel.resetAllData()
                dismiss() // データ削除後に画面を閉じる
            }
        }
    }
}

// MARK: - 統計データ構造

struct TripStatistics {
    let completed: Int
    let active: Int
    let upcoming: Int
    let total: Int
}

// MARK: - 統計カードコンポーネント

struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isLarge: Bool

    var body: some View {
        VStack(spacing: isLarge ? 16 : 12) {
            // アイコン
            Image(systemName: icon)
                .font(.system(size: isLarge ? 32 : 24))
                .foregroundColor(color)

            // 値
            Text(value)
                .font(isLarge ? .largeTitle : .title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // タイトルとサブタイトル
            VStack(spacing: 4) {
                Text(title)
                    .font(isLarge ? .headline : .subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(isLarge ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview("統計情報 - データあり") {
    let viewModel = TravelCalculatorViewModel()
    // テストデータを追加
    viewModel.trips = [
        Trip(
            name: "タイ旅行",
            country: "タイ",
            currency: Currency(code: "THB", name: "タイバーツ"),
            startDate: Date().addingTimeInterval(-60*60*24*10), // 10日前開始
            endDate: Date().addingTimeInterval(-60*60*24*3)     // 3日前終了（完了）
        ),
        Trip(
            name: "アメリカ旅行",
            country: "アメリカ",
            currency: Currency(code: "USD", name: "米ドル"),
            startDate: Date().addingTimeInterval(-60*60*24*2),  // 2日前開始
            endDate: Date().addingTimeInterval(60*60*24*3)      // 3日後終了（進行中）
        ),
        Trip(
            name: "ヨーロッパ旅行",
            country: "フランス",
            currency: Currency(code: "EUR", name: "ユーロ"),
            startDate: Date().addingTimeInterval(60*60*24*10),  // 10日後開始（予定）
            endDate: Date().addingTimeInterval(60*60*24*17)     // 17日後終了
        )
    ]

    return StatisticsView()
        .environmentObject(viewModel)
}

#Preview("統計情報 - データなし") {
    let viewModel = TravelCalculatorViewModel()
    // 空のデータ

    return StatisticsView()
        .environmentObject(viewModel)
}
