//
//  EditTripView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/05/24.
//

import SwiftUI
import Foundation

struct EditTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel
    
    var trip: Trip
    
    // 編集可能な項目のステート
    @State private var tripName: String
    @State private var country: String
    @State private var startDate: Date
    @State private var endDate: Date
    
    // フォームバリデーション
    private var isFormValid: Bool {
        return !tripName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // イニシャライザで初期値を設定
    init(trip: Trip) {
        self.trip = trip
        _tripName = State(initialValue: trip.name)
        _country = State(initialValue: trip.country)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 旅行名入力セクション
                Section(header: Text("旅行名")) {
                    TextField("旅行名を入力", text: $tripName)
                        .font(.headline)
                }
                
                // 国名入力セクション
                Section(header: Text("国名")) {
                    TextField("国名を入力", text: $country)
                        .font(.headline)
                }
                
                // 旅行期間セクション
                Section(header: Text("旅行期間")) {
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                    
                    // 旅行日数を表示
                    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0 + 1
                    Text("旅行日数: \(days)日")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 通貨情報（表示のみ）
                Section(header: Text("通貨")) {
                    HStack(spacing: 8) {
                        Text(flagEmoji(for: trip.currency.code))
                            .font(.title2)
                        
                        Text(trip.currency.name)
                            .fontWeight(.medium)
                        
                        Text("(\(trip.currency.code))")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    Text("通貨は変更できません")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 既存データの情報表示
                if !trip.exchangeRecords.isEmpty || !trip.purchaseRecords.isEmpty {
                    Section(header: Text("関連データ")) {
                        if !trip.exchangeRecords.isEmpty {
                            HStack {
                                Text("両替記録")
                                Spacer()
                                Text("\(trip.exchangeRecords.count)件")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !trip.purchaseRecords.isEmpty {
                            HStack {
                                Text("買い物記録")
                                Spacer()
                                Text("\(trip.purchaseRecords.count)件")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("期間を変更しても既存の記録は保持されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("旅行を編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    updateTrip()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    // 旅行情報を更新するメソッド
    private func updateTrip() {
        guard isFormValid else { return }
        
        var updatedTrip = trip
        updatedTrip.name = tripName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTrip.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTrip.startDate = startDate
        updatedTrip.endDate = endDate
        
        viewModel.updateTrip(updatedTrip)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    let trip = Trip(
        name: "タイ旅行",
        country: "タイ",
        currency: Currency(code: "THB", name: "タイバーツ"),
        startDate: Date(),
        endDate: Date().addingTimeInterval(60*60*24*7),
        exchangeRecords: [
            ExchangeRecord(date: Date(), jpyAmount: 10000, displayRate: 3.8, foreignAmount: 2500)
        ],
        purchaseRecords: [
            PurchaseRecord(date: Date(), foreignAmount: 500, description: "お土産")
        ]
    )
    
    EditTripView(trip: trip)
        .environmentObject(TravelCalculatorViewModel())
}
