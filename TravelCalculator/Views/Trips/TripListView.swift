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

    // 国コードから旗の絵文字を取得する関数
    private func flagEmoji(for countryCode: String) -> String {
        // 国コードをUnicode地域指標に変換
        let base: UInt32 = 127397 // Unicode地域指標のベースとなる値
        var flagString = ""

        // 2文字の国コード（例：US, JP, THB）から先頭2文字だけを使用
        let codeToUse = String(countryCode.prefix(2)).uppercased()

        for scalar in codeToUse.unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                flagString.append(Character(scalarValue))
            }
        }
        return flagString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flagEmoji(for: trip.currency.code))
                    .font(.title2)

                Text(trip.name)
                    .font(.headline)
            }

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
}



#Preview {
    let viewModel = TravelCalculatorViewModel()
    // テストデータ
    viewModel.trips = [
        Trip(
            name: "タイ旅行",
            currency: Currency(code: "THB", name: "タイバーツ"),
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
            exchangeRecords: [
                ExchangeRecord(date: Date(), jpyAmount: 20000, displayRate: 110.0, foreignAmount: 181.82)
            ],
            purchaseRecords: [
                PurchaseRecord(date: Date(), foreignAmount: 100, description: "お土産")
            ]
        )
    ]
    return TripListView()
        .environmentObject(viewModel)
}
