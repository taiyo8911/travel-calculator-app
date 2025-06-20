//
//  NavigationManager.swift
//  TravelCalculator
//
//  Created by Refactoring on 2025/06/20.
//

import Foundation
import SwiftUI
import Combine

protocol NavigationManagerProtocol {
    var navigationPath: NavigationPath { get set }
    func navigateToTripDetail(_ tripId: UUID)
    func navigateToExchangeList(_ tripId: UUID)
    func navigateToPurchaseList(_ tripId: UUID)
    func clearNavigation()
    func navigateBack()
    func navigateToTrip(_ trip: Trip) // プロトコルにも追加
}

class NavigationManager: NavigationManagerProtocol, ObservableObject {

    @Published var navigationPath = NavigationPath()

    // MARK: - Navigation Methods

    func navigateToTripDetail(_ tripId: UUID) {
        navigationPath.append(NavigationDestination.tripDetail(tripId: tripId))
    }

    func navigateToExchangeList(_ tripId: UUID) {
        navigationPath.append(NavigationDestination.exchangeList(tripId: tripId))
    }

    func navigateToPurchaseList(_ tripId: UUID) {
        navigationPath.append(NavigationDestination.purchaseList(tripId: tripId))
    }

    func clearNavigation() {
        navigationPath = NavigationPath()
    }

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    // MARK: - Legacy Support (旅行オブジェクトを受け取る既存メソッドとの互換性)

    func navigateToTrip(_ trip: Trip) {
        navigateToTripDetail(trip.id)
    }
}
