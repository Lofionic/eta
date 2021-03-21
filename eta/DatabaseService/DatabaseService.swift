//
//  Created by Lofionic ©2021
//

import Foundation

import RxSwift

enum DataEvent<T> {
    case added(T)
    case changed(T)
    case removed(T)
    case moved(T)
    case value(T)
}

protocol SessionService {
    func sessionEvents(userIdentifier: UserIdentifier, events: ObservedEvents) -> Observable<DataEvent<Session>>
    func sessionEvents(subscriberIdentifier: UserIdentifier, events: ObservedEvents) -> Observable<DataEvent<Session>>
    func sessionEvents(sessionIdentifier: SessionIdentifier, events: ObservedEvents) -> Observable<DataEvent<Session>>
}

protocol UserService {
    func userEvents(userIdentifier: UserIdentifier, events: ObservedEvents) -> Observable<DataEvent<User>>
    func getUser(_ userIdentifier: UserIdentifier) -> Single<User>
}
