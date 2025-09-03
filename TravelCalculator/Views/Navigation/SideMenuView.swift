//
//  SideMenuView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/06/23.
//


import SwiftUI

struct SideMenuView: View {
    @Binding var isPresented: Bool
    @Binding var showingStatistics: Bool
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel

    private let feedbackFormURL = "https://forms.gle/WiAJaAzPGh3G4vCY9"

    var body: some View {
        ZStack {
            // 背景オーバーレイ（タップで閉じる）
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeSideMenu()
                    }
            }

            // サイドメニュー本体
            HStack {
                if isPresented {
                    sideMenuContent
                        .frame(width: UIScreen.main.bounds.width * 0.7)
                        .background(Color(UIColor.systemBackground))
                        .transition(.move(edge: .leading))
                }

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }

    // MARK: - サイドメニューコンテンツ

    private var sideMenuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            menuHeader

            // メニュー項目
            ScrollView {
                VStack(spacing: 0) {
                    // メニュー項目セクション
                    menuItemsSection
                }
            }

            Spacer()
        }
        .padding(.top, getSafeAreaTop())
    }

    // MARK: - ヘッダー

    private var menuHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // アプリアイコンとタイトル
                HStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("トラベルマネージャー")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                // 閉じるボタン
                Button(action: closeSideMenu) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - メニュー項目セクション

    private var menuItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                MenuItemButton(
                    icon: "chart.bar.fill",
                    title: "統計情報",
                    action: {
                        closeSideMenu()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingStatistics = true
                        }
                    }
                )

                MenuItemButton(
                    icon: "envelope",
                    title: "お問い合わせ",
                    action: {
                        closeSideMenu()
                        openFeedbackForm()
                    }
                )
            }
        }
    }

    // MARK: - ヘルパーメソッド

    private func closeSideMenu() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }

    private func openFeedbackForm() {
        guard let url = URL(string: feedbackFormURL) else {
            print("無効なURL: \(feedbackFormURL)")
            return
        }

        // Safariで開く
        UIApplication.shared.open(url)
    }

    private func getSafeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.top
    }
}

// MARK: - メニュー項目ボタンコンポーネント

struct MenuItemButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(UIColor.secondarySystemBackground)
                    .opacity(0.01) // タップ領域確保のための透明背景
            )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(Color(UIColor.secondarySystemBackground))
                .opacity(0)
        )
        .onTapGesture {
            action()
        }
    }
}

#Preview("サイドメニュー") {
    ZStack {
        Color.gray.ignoresSafeArea()

        SideMenuView(
            isPresented: .constant(true),
            showingStatistics: .constant(false)
        )
        .environmentObject(TravelCalculatorViewModel())
    }
}
