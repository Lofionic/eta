//
//  Session.swift
//  eta
//
//  Created by Chris Rivers on 10/03/2021.
//

import Foundation

struct Session: Codable {
    let identifier: SessionIdentifier
    let userIdentifier: UserIdentifier
    let friendIdentifier: UserIdentifier
    let status: Int
    
    let startDate: TimeInterval
    let lastUpdated: TimeInterval
    let expiresAfter: TimeInterval
    
    let eta: ETA?
}

struct ETA: Codable {
    let activity: Int
    let date: Double
    
    let from: Location
    let to: Location
    
    let route: Route
}

struct Route: Codable {
    let distance: Double
    let realTime: Int
    let time: Int
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}
