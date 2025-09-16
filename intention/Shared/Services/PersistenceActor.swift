//
//  PersistenceActor.swift
//  intention
//
//  Created by Benjamin Tryon on 7/23/25.
//

import Foundation

// All I/O (encoding/decoding) logic here

/// Testing seam
public protocol Persistence: Sendable {
    func write<T: Codable>(_ object: T, to key: String) async throws
    func readIfExists<T: Codable>(_ type: T.Type, from key: String) async throws -> T?
    func clear(_ key: String) async
}

/// All business logic (when to save, what to save) belongs in the VM
/// VM decides when to persist; PersistenceActor decides how (encode/decode, storage)
///     PersistenceActor continues to store the **categories list**
public actor PersistenceActor {
    public enum PersistenceActorError: Error {
        case encodingFailed(Error)
        case decodingFailed(Error)
    }
    
    // Isolated - no need for .detach elsewhere
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {}
}


/// Actor conforms
extension PersistenceActor: Persistence {
    
    // MARK: Generic write; crossing int othis actor requires `await` from outside
    /// Encode and Save any Codable object and write it (to UserDefaults)
    public func write<T: Codable>(_ object: T, to key: String) async throws {
        do {
            let data = try encoder.encode(object)   // object is `categories` here
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            debugPrint("[PersistenceActor.saveHistory] failed to encode and save:", error)
            throw PersistenceActorError.encodingFailed(error)
        }
    }
    
    // MARK: Load a Codable object from UserDefaults
    public func readIfExists<T: Codable>(_ type: T.Type, from key: String) async throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            debugPrint("[PersistenceActor.loadHistory] deocding failed: ", error)
            throw PersistenceActorError.decodingFailed(error)
        }
    }
    
    // MARK: Clear stored value at a key (from UserDefaults)
    public func clear(_ key: String) async {
        UserDefaults.standard.removeObject(forKey: key) // keeps in-memory state (like categories), is seralized and background-safe
    }
}
