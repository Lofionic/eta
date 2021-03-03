//
//  Created by Lofionic ©2021
//

import RxSwift

typealias UserIdentifier = String
typealias SessionIdentifier = String

struct LocationUpdate {
    struct Location {
        let latitude: Double
        let longitude: Double
    }
    
    let userIdentifier: UserIdentifier
    let sessionIdentifier: SessionIdentifier
    let location: Location
    let date: String
}

protocol CloudService {
    func startSession(
        userIdentifier: UserIdentifier,
        friendIdentifier: UserIdentifier,
        expiresAfter: Double) -> Completable
    func postLocationUpdate(userIdentifier: UserIdentifier, sessionIdentifier: SessionIdentifier, locationUpdate: LocationUpdate) -> Completable
}
