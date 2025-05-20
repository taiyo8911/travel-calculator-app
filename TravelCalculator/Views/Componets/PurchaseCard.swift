//
//  PurchaseCard.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//


import SwiftUI

struct PurchaseCard: View {
    var purchase: PurchaseRecord
    var currency: Currency
    var weightedAverageRate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("買い物")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(CurrencyFormatter.formatDate(purchase.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if !purchase.description.isEmpty {
                Text(purchase.description)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            
            HStack {
                Text("\(CurrencyFormatter.formatForeign(purchase.foreignAmount, currencyCode: currency.code))")
                    .font(.headline)
                
                Spacer()
                
                Text("\(CurrencyFormatter.formatJPY(purchase.jpyAmount(using: weightedAverageRate)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
    PurchaseCard(
        purchase: PurchaseRecord(
            id: UUID(),
            date: Date(),
            foreignAmount: 6,
            description: "コーヒー"
        ),
        currency: Currency(
            code: "USD",
            name: "$"
        ),
        weightedAverageRate: 150.0
    )
}
