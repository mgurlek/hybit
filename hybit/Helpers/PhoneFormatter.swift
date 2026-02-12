//
//  PhoneFormatter.swift
//  hybit
//
//  Created by Mert Gurlek on 13.02.2026.
//

import Foundation

struct PhoneFormatter {
    /// Strict Mask: "XXX XXX XX XX"
    /// Limits input to 10 digits
    static func format(_ phoneNumber: String) -> String {
        // 1. Clean: Remove everything except numbers
        let pureNumber = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // 2. Limit: Max 10 digits
        let constrainedNumber = String(pureNumber.prefix(10))
        
        // 3. Mask: Apply XXX XXX XX XX
        // Pattern logic:
        // Indices: 0-2 (3 chars) -> Space -> 3-5 (3 chars) -> Space -> 6-7 (2 chars) -> Space -> 8-9 (2 chars)
        
        var result = ""
        for (index, char) in constrainedNumber.enumerated() {
            if index == 3 || index == 6 || index == 8 {
                result.append(" ")
            }
            result.append(char)
        }
        
        return result
    }
    
    /// Returns +90XXXXXXXXXX for backend
    static func unformat(_ string: String) -> String {
        let digits = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return "+90\(digits)"
    }
}
