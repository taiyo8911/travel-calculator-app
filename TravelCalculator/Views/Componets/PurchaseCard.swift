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

                if weightedAverageRate > 0 {
                    Text("\(CurrencyFormatter.formatJPY(purchase.jpyAmount(using: weightedAverageRate)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("計算不可")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("両替記録なし")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            // 警告表示（両替記録がない場合）
            if weightedAverageRate <= 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("両替記録が無いため日本円換算できません")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
                .padding(.top, 2)
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
