//
//  DatabaseService.swift
//  eta
//
//  Created by Chris Rivers on 10/03/2021.
//

import Foundation

import RxSwift

enum DataEvent<T> {
    case added(T)
    case changed(T)
    case removed(T)
    case moved(T)
}

protocol SessionService {
    func sessions(userIdentifier: UserIdentifier) -> Observable<DataEvent<Session>>
}

protocol UserService {
    func getUser(_ userIdentifier: UserIdentifier) -> Single<User>
}
