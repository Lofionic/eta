//
//  Created by Lofionic ©2021
//

import RxSwift

typealias SessionIdentifier = String
typealias Username = String

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct Location: Codable {
    let coordinates: Coordinates
    let date: Date
}

enum SessionStatus: Int, Codable {
    case unauthorized
    case authorized
}

protocol CloudService {
    var authenticationService: AuthorizationService? { get set }
    
    func authorize() -> Completable
    func registerUser(_ userIdentifier: UserIdentifier, email: Email) -> Single<UserIdentifier?>
    
    func createSession(userIdentifier: UserIdentifier) -> Single<SessionIdentifier>
    func removeSession(sessionIdentifier: SessionIdentifier) -> Completable
    
    func joinSession(sessionIdentifier: SessionIdentifier) -> Completable
    func authorizeSession(sessionIdentifier: SessionIdentifier) -> Completable
    
    func postLocation(userIdentifier: UserIdentifier, sessionIdentifier: SessionIdentifier, location: Location) -> Completable
}
