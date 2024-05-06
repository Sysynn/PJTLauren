//
//  Utilities.swift
//  PJTLauren
//
//  Created by Synn on 5/5/24.
//

import Foundation

func numberToKorean(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    formatter.locale = Locale(identifier: "ko_KR")
    if let formattedNumber = formatter.string(from: NSNumber(value: number)) {
        return formattedNumber
    }
    return ""
}
