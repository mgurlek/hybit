//
//  UserProfile.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable {
    let uid: String
    let firstName: String
    let lastName: String
    let username: String
    let phoneNumber: String
    let age: Int?
    let nationality: String?
    let profileImageURL: String?
    let createdAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "uid": uid,
            "firstName": firstName,
            "lastName": lastName,
            "username": username,
            "phoneNumber": phoneNumber,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let age { dict["age"] = age }
        if let nationality { dict["nationality"] = nationality }
        if let profileImageURL { dict["profileImageURL"] = profileImageURL }
        
        return dict
    }
}
