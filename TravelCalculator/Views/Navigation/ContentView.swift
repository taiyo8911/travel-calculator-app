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
        NavigationStack(path: Binding(
            get: { viewModel.navigationPath },
            set: { viewModel.navigationPath = $0 }
        )) {
            TripListView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        // 旅行追加ボタン
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
        .sheet(isPresented: $viewModel.showingAddTripSheet) {
            NavigationStack {
                AddTripView()
                    .navigationTitle("旅行追加")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
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
                viewModel.clearNavigation()
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

enum NavigationDestination: Hashable {
    case tripDetail(tripId: UUID)
    case exchangeList(tripId: UUID)
    case purchaseList(tripId: UUID)
}

#Preview{
    ContentView()
        .environmentObject(TravelCalculatorViewModel())
}

// git test
