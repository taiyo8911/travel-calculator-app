//
//  PurchaseCard.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/06/20.
//

import SwiftUI

/// レスポンシブな買い物カード（統一サイズ版）
struct ResponsivePurchaseCard: View {
    var purchase: PurchaseRecord
    var currency: Currency
    var weightedAverageRate: Double

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // 統一されたカードサイズ
    private var cardWidth: CGFloat? {
        switch horizontalSizeClass {
        case .compact:
            return 280 // iPhone Portrait（統一）
        case .regular:
            return 320 // iPad or iPhone Landscape（統一）
        default:
            return 280 // Default（統一）
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            cardHeader

            UnifiedDivider()

            // 説明
            if !purchase.description.isEmpty {
                Text(purchase.description)
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            // 金額表示
            amountSection

            // 警告表示（両替記録がない場合）
            if weightedAverageRate <= 0 {
                noExchangeWarning
            }
        }
        .padding()
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Sections

    private var cardHeader: some View {
        HStack {
            UnifiedTag(text: "買い物", color: .green)

            Spacer()

            Text(CurrencyFormatter.formatDate(purchase.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 外貨金額
            HStack {
                Text("支払額:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyFormatter.formatForeign(purchase.foreignAmount, currencyCode: currency.code))
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // 日本円換算
            if weightedAverageRate > 0 {
                HStack {
                    Text("円換算:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.formatJPY(purchase.jpyAmount(using: weightedAverageRate)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                // 適用レート
                HStack {
                    Text("レート:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1\(currency.code) = \(CurrencyFormatter.formatRate(weightedAverageRate))円")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Text("円換算:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("計算不可")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var noExchangeWarning: some View {
        UnifiedWarningView(
            message: "両替記録が無いため日本円換算できません",
            icon: "exclamationmark.triangle.fill",
            color: .orange
        )
    }
}

#Preview("Purchase Card") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ResponsivePurchaseCard(
                purchase: PurchaseRecord(
                    date: Date(),
                    foreignAmount: 500,
                    description: "お土産・ショッピング"
                ),
                currency: Currency(code: "USD", name: "米ドル"),
                weightedAverageRate: 150.0
            )

            ResponsivePurchaseCard(
                purchase: PurchaseRecord(
                    date: Date(),
                    foreignAmount: 25,
                    description: "ランチ"
                ),
                currency: Currency(code: "USD", name: "米ドル"),
                weightedAverageRate: 0  // 両替記録なしの場合
            )
        }
        .padding()
    }
}
