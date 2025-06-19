//
//  SummaryCard.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct SummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    // 動的なレイアウト設定
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var isLargeText: Bool {
        dynamicTypeSize >= .xLarge
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isLargeText ? 12 : 8) {
            // アイコンとタイトル
            headerSection

            // 値の表示
            valueSection
        }
        .padding(isCompact ? 12 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder, alignment: .leading)
    }

    // MARK: - セクション

    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: iconSize, weight: .medium))
                .frame(width: iconFrameSize, height: iconFrameSize)

            Text(title)
                .font(titleFont)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
    }

    private var valueSection: some View {
        Text(value)
            .font(valueFont)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .lineLimit(isLargeText ? 3 : 2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - スタイリング

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(UIColor.secondarySystemBackground))
            .shadow(
                color: Color.black.opacity(0.08),
                radius: isCompact ? 4 : 6,
                x: 0,
                y: isCompact ? 2 : 3
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.2), lineWidth: 1)
    }

    // MARK: - 動的サイズ設定

    private var iconSize: CGFloat {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large:
            return isCompact ? 18 : 20
        case .xLarge:
            return isCompact ? 20 : 22
        default:
            return isCompact ? 22 : 24
        }
    }

    private var iconFrameSize: CGFloat {
        iconSize + 4
    }

    private var titleFont: Font {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large:
            return .caption
        case .xLarge:
            return .subheadline
        default:
            return .subheadline
        }
    }

    private var valueFont: Font {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large:
            return isCompact ? .subheadline : .headline
        case .xLarge:
            return .headline
        default:
            return .title3
        }
    }
}

// MARK: - 特殊用途のサマリーカード

/// 警告付きサマリーカード
struct WarningSummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    var warningMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SummaryCard(title: title, value: value, icon: icon, color: color)

            UnifiedWarningView(message: warningMessage, color: .orange)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
    }
}

/// インタラクティブサマリーカード
struct InteractiveSummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    var action: (() -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button(action: action ?? {}) {
            SummaryCard(title: title, value: value, icon: icon, color: color)
        }
        .buttonStyle(InteractiveCardButtonStyle())
        .disabled(action == nil)
    }
}

/// インタラクティブカード用のボタンスタイル
struct InteractiveCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 進行状況付きサマリーカード
struct ProgressSummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    var progress: Double // 0.0 - 1.0
    var progressLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SummaryCard(title: title, value: value, icon: icon, color: color)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(progressLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(y: 0.8)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}

#Preview("Standard Cards") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 16) {
        SummaryCard(
            title: "両替レート",
            value: "1 USD = 110 JPY",
            icon: "arrow.left.arrow.right.circle.fill",
            color: .blue
        )

        SummaryCard(
            title: "合計支出額",
            value: "¥45,000",
            icon: "cart.circle.fill",
            color: .green
        )

        SummaryCard(
            title: "残り外貨",
            value: "計算不可",
            icon: "dollarsign.circle.fill",
            color: .orange
        )

        SummaryCard(
            title: "旅行日数",
            value: "7日間",
            icon: "calendar.circle.fill",
            color: .purple
        )
    }
    .padding()
}

#Preview("Special Cards") {
    VStack(spacing: 16) {
        WarningSummaryCard(
            title: "合計支出額",
            value: "計算不可",
            icon: "cart.circle.fill",
            color: .orange,
            warningMessage: "両替記録が無いため計算できません"
        )

        InteractiveSummaryCard(
            title: "両替を追加",
            value: "タップして追加",
            icon: "plus.circle.fill",
            color: .blue,
            action: { print("Add exchange tapped") }
        )

        ProgressSummaryCard(
            title: "予算使用状況",
            value: "¥35,000 / ¥50,000",
            icon: "chart.bar.fill",
            color: .green,
            progress: 0.7,
            progressLabel: "予算進捗"
        )
    }
    .padding()
}
