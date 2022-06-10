//
//  Created by Lofionic ©2021
//

import Foundation

struct SessionConfiguration: Codable {
    let expiresAfter: TimeInterval
    let privateMode: Bool
}

struct Session: Codable {
    let identifier: SessionIdentifier
    let userIdentifier: UserIdentifier
    let configuration: SessionConfiguration
    
    let subscriberIdentifier: UserIdentifier?
    let status: SessionStatus
    
    let startDate: Date
    let lastUpdated: Date
    
    let eta: ETA?
}

struct ETA: Codable {
    let activity: Int
    let date: Date
	let description: String
	let duration: TimeInterval
}

struct Route: Codable, Equatable {
    let distance: Double
    let realTime: Int
    let time: Int
}
