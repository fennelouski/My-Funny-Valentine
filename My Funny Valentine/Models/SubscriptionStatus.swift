//
//  SubscriptionStatus.swift
//  My Funny Valentine
//

import Foundation

enum SubscriptionStatus: String, Codable, Sendable {
    case free
    case premium
    case expired
}
