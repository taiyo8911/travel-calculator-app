//
//  TravelCalculatorApp.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/02.
//

import SwiftUI

@main
struct TravelCalculatorApp: App {
    @StateObject private var viewModel = TravelCalculatorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
