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

    // 旅行のリストをIDでソート
    private var sortedTrips: [Trip] {
        viewModel.trips.sorted(by: { $0.id.uuidString > $1.id.uuidString })
    }

    var body: some View {
        List {
            ForEach(sortedTrips) { trip in
                NavigationLink(value: trip) {
                    TripRow(trip: trip)
                }
            }
            .onDelete { indexSet in
                deleteTripAt(indexSet)
            }
        }
        .id(UUID()) // 強制的にビューをリフレッシュする
        .navigationDestination(for: Trip.self) { trip in
            TripDetailView(trip: trip)
        }
        .listStyle(InsetGroupedListStyle())
    }

    private func deleteTripAt(_ indexSet: IndexSet) {
        for index in indexSet {
            viewModel.deleteTrip(withId: sortedTrips[index].id)
        }
    }
}

// それぞれの行を表示するビュー
struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 行の上部 - 旅行名と状態
            HStack {
                HStack {
                    Text(flagEmoji(for: trip.currency.code))
                        .font(.title2)

                    Text(trip.name)
                        .font(.headline)
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

            // 通貨レートと支出額
            HStack {
                // 1通貨あたりのレートを表示
                Text("1 \(trip.currency.code) = \(CurrencyFormatter.formatJPY(trip.weightedAverageRate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("合計支出額: \(CurrencyFormatter.formatJPY(trip.totalExpenseInJPY))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            currency: Currency(code: "EUR", name: "ユーロ"),
            startDate: Date().addingTimeInterval(-60*60*24*10), // 10日前
            endDate: Date().addingTimeInterval(-60*60*24*3), // 3日前
            exchangeRecords: [],
            purchaseRecords: []
        )
    ]
    return TripListView()
        .environmentObject(viewModel)
}
