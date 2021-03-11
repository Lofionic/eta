//
//  DatabaseService.swift
//  eta
//
//  Created by Chris Rivers on 10/03/2021.
//

import Foundation

import RxSwift

enum DatabaseEvent<T> {
    case added(T)
    case changed(T)
    case removed(T)
    case moved(T)
}

protocol DatabaseService {
    func sessions(userIdentifier: UserIdentifier) -> Observable<DatabaseEvent<Session>>
}
