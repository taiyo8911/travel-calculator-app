//
//  SettingsView.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: TravelCalculatorViewModel
    @State private var showResetConfirmation = false
    @State private var showAboutSheet = false

    var body: some View {
        Form {
            dataManagementSection
            appInformationSection
        }
        .navigationTitle("設定")
        .alert("すべてのデータをリセット", isPresented: $showResetConfirmation) {
            resetConfirmationButtons
        } message: {
            Text("すべての旅行データが削除されます。この操作は元に戻せません。")
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView()
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var dataManagementSection: some View {
        Section(header: Text("データ管理")) {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("すべてのデータを削除")
                }
            }
        }
    }

    private var appInformationSection: some View {
        Section(header: Text("アプリ情報")) {
            aboutAppButton
        }
    }

    private var aboutAppButton: some View {
        Button(action: { showAboutSheet = true }) {
            HStack {
                Image(systemName: "info.circle")
                Text("このアプリについて")
            }
        }
    }

    private func externalLinkContent(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text)
            Spacer()
            Image(systemName: "arrow.up.forward.square")
                .font(.caption)
        }
    }

    private var resetConfirmationButtons: some View {
        Group {
            Button("キャンセル", role: .cancel) { }
            Button("リセット", role: .destructive) {
                viewModel.resetAllData()
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                iconView
                dividerView
                descriptionView
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("閉じる") {
                dismiss()
            })
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var iconView: some View {
        Image(systemName: "airplane.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.blue)
    }

    private var dividerView: some View {
        Divider()
            .padding(.horizontal, 50)
            .padding(.vertical, 10)
    }

    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("海外旅行のお金を管理するアプリです。")
            Text("両替記録や買い物履歴を簡単に記録できます。")
            Text("データは旅行ごとにPDFで出力できます。")
            Text("")
            Text("※アプリを削除するとデータも削除されてしまいます。")
                .fontWeight(.bold)
        }
    }
}

#Preview{
    SettingsView()
}
