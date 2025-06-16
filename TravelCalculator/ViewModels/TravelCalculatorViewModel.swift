//
//  TravelCalculatorViewModel.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import Foundation
import Combine
import SwiftUI

class TravelCalculatorViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var selectedTripId: UUID?
    @Published var navigationPath = NavigationPath()

    @Published var isSettingsViewPresented: Bool = false // 設定画面を表示するフラグ
    @Published var showingAddTripSheet = false // 旅行追加シートを表示するフラグ

    // データバージョン管理
    private let currentDataVersion = "1.1.0"
    private let dataVersionKey = "TravelCalculator_DataVersion"

    // 旅行追加後の処理
    func closeAddTripSheet() {
        self.showingAddTripSheet = false
    }

    // 選択中の旅行
    var selectedTrip: Trip? {
        guard let id = selectedTripId else { return nil }
        return trips.first { $0.id == id }
    }

    // 特定の旅行に遷移
    func navigateToTrip(_ trip: Trip) {
        selectedTripId = trip.id
        navigationPath.append(trip)
    }

    init() {
        loadData()
        performDataMigrationIfNeeded()
    }

    // MARK: - Trip Management

    // 旅行を追加
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        selectedTripId = trip.id
        navigateToTrip(trip)
        saveData()
    }

    // 旅行を削除
    func deleteTrip(withId id: UUID) {
        trips.removeAll(where: { $0.id == id })
        if selectedTripId == id {
            selectedTripId = trips.first?.id
        }
        saveData()
    }

    // 旅行情報を更新
    func updateTrip(_ updatedTrip: Trip) {
        objectWillChange.send()

        trips = trips.map { trip in
            if trip.id == updatedTrip.id {
                return updatedTrip
            } else {
                return trip
            }
        }

        saveData()
    }

    // MARK: - Exchange Record Management

    // 両替記録を特定の旅行に追加
    func addExchangeRecord(_ record: ExchangeRecord, toTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].exchangeRecords.append(record)
            saveData()
        }
    }

    // 両替記録を更新
    func updateExchangeRecord(_ updatedRecord: ExchangeRecord, inTripWithId tripId: UUID) {
        if let tripIndex = trips.firstIndex(where: { $0.id == tripId }),
           let recordIndex = trips[tripIndex].exchangeRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
            trips[tripIndex].exchangeRecords[recordIndex] = updatedRecord
            saveData()
        }
    }

    // 両替記録を削除
    func deleteExchangeRecord(at indexSet: IndexSet, from sortedRecords: [ExchangeRecord], inTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            let idsToDelete = indexSet.map { sortedRecords[$0].id }
            trips[index].exchangeRecords.removeAll(where: { idsToDelete.contains($0.id) })
            saveData()
        }
    }

    // MARK: - Purchase Record Management

    // 買い物記録を特定の旅行に追加
    func addPurchaseRecord(_ record: PurchaseRecord, toTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].purchaseRecords.append(record)
            saveData()
        }
    }

    // 買い物記録を更新
    func updatePurchaseRecord(_ updatedRecord: PurchaseRecord, inTripWithId tripId: UUID) {
        if let tripIndex = trips.firstIndex(where: { $0.id == tripId }),
           let recordIndex = trips[tripIndex].purchaseRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
            trips[tripIndex].purchaseRecords[recordIndex] = updatedRecord
            saveData()
        }
    }

    // 買い物記録を削除
    func deletePurchaseRecord(at indexSet: IndexSet, from sortedRecords: [PurchaseRecord], inTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            let idsToDelete = indexSet.map { sortedRecords[$0].id }
            trips[index].purchaseRecords.removeAll(where: { idsToDelete.contains($0.id) })
            saveData()
        }
    }

    // MARK: - Data Persistence

    // データの永続化
    func saveData() {
        if let encoded = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encoded, forKey: "trips")
        }

        if let selectedId = selectedTripId {
            UserDefaults.standard.set(selectedId.uuidString, forKey: "selectedTripId")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedTripId")
        }

        // データバージョンを保存
        UserDefaults.standard.set(currentDataVersion, forKey: dataVersionKey)
    }

    // データの読み込み
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "trips"),
           let decodedTrips = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decodedTrips
        }

        if let selectedIdString = UserDefaults.standard.string(forKey: "selectedTripId"),
           let selectedId = UUID(uuidString: selectedIdString) {
            selectedTripId = selectedId
        }
    }

    // すべてのデータをリセット
    func resetAllData() {
        trips = []
        selectedTripId = nil
        navigationPath = NavigationPath()
        UserDefaults.standard.removeObject(forKey: "trips")
        UserDefaults.standard.removeObject(forKey: "selectedTripId")
        UserDefaults.standard.removeObject(forKey: dataVersionKey)
        saveData()
    }

    // MARK: - Data Migration

    // データ移行が必要かチェック
    private func performDataMigrationIfNeeded() {
        let savedVersion = UserDefaults.standard.string(forKey: dataVersionKey) ?? "1.0.0"

        if shouldMigrateData(from: savedVersion, to: currentDataVersion) {
            print("データ移行を開始します: \(savedVersion) → \(currentDataVersion)")
            performDataMigration(from: savedVersion)
            saveData() // 移行後のデータを保存
            print("データ移行が完了しました")
        }
    }

    // データ移行が必要かどうか判定
    private func shouldMigrateData(from oldVersion: String, to newVersion: String) -> Bool {
        // バージョン1.0.x から 1.1.x への移行が必要
        return oldVersion.hasPrefix("1.0") && newVersion.hasPrefix("1.1")
    }

    // データ移行の実行
    private func performDataMigration(from version: String) {
        if version.hasPrefix("1.0") {
            migrateFromV1_0ToV1_1()
        }
    }

    // バージョン1.0から1.1への移行
    private func migrateFromV1_0ToV1_1() {
        var migrationCount = 0

        for tripIndex in trips.indices {
            for exchangeIndex in trips[tripIndex].exchangeRecords.indices {
                let exchange = trips[tripIndex].exchangeRecords[exchangeIndex]

                // rateInputTypeがnilの場合、legacyに設定
                if exchange.rateInputType == nil {
                    var migratedExchange = exchange
                    migratedExchange.rateInputType = .legacy
                    migratedExchange.inputValue1 = exchange.displayRate
                    migratedExchange.inputValue2 = nil

                    trips[tripIndex].exchangeRecords[exchangeIndex] = migratedExchange
                    migrationCount += 1
                }
            }
        }

        print("移行された両替記録: \(migrationCount)件")
    }

    // MARK: - Data Validation and Repair

    // データの整合性チェック
    func validateAndRepairData() {
        var repairCount = 0

        for tripIndex in trips.indices {
            for exchangeIndex in trips[tripIndex].exchangeRecords.indices {
                let exchange = trips[tripIndex].exchangeRecords[exchangeIndex]

                // rateInputTypeがnilの記録を修復
                if exchange.rateInputType == nil {
                    var repairedExchange = exchange
                    repairedExchange.rateInputType = .legacy
                    repairedExchange.inputValue1 = exchange.displayRate
                    repairedExchange.inputValue2 = nil

                    trips[tripIndex].exchangeRecords[exchangeIndex] = repairedExchange
                    repairCount += 1
                }

                // 不正な値のチェック
                if exchange.jpyAmount <= 0 || exchange.foreignAmount <= 0 {
                    print("警告: 不正な値が検出されました - 旅行: \(trips[tripIndex].name), 両替ID: \(exchange.id)")
                }
            }
        }

        if repairCount > 0 {
            print("修復されたデータ: \(repairCount)件")
            saveData()
        }
    }

    // MARK: - Statistics and Analytics

    // 全体統計情報
    var overallStats: OverallStats {
        let allExchangeRecords = trips.flatMap { $0.exchangeRecords }
        let allPurchaseRecords = trips.flatMap { $0.purchaseRecords }

        let inputTypeBreakdown = Dictionary(grouping: allExchangeRecords) {
            $0.rateInputType ?? .legacy
        }.mapValues { $0.count }

        return OverallStats(
            totalTrips: trips.count,
            totalExchangeRecords: allExchangeRecords.count,
            totalPurchaseRecords: allPurchaseRecords.count,
            inputTypeBreakdown: inputTypeBreakdown,
            activeTrips: trips.filter { $0.isActive }.count,
            upcomingTrips: trips.filter { !$0.isActive && $0.startDate > Date() }.count
        )
    }

    // MARK: - PDF Generation

    // PDF生成メソッド
    func generatePDF(for trip: Trip) -> Data? {
        return PDFGenerator.generateTripPDF(trip: trip)
    }

    // PDF共有メソッド
    func sharePDF(for trip: Trip, from viewController: UIViewController) {
        guard let pdfData = generatePDF(for: trip) else {
            print("PDFの生成に失敗しました")
            return
        }

        // 一時ファイルとしてPDFを保存
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(trip.name)_旅行記録.pdf")

        do {
            try pdfData.write(to: tmpURL)

            // 共有シートを表示
            let activityVC = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
            viewController.present(activityVC, animated: true)
        } catch {
            print("PDF保存エラー: \(error)")
        }
    }
}

// MARK: - Supporting Structures

struct OverallStats {
    let totalTrips: Int
    let totalExchangeRecords: Int
    let totalPurchaseRecords: Int
    let inputTypeBreakdown: [RateInputType: Int]
    let activeTrips: Int
    let upcomingTrips: Int

    var mostUsedInputType: RateInputType? {
        return inputTypeBreakdown.max(by: { $0.value < $1.value })?.key
    }

    var inputTypeUsagePercentage: [RateInputType: Double] {
        guard totalExchangeRecords > 0 else { return [:] }

        return inputTypeBreakdown.mapValues { count in
            Double(count) / Double(totalExchangeRecords) * 100
        }
    }
}
