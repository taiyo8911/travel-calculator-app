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
                .navigationDestination(for: UUID.self) { tripId in
                    if let trip = viewModel.trips.first(where: { $0.id == tripId }) {
                        TripDetailView(trip: trip)
                    }
                }
                .navigationDestination(for: Trip.self) { trip in
                    TripDetailView(trip: trip)
                }
                // 両替履歴画面への遷移
                .navigationDestination(for: ExchangeListDestination.self) { destination in
                    ExchangeListView(trip: destination.trip)
                }
                // 買い物履歴画面への遷移
                .navigationDestination(for: PurchaseListDestination.self) { destination in
                    PurchaseListView(trip: destination.trip)
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
                VStack(spacing: 16) {
                    Image(systemName: "airplane")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("旅行がありません")
                        .font(.headline)

                    Text("「追加」ボタンをタップして最初の旅行を記録しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// ナビゲーション用の構造体
struct ExchangeListDestination: Hashable {
    let trip: Trip
}

struct PurchaseListDestination: Hashable {
    let trip: Trip
}

#Preview{
    ContentView()
        .environmentObject(TravelCalculatorViewModel())
}
