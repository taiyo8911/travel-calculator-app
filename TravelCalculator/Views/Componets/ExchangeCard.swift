//
//  ExchangeCard.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//


import SwiftUI

struct ExchangeCard: View {
    var exchange: ExchangeRecord
    var currency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("両替")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(CurrencyFormatter.formatDate(exchange.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Text("\(CurrencyFormatter.formatJPY(exchange.jpyAmount))")
                .font(.headline)
            
            HStack {
                Text("\(CurrencyFormatter.formatForeign(exchange.foreignAmount, currencyCode: currency.code))")
                
                Spacer()
                
                Text(exchange.isHighFee ? "手数料: \(CurrencyFormatter.formatPercent(exchange.feePercentage))" : "")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 250)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    ExchangeCard(
        exchange: ExchangeRecord(
            date: Date(),
            jpyAmount: 10000,
            displayRate: 150.0,
            foreignAmount: 60
        ),
        currency: Currency(code: "USD", name: "US Dollar")
    )
}
