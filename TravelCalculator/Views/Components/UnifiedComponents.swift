//
//  UnifiedComponents.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/06/20.
//

import SwiftUI

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

#Preview("Unified Components") {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            UnifiedTag(text: "両替", color: .blue)
            UnifiedTag(text: "買い物", color: .green, style: .filled)
        }

        UnifiedDivider()

        UnifiedWarningIcon()

        UnifiedWarningView(message: "これは警告メッセージのサンプルです")
    }
    .padding()
}
