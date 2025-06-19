//
//  ContentView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TravelCalculatorViewModel

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            TripListView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: {
                            viewModel.isSettingsViewPresented = true
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("設定")

                        Spacer()

                        Button(action: {
                            viewModel.showingAddTripSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("旅行を追加")
                    }
                }
        }
        .sheet(isPresented: $viewModel.isSettingsViewPresented) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("設定")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完了") {
                                viewModel.isSettingsViewPresented = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $viewModel.showingAddTripSheet) {
            NavigationStack {
                AddTripView()
                    .navigationTitle("旅行追加")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        // 旅行データがない場合は、ガイドを表示
        .overlay {
            if viewModel.trips.isEmpty {
                EmptyStateView(
                    icon: "airplane",
                    title: "旅行がありません",
                    description: "「追加」ボタンをタップして最初の旅行を記録しましょう",
                    actionTitle: "旅行を追加",
                    action: { viewModel.showingAddTripSheet = true }
                )
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: - Navigation Destination Handling

    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .tripDetail(let tripId):
            if let trip = viewModel.trips.first(where: { $0.id == tripId }) {
                TripDetailView(trip: trip)
            } else {
                tripNotFoundView
            }

        case .exchangeList(let tripId):
            if let trip = viewModel.trips.first(where: { $0.id == tripId }) {
                ExchangeListView(trip: trip)
            } else {
                tripNotFoundView
            }

        case .purchaseList(let tripId):
            if let trip = viewModel.trips.first(where: { $0.id == tripId }) {
                PurchaseListView(trip: trip)
            } else {
                tripNotFoundView
            }
        }
    }

    private var tripNotFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("旅行が見つかりません")
                .font(.headline)

            Text("旅行が削除されたか、データに問題がある可能性があります")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("旅行一覧に戻る") {
                viewModel.navigationPath = NavigationPath()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .navigationTitle("エラー")
    }
}

// MARK: - Navigation Destination Types

/// 統一されたナビゲーション先の定義
enum NavigationDestination: Hashable {
    case tripDetail(tripId: UUID)
    case exchangeList(tripId: UUID)
    case purchaseList(tripId: UUID)
}

// MARK: - TravelCalculatorViewModel Extension

extension TravelCalculatorViewModel {

    /// 旅行詳細画面へのナビゲーション
    func navigateToTripDetail(_ tripId: UUID) {
        navigationPath.append(NavigationDestination.tripDetail(tripId: tripId))
    }

    /// 両替履歴画面へのナビゲーション
    func navigateToExchangeList(_ tripId: UUID) {
        navigationPath.append(NavigationDestination.exchangeList(tripId: tripId))
    }

    /// 買い物履歴画面へのナビゲーション
    func navigateToPurchaseList(_ tripId: UUID) {
        navigationPath.append(NavigationDestination.purchaseList(tripId: tripId))
    }

    /// ナビゲーションをクリア
    func clearNavigation() {
        navigationPath = NavigationPath()
    }

    /// 一つ前の画面に戻る
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}

#Preview{
    ContentView()
        .environmentObject(TravelCalculatorViewModel())
}
