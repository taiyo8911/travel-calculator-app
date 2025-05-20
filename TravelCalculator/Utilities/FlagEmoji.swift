//
//  FlagEmoji.swift
//  TravelCalculator
//
//  Created by Taiyo KOSHIBA on 2025/04/05.
//

import Foundation


// 国コードから国旗絵文字に変換するユーティリティ関数
public func flagEmoji(for code: String) -> String {
    // 通貨コードの最初の2文字を国コードとして扱う
    let countryCode = String(code.prefix(2))

    let base: UInt32 = 127397
    var emoji = ""
    for scalar in countryCode.uppercased().unicodeScalars {
        if scalar.value >= 65 && scalar.value <= 90 {
            if let scalar = UnicodeScalar(base + scalar.value) {
                emoji.unicodeScalars.append(scalar)
            }
        }
    }
    return emoji
}
