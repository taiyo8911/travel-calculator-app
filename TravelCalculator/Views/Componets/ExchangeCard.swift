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
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            cardHeader

            Divider()

            // 入力レート表示
            inputRateSection

            // 両替詳細
            exchangeDetailsSection

            // レート情報
            rateInfoSection
        }
        .padding()
        .frame(width: 280) // 少し幅を広げる
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
                Text("両替")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)

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

        return Text(inputType.displayName)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }

    // MARK: - Input Rate Section

    private var inputRateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("入力レート")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(exchange.displayRateString(currencyCode: currency.code))
                .font(.subheadline)
                .fontWeight(.medium)
                .fixedSize(horizontal: false, vertical: true)
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

            // 矢印
            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
                    .font(.caption)
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
            Divider()

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
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            // 既存データ（従来方式）
            ExchangeCard(
                exchange: ExchangeRecord(
                    date: Date(),
                    jpyAmount: 10000,
                    displayRate: 0.109,
                    foreignAmount: 91700
                ),
                currency: Currency(code: "KRW", name: "韓国ウォン")
            )

            // 新データ（両替所表示方式）
            ExchangeCard(
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

            // 新データ（1円あたり方式）
            ExchangeCard(
                exchange: ExchangeRecord(
                    date: Date(),
                    jpyAmount: 3000,
                    foreignAmount: 27000,
                    rateInputType: .perYen,
                    inputValue1: 9.0,
                    inputValue2: nil
                ),
                currency: Currency(code: "KRW", name: "韓国ウォン")
            )

            // 新データ（1外貨あたり方式）
            ExchangeCard(
                exchange: ExchangeRecord(
                    date: Date(),
                    jpyAmount: 15000,
                    foreignAmount: 100,
                    rateInputType: .perForeign,
                    inputValue1: 150.0,
                    inputValue2: nil
                ),
                currency: Currency(code: "USD", name: "米ドル")
            )
        }
        .padding()
    }
}
