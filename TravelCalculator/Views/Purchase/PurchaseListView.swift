//
//  PurchaseListView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//


import SwiftUI

struct PurchaseListView: View {
    @EnvironmentObject var viewModel: TravelCalculatorViewModel
    var trip: Trip

    @State private var showingAddPurchaseSheet = false
    @State private var selectedPurchase: PurchaseRecord? = nil

    var sortedPurchaseRecords: [PurchaseRecord] {
        return trip.purchaseRecords.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        VStack {
            if trip.purchaseRecords.isEmpty {
                // 買い物履歴がない場合の表示
                VStack(spacing: 20) {
                    Image(systemName: "cart.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .opacity(trip.weightedAverageRate > 0 ? 1.0 : 0.5)

                    Text("買い物履歴がありません")
                        .font(.headline)
                        .opacity(trip.weightedAverageRate > 0 ? 1.0 : 0.5)

                    Text("「追加」ボタンをタップして最初の買い物を記録しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(trip.weightedAverageRate > 0 ? 1.0 : 0.5)

                    if trip.weightedAverageRate <= 0 {
                        Text("買い物を記録するには、先に両替を記録してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    Button(action: {
                        showingAddPurchaseSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("買い物を追加")
                        }
                        .padding()
                        .background(trip.weightedAverageRate > 0 ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top)
                    .disabled(trip.weightedAverageRate <= 0)
                }
                .padding()
            } else {
                List {
                    ForEach(sortedPurchaseRecords) { purchase in
                        PurchaseRow(
                            purchase: purchase,
                            currency: trip.currency,
                            weightedAverageRate: trip.weightedAverageRate
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPurchase = purchase
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deletePurchaseRecord(at: indexSet, from: sortedPurchaseRecords, inTripWithId: trip.id)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("買い物履歴")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingAddPurchaseSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .disabled(trip.weightedAverageRate <= 0)
            }
        }
        .sheet(isPresented: $showingAddPurchaseSheet) {
            AddPurchaseView(trip: trip)
        }
        .sheet(item: $selectedPurchase) { purchase in
            EditPurchaseView(trip: trip, purchase: purchase)
        }
    }
}


struct PurchaseRow: View {
    var purchase: PurchaseRecord
    var currency: Currency
    var weightedAverageRate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(CurrencyFormatter.formatDate(purchase.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if !purchase.description.isEmpty {
                Text(purchase.description)
                    .font(.headline)
            }
            
            HStack {
                HStack {
                    Text(CurrencyFormatter.formatForeign(purchase.foreignAmount, currencyCode: currency.code))
                        .font(.headline)
                        .frame(minWidth: 100, alignment: .trailing)
                    
                    Image(systemName: "equal")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(CurrencyFormatter.formatJPY(purchase.jpyAmount(using: weightedAverageRate)))
                        .font(.headline)
                        .frame(minWidth: 100, alignment: .leading)
                }
                
                Spacer()
            }
            
            // 適用レート情報
            HStack {
                Text("レート: 1\(currency.code) = ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(CurrencyFormatter.formatRate(weightedAverageRate))円")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}


struct PurchaseListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TravelCalculatorViewModel()
        let trip = Trip(
            name: "タイ旅行",
            currency: Currency(code: "THB", name: "タイバーツ"),
            exchangeRecords: [
                ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500)
            ],
            purchaseRecords: [
                PurchaseRecord(date: Date(), foreignAmount: 500, description: "お土産"),
                PurchaseRecord(date: Date().addingTimeInterval(-43200), foreignAmount: 200, description: "ランチ")
            ]
        )
        
        return NavigationView {
            PurchaseListView(trip: trip)
                .environmentObject(viewModel)
        }
    }
}
