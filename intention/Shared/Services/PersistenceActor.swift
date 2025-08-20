//
//  PersistenceActor.swift
//  intention
//
//  Created by Benjamin Tryon on 7/23/25.
//

import Foundation

// All I/O (encoding/decoding) logic here

//protocol Persistence {
//    func write<T: Codable>(_ object: T, to key: String) async throws
//    func read<T: Codable>(_ type: T.Type, from key: String) async throws -> T?
//    func clear(_ key: String) async
//}

/// Make your actor conform
//extension PersistenceActor: Persistence {}

//  All business logic (when to save, what to save) belongs in the VM
actor PersistenceActor {
    enum PersistenceActorError: Error {
        case encodingFailed(Error)
        case decodingFailed(Error)
        case noData
    }
    
    // Isolated - no need for .detach elsewhere
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    
    // MARK: Generic write; crossing int othis actor requires `await` from outside
    /// Encode and Save any Codable object and write it (to UserDefaults)
    func write<T: Codable>(_ object: T, to key: String) throws {
        do {
            let data = try encoder.encode(object)   // object is `categories` here
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            debugPrint("[PersistenceActor.saveHistory] failed to encode and save:", error)
            throw PersistenceActorError.encodingFailed(error)
        }
    }
    
    // MARK: Load a Codable object from UserDefaults
    func readIfExists<T: Codable>(_ type: T.Type, from key: String) throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            debugPrint("[PersistenceActor.loadHistory] deocding failed: ", error)
            throw PersistenceActorError.decodingFailed(error)
        }
    }
    
    // MARK: Clear stored value at a key (from UserDefaults)
    func clear(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key) // keeps in-memory state (like categories), is seralized and background-safe
    }
}
