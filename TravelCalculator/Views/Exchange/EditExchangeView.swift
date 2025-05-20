//
//  EditExchangeView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/06.
//


import SwiftUI

struct EditExchangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: TravelCalculatorViewModel
    
    var trip: Trip
    var exchange: ExchangeRecord
    
    @State private var date: Date
    @State private var jpyAmount: String
    @State private var displayRate: String
    @State private var foreignAmount: String
    
    // フォームのバリデーション
    private var isFormValid: Bool {
        guard let jpyValue = Double(jpyAmount), jpyValue > 0,
              let rateValue = Double(displayRate), rateValue > 0,
              let foreignValue = Double(foreignAmount), foreignValue > 0 else {
            return false
        }
        return true
    }
    
    // イニシャライザ
    init(trip: Trip, exchange: ExchangeRecord) {
        self.trip = trip
        self.exchange = exchange
        
        // 初期値を設定
        _date = State(initialValue: exchange.date)
        _jpyAmount = State(initialValue: String(format: "%.0f", exchange.jpyAmount))
        _displayRate = State(initialValue: String(format: "%.2f", exchange.displayRate))
        _foreignAmount = State(initialValue: String(format: "%.2f", exchange.foreignAmount))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("両替情報")) {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("日本円")
                        Spacer()
                        TextField("日本円", text: $jpyAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("表示レート")
                        Spacer()
                        TextField("表示レート", text: $displayRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("\(trip.currency.code)金額")
                        Spacer()
                        TextField("外貨金額", text: $foreignAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // プレビューセクション
                if isFormValid, let jpyValue = Double(jpyAmount), let foreignValue = Double(foreignAmount) {
                    Section(header: Text("実質レート")) {
                        let actualRate = jpyValue / foreignValue
                        let feePercentage = ((actualRate / Double(displayRate)! - 1) * 100)
                        
                        HStack {
                            Text("実質レート:")
                            Spacer()
                            Text("1\(trip.currency.code) = \(CurrencyFormatter.formatRate(actualRate))円")
                        }
                        
                        HStack {
                            Text("手数料率:")
                            Spacer()
                            Text("\(CurrencyFormatter.formatPercent(feePercentage))")
                                .foregroundColor(feePercentage > 3.0 ? .red : .green)
                        }
                    }
                }
            }
            .navigationBarTitle("両替履歴を編集", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveExchangeRecord()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private func saveExchangeRecord() {
        guard let jpyValue = Double(jpyAmount),
              let rateValue = Double(displayRate),
              let foreignValue = Double(foreignAmount) else {
            return
        }
        
        // 更新された記録を作成
        let updatedRecord = ExchangeRecord(
            id: exchange.id,
            date: date,
            jpyAmount: jpyValue,
            displayRate: rateValue,
            foreignAmount: foreignValue
        )
        
        // ViewModelの更新メソッドを呼び出す
        viewModel.updateExchangeRecord(updatedRecord, inTripWithId: trip.id)
        
        // 画面を閉じる
        presentationMode.wrappedValue.dismiss()
    }
}


#Preview {
    let viewModel = TravelCalculatorViewModel()

    // サンプルのCurrency
    let currency = Currency(code: "USD", name: "US Dollar")

    // サンプルのTrip - currency引数を追加
    let trip = Trip(name: "アメリカ旅行", currency: currency)

    // サンプルの両替記録
    let exchange = ExchangeRecord(
        date: Date(),
        jpyAmount: 10000.0,
        displayRate: 150.0,
        foreignAmount: 65.0
    )

    EditExchangeView(trip: trip, exchange: exchange)
        .environmentObject(viewModel)
}
