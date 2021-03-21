//
//  SnapshotDecodable.swift
//  eta
//
//  Created by Chris Rivers on 15/03/2021.
//

import FirebaseDatabase

protocol SnapshotDecodable: Decodable {
    static func decode(_ snapshot: DataSnapshot, jsonDecoder: JSONDecoder) throws -> Self
    static func decode(_ snapshot: DataSnapshot) throws -> Self
}

extension SnapshotDecodable {
    static func decode(_ snapshot: DataSnapshot) throws -> Self {
        try decode(snapshot, jsonDecoder: JSONDecoder())
    }
}

extension SnapshotDecodable {
    static func decode(_ snapshot: DataSnapshot, jsonDecoder: JSONDecoder) throws -> Self {
        guard let dictionary = snapshot.value as? [String: AnyObject] else {
            throw FirebaseDatabaseServiceError.decodingError
        }
        let identifierDictionary = dictionary.merging(["identifier": snapshot.key as AnyObject]) { (current, _) in current }
        let json = try JSONSerialization.data(withJSONObject: identifierDictionary, options: [])
        return try jsonDecoder.decode(Self.self, from: json)
    }
}

extension User: SnapshotDecodable {}
extension Session: SnapshotDecodable {}
