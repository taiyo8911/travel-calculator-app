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

    // MARK: - Managers
    private let dataManager: DataManagerProtocol
    private let navigationManager: NavigationManager
    private let pdfManager: PDFManagerProtocol

    // MARK: - Published Properties
    @Published var trips: [Trip] = []
    @Published var selectedTripId: UUID?
    @Published var isSettingsViewPresented: Bool = false
    @Published var showingAddTripSheet = false

    var navigationPath: NavigationPath {
        get { navigationManager.navigationPath }
        set { navigationManager.navigationPath = newValue }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(dataManager: DataManagerProtocol = DataManager(),
         navigationManager: NavigationManager = NavigationManager(),
         pdfManager: PDFManagerProtocol = PDFManager()) {

        self.dataManager = dataManager
        self.navigationManager = navigationManager
        self.pdfManager = pdfManager

        setupBindings()
        loadData()
    }

    private func setupBindings() {
        navigationManager.$navigationPath
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func loadData() {
        trips = dataManager.loadTrips()
        selectedTripId = dataManager.loadSelectedTripId()
    }

    private func saveData() {
        dataManager.save(trips: trips)
        dataManager.saveSelectedTripId(selectedTripId)
    }

    // MARK: - Trip Management

    func addTrip(_ trip: Trip) {
        trips.append(trip)
        selectedTripId = trip.id
        navigationManager.navigateToTrip(trip)
        saveData()
    }

    func deleteTrip(withId id: UUID) {
        trips.removeAll(where: { $0.id == id })
        if selectedTripId == id {
            selectedTripId = trips.first?.id
        }
        saveData()
    }

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

    func addExchangeRecord(_ record: ExchangeRecord, toTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].exchangeRecords.append(record)
            saveData()
        }
    }

    func updateExchangeRecord(_ updatedRecord: ExchangeRecord, inTripWithId tripId: UUID) {
        if let tripIndex = trips.firstIndex(where: { $0.id == tripId }),
           let recordIndex = trips[tripIndex].exchangeRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
            trips[tripIndex].exchangeRecords[recordIndex] = updatedRecord
            saveData()
        }
    }

    func deleteExchangeRecord(at indexSet: IndexSet, from sortedRecords: [ExchangeRecord], inTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            let idsToDelete = indexSet.map { sortedRecords[$0].id }
            trips[index].exchangeRecords.removeAll(where: { idsToDelete.contains($0.id) })
            saveData()
        }
    }

    // MARK: - Purchase Record Management

    func addPurchaseRecord(_ record: PurchaseRecord, toTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].purchaseRecords.append(record)
            saveData()
        }
    }

    func updatePurchaseRecord(_ updatedRecord: PurchaseRecord, inTripWithId tripId: UUID) {
        if let tripIndex = trips.firstIndex(where: { $0.id == tripId }),
           let recordIndex = trips[tripIndex].purchaseRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
            trips[tripIndex].purchaseRecords[recordIndex] = updatedRecord
            saveData()
        }
    }

    func deletePurchaseRecord(at indexSet: IndexSet, from sortedRecords: [PurchaseRecord], inTripWithId tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            let idsToDelete = indexSet.map { sortedRecords[$0].id }
            trips[index].purchaseRecords.removeAll(where: { idsToDelete.contains($0.id) })
            saveData()
        }
    }

    // MARK: - UI State Management

    func closeAddTripSheet() {
        self.showingAddTripSheet = false
    }

    var selectedTrip: Trip? {
        guard let id = selectedTripId else { return nil }
        return trips.first { $0.id == id }
    }

    // MARK: - Navigation

    func navigateToTrip(_ trip: Trip) {
        selectedTripId = trip.id
        navigationManager.navigateToTrip(trip)
    }

    func navigateToTripDetail(_ tripId: UUID) {
        navigationManager.navigateToTripDetail(tripId)
    }

    func navigateToExchangeList(_ tripId: UUID) {
        navigationManager.navigateToExchangeList(tripId)
    }

    func navigateToPurchaseList(_ tripId: UUID) {
        navigationManager.navigateToPurchaseList(tripId)
    }

    func clearNavigation() {
        navigationManager.clearNavigation()
    }

    func navigateBack() {
        navigationManager.navigateBack()
    }

    // MARK: - Data Management

    func resetAllData() {
        trips = []
        selectedTripId = nil
        navigationManager.clearNavigation()
        dataManager.resetAllData()
    }

    func validateAndRepairData() {
        trips = dataManager.validateAndRepairData()
    }

    // MARK: - Statistics

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

    func generatePDF(for trip: Trip) -> Data? {
        return pdfManager.generateTripPDF(trip: trip)
    }

    func sharePDF(for trip: Trip, from viewController: UIViewController) {
        pdfManager.sharePDF(for: trip, from: viewController)
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
