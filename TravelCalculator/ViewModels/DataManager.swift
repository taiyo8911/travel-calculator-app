//
//  DataManager.swift
//  TravelCalculator
//
//  Created by Refactoring on 2025/06/20.
//

import Foundation
import Combine

protocol DataManagerProtocol {
    func save(trips: [Trip])
    func loadTrips() -> [Trip]
    func saveSelectedTripId(_ id: UUID?)
    func loadSelectedTripId() -> UUID?
    func resetAllData()
    func validateAndRepairData() -> [Trip] // この行を追加
}

class DataManager: DataManagerProtocol, ObservableObject {

    // データバージョン管理
    private let currentDataVersion = "1.1.0"
    private let dataVersionKey = "TravelCalculator_DataVersion"

    init() {
        performDataMigrationIfNeeded()
    }

    // MARK: - Public Methods

    func save(trips: [Trip]) {
        if let encoded = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encoded, forKey: "trips")
        }
        UserDefaults.standard.set(currentDataVersion, forKey: dataVersionKey)
    }

    func loadTrips() -> [Trip] {
        guard let data = UserDefaults.standard.data(forKey: "trips"),
              let decodedTrips = try? JSONDecoder().decode([Trip].self, from: data) else {
            return []
        }
        return decodedTrips
    }

    func saveSelectedTripId(_ id: UUID?) {
        if let id = id {
            UserDefaults.standard.set(id.uuidString, forKey: "selectedTripId")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedTripId")
        }
    }

    func loadSelectedTripId() -> UUID? {
        guard let selectedIdString = UserDefaults.standard.string(forKey: "selectedTripId") else {
            return nil
        }
        return UUID(uuidString: selectedIdString)
    }

    func resetAllData() {
        UserDefaults.standard.removeObject(forKey: "trips")
        UserDefaults.standard.removeObject(forKey: "selectedTripId")
        UserDefaults.standard.removeObject(forKey: dataVersionKey)
    }

    func validateAndRepairData() -> [Trip] {
        var trips = loadTrips()
        var repairCount = 0

        for tripIndex in trips.indices {
            for exchangeIndex in trips[tripIndex].exchangeRecords.indices {
                let exchange = trips[tripIndex].exchangeRecords[exchangeIndex]

                if exchange.rateInputType == nil {
                    var repairedExchange = exchange
                    repairedExchange.rateInputType = .legacy
                    repairedExchange.inputValue1 = exchange.displayRate
                    repairedExchange.inputValue2 = nil

                    trips[tripIndex].exchangeRecords[exchangeIndex] = repairedExchange
                    repairCount += 1
                }

                if exchange.jpyAmount <= 0 || exchange.foreignAmount <= 0 {
                    print("警告: 不正な値が検出されました - 旅行: \(trips[tripIndex].name), 両替ID: \(exchange.id)")
                }
            }
        }

        if repairCount > 0 {
            save(trips: trips)
            print("修復されたデータ: \(repairCount)件")
        }

        return trips
    }

    // MARK: - Data Migration

    private func performDataMigrationIfNeeded() {
        let savedVersion = UserDefaults.standard.string(forKey: dataVersionKey) ?? "1.0.0"

        if shouldMigrateData(from: savedVersion, to: currentDataVersion) {
            print("データ移行を開始します: \(savedVersion) → \(currentDataVersion)")
            performDataMigration(from: savedVersion)
            UserDefaults.standard.set(currentDataVersion, forKey: dataVersionKey)
            print("データ移行が完了しました")
        }
    }

    private func shouldMigrateData(from oldVersion: String, to newVersion: String) -> Bool {
        return oldVersion.hasPrefix("1.0") && newVersion.hasPrefix("1.1")
    }

    private func performDataMigration(from version: String) {
        if version.hasPrefix("1.0") {
            migrateFromV1_0ToV1_1()
        }
    }

    private func migrateFromV1_0ToV1_1() {
        var trips = loadTrips()
        var migrationCount = 0

        for tripIndex in trips.indices {
            for exchangeIndex in trips[tripIndex].exchangeRecords.indices {
                let exchange = trips[tripIndex].exchangeRecords[exchangeIndex]

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

        if migrationCount > 0 {
            save(trips: trips)
            print("移行された両替記録: \(migrationCount)件")
        }
    }
}
