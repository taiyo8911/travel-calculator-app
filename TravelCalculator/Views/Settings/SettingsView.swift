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
            versionRow
            aboutAppButton
        }
    }

    private var versionRow: some View {
        HStack {
            Text("バージョン")
            Spacer()
            Text("1.0.0")
                .foregroundColor(.secondary)
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
                titleView
                versionView
                dividerView
                descriptionView
                copyrightView
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("閉じる") {
                dismiss()
            })
            .navigationTitle("このアプリについて")
        }
    }

    private var iconView: some View {
        Image(systemName: "airplane.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.blue)
    }

    private var titleView: some View {
        Text("Travel Calculator")
            .font(.largeTitle)
            .fontWeight(.bold)
    }

    private var versionView: some View {
        Text("Version 1.0.0")
            .foregroundColor(.secondary)
    }

    private var dividerView: some View {
        Divider()
            .padding(.horizontal, 50)
            .padding(.vertical, 10)
    }

    private var descriptionView: some View {
        Text("海外旅行中の両替と買い物の記録を簡単に管理するアプリです。")
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private var copyrightView: some View {
        Text("© 2025 MAC-YA")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 30)
    }
}

#Preview{
    SettingsView()
}
