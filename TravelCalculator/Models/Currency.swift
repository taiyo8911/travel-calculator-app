//
//  Currency.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import Foundation

struct Currency: Codable, Identifiable, Hashable, Equatable {
    var id = UUID()
    var code: String // 通貨コード (例: USD, EUR)
    var name: String // 通貨名 (例: 米ドル, ユーロ)

    // イニシャライザ
    init(code: String, name: String) {
        self.id = UUID()
        self.code = code
        self.name = name
    }

    // Equatableプロトコルの実装
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.id == rhs.id && lhs.code == rhs.code && lhs.name == rhs.name
    }

    // 利用可能な通貨のリスト
    static var availableCurrencies: [Currency] = [
        // 北米・南米
        Currency(code: "USD", name: "米ドル"),
        Currency(code: "CAD", name: "カナダドル"),
        Currency(code: "MXN", name: "メキシコペソ"),

        // ヨーロッパ
        Currency(code: "EUR", name: "ユーロ"),
        Currency(code: "GBP", name: "英ポンド"),
        Currency(code: "CHF", name: "スイスフラン"),

        // 東アジア
        Currency(code: "CNY", name: "中国元"),
        Currency(code: "HKD", name: "香港ドル"),
        Currency(code: "TWD", name: "台湾ドル"),
        Currency(code: "KRW", name: "韓国ウォン"),

        // 東南アジア
        Currency(code: "THB", name: "タイバーツ"),
        Currency(code: "SGD", name: "シンガポールドル"),
        Currency(code: "MYR", name: "マレーシアリンギット"),
        Currency(code: "IDR", name: "インドネシアルピア"),
        Currency(code: "VND", name: "ベトナムドン"),
        Currency(code: "PHP", name: "フィリピンペソ"),

        // オセアニア
        Currency(code: "AUD", name: "豪ドル"),
        Currency(code: "NZD", name: "NZドル")
    ]
}
