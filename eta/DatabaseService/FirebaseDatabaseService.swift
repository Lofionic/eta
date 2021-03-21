//
//  Created by Lofionic ©2021
//

import FirebaseDatabase

import RxSwift

enum FirebaseDatabaseServiceError: Error {
    case decodingError
    case sessionExistsForUser
    case sessionFull
    case error(underlyingError: Error)
    case errorValidating(underlyingError: Error)
    case unknown
}

struct ObservedEvents: OptionSet {
    let rawValue: Int
    
    static let add = ObservedEvents(rawValue: 1 << 0)
    static let remove = ObservedEvents(rawValue: 1 << 1)
    static let change = ObservedEvents(rawValue: 1 << 2)
    static let move = ObservedEvents(rawValue: 1 << 3)
    static let value = ObservedEvents(rawValue: 1 << 4)
}

final class FirebaseDatabaseService {
    struct Keys {
        static let sessions = "sessions"
        struct Session {
            static let userIdentifier = "userIdentifier"
            static let subscriberIdentifier = "subscriberIdentifier"
            static let status = "status"
        }
        static let users = "users"
        struct User {
            static let email = "email"
        }
    }
    
    let database: DatabaseReference
    
    init(database: DatabaseReference = Database.database().reference()) {
        self.database = database
    }
}

// MARK: - Generic utility functions
extension FirebaseDatabaseService {
    func getData<T: SnapshotDecodable>(query: DatabaseQuery, completion: @escaping (Result<T, Error>) -> Void) {
        query.getData(completion: { (error, snapshot) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let result = try? T.decode(snapshot) {
                    completion(.success(result))
                } else {
                    completion(.failure(FirebaseDatabaseServiceError.decodingError))
                }
            }
        })
    }
    
    func observeEvents<T: SnapshotDecodable>(
        query: DatabaseQuery,
        events: ObservedEvents,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        onEvent: @escaping (DataEvent<T>) -> Void,
        onError: @escaping (Error) -> Void) -> [DatabaseHandle]
    {
        var handles = [DatabaseHandle]()
        
        if events.contains(.add) {
            handles.append(query.observe(.childAdded) { snapshot in
                do {
                    let element = try T.decode(snapshot, jsonDecoder: jsonDecoder)
                    onEvent(.added(element))
                } catch {
                    onError(error)
                }
            })
        }
        
        if events.contains(.remove) {
            handles.append(query.observe(.childRemoved) { snapshot in
                do {
                    let element = try T.decode(snapshot, jsonDecoder: jsonDecoder)
                    onEvent(.removed(element))
                } catch {
                    onError(error)
                }
            })
        }
        
        if events.contains(.change) {
            handles.append(query.observe(.childChanged) { snapshot in
                do {
                    let element = try T.decode(snapshot, jsonDecoder: jsonDecoder)
                    onEvent(.changed(element))
                } catch {
                    onError(error)
                }
            })
        }
        
        if events.contains(.move) {
            handles.append(query.observe(.childMoved) { snapshot in
                do {
                    let element = try T.decode(snapshot, jsonDecoder: jsonDecoder)
                    onEvent(.moved(element))
                } catch {
                    onError(error)
                }
            })
        }
        
        if events.contains(.value) {
            handles.append(query.observe(.value) { snapshot in
                do {
                    let element = try T.decode(snapshot, jsonDecoder: jsonDecoder)
                    onEvent(.value(element))
                } catch {
                    onError(error)
                }
            })
        }
        
        return handles
    }
}

extension Array: SnapshotDecodable where Element: SnapshotDecodable {}
