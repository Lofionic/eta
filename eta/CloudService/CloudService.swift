//
//  Created by Lofionic ©2021
//

import RxSwift

typealias UserIdentifier = String
typealias SessionIdentifier = String
typealias Username = String

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
    func createSession(userIdentifier: UserIdentifier) -> Single<SessionIdentifier?>
    func registerUser(_ userIdentifier: UserIdentifier, email: Email) -> Completable
}
