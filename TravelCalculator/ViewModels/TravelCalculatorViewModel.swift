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
    }

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

    // 両替記録を特定の旅行に追加
    func addExchangeRecord(_ record: ExchangeRecord, toTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].exchangeRecords.append(record)
            saveData()
        }
    }

    // 買い物記録を特定の旅行に追加
    func addPurchaseRecord(_ record: PurchaseRecord, toTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].purchaseRecords.append(record)
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

    // 買い物記録を削除
    func deletePurchaseRecord(at indexSet: IndexSet, from sortedRecords: [PurchaseRecord], inTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            let idsToDelete = indexSet.map { sortedRecords[$0].id }
            trips[index].purchaseRecords.removeAll(where: { idsToDelete.contains($0.id) })
            saveData()
        }
    }

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
        saveData()
    }


    // TravelCalculatorViewModel.swift に追加する編集機能のメソッド

    // 両替記録を更新
    func updateExchangeRecord(_ updatedRecord: ExchangeRecord, inTripWithId tripId: UUID) {
        if let tripIndex = trips.firstIndex(where: { $0.id == tripId }),
           let recordIndex = trips[tripIndex].exchangeRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
            trips[tripIndex].exchangeRecords[recordIndex] = updatedRecord
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
}
