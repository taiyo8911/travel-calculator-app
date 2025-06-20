//
//  RecordCards.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/06/19.
//


import SwiftUI

/// レスポンシブな両替カード（画面サイズに適応）
struct ResponsiveExchangeCard: View {
    var exchange: ExchangeRecord
    var currency: Currency

    // デバイスサイズに基づく適応的な幅（統一版）
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

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

            // 入力レート表示
            inputRateSection

            // 両替詳細
            exchangeDetailsSection

            // レート情報
            rateInfoSection
        }
        .padding()
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Header Section

    private var cardHeader: some View {
        HStack {
            HStack(spacing: 8) {
                UnifiedTag(text: "両替", color: .blue)

                // 入力方式インジケーター
                inputMethodBadge
            }

            Spacer()

            Text(CurrencyFormatter.formatDate(exchange.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var inputMethodBadge: some View {
        let inputType = exchange.rateInputType ?? .legacy
        let color = colorForInputType(inputType)

        return UnifiedTag(
            text: inputType.displayName,
            color: color,
            style: .filled
        )
    }

    // MARK: - Input Rate Section

    private var inputRateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("入力レート")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // 入力方式の詳細表示
                inputTypeDetail
            }

            Text(exchange.displayRateString(currencyCode: currency.code))
                .font(.subheadline)
                .fontWeight(.medium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var inputTypeDetail: some View {
        let inputType = exchange.rateInputType ?? .legacy

        return HStack(spacing: 4) {
            Image(systemName: iconForInputType(inputType))
                .font(.caption2)
                .foregroundColor(colorForInputType(inputType))

            Text(inputType.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Exchange Details Section

    private var exchangeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日本円金額
            HStack {
                Text("日本円:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyFormatter.formatJPY(exchange.jpyAmount))
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // 矢印（アニメーション付き）
            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .scaleEffect(1.2)
                Spacer()
            }

            // 外貨金額
            HStack {
                Text("\(currency.name):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyFormatter.formatForeign(exchange.foreignAmount, currencyCode: currency.code))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Rate Info Section

    private var rateInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            UnifiedDivider()

            // 実質レート
            HStack {
                Text("実質レート:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("1\(currency.code) = \(CurrencyFormatter.formatRate(exchange.actualRate))円")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // 手数料情報
            if exchange.feePercentage != 0 {
                HStack {
                    Text("手数料:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(String(format: "%.2f", exchange.feePercentage))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(exchange.isHighFee ? .red : .green)

                        if exchange.isHighFee {
                            UnifiedWarningIcon()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func colorForInputType(_ type: RateInputType) -> Color {
        switch type {
        case .legacy:
            return .gray
        case .exchangeOffice:
            return .blue
        case .perYen:
            return .green
        case .perForeign:
            return .orange
        }
    }

    private func iconForInputType(_ type: RateInputType) -> String {
        switch type {
        case .legacy:
            return "clock"
        case .exchangeOffice:
            return "building.2"
        case .perYen:
            return "yensign.circle"
        case .perForeign:
            return "dollarsign.circle"
        }
    }
}

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

// MARK: - 統一されたUIコンポーネント

/// 統一されたタグ
struct UnifiedTag: View {
    let text: String
    let color: Color
    let style: TagStyle

    enum TagStyle {
        case outlined
        case filled
    }

    init(text: String, color: Color, style: TagStyle = .outlined) {
        self.text = text
        self.color = color
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(6)
    }

    private var backgroundColor: Color {
        switch style {
        case .outlined:
            return color.opacity(0.15)
        case .filled:
            return color
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .outlined:
            return color
        case .filled:
            return .white
        }
    }
}

/// 統一された区切り線
struct UnifiedDivider: View {
    var body: some View {
        Divider()
            .background(Color.gray.opacity(0.3))
    }
}

/// 統一された警告アイコン
struct UnifiedWarningIcon: View {
    let color: Color

    init(color: Color = .orange) {
        self.color = color
    }

    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundColor(color)
    }
}

/// 統一された警告ビュー
struct UnifiedWarningView: View {
    let message: String
    let icon: String
    let color: Color

    init(message: String, icon: String = "exclamationmark.triangle.fill", color: Color = .orange) {
        self.message = message
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)

            Text(message)
                .font(.caption2)
                .foregroundColor(color)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Exchange Card - Legacy") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ResponsiveExchangeCard(
                exchange: ExchangeRecord(
                    date: Date(),
                    jpyAmount: 10000,
                    displayRate: 0.109,
                    foreignAmount: 91700
                ),
                currency: Currency(code: "KRW", name: "韓国ウォン")
            )
        }
        .padding()
    }
}

#Preview("Exchange Card - New Format") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ResponsiveExchangeCard(
                exchange: ExchangeRecord(
                    date: Date(),
                    jpyAmount: 5000,
                    foreignAmount: 45000,
                    rateInputType: .exchangeOffice,
                    inputValue1: 100,
                    inputValue2: 900
                ),
                currency: Currency(code: "KRW", name: "韓国ウォン")
            )
        }
        .padding()
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
