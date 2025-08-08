//
//  PersistenceActor.swift
//  intention
//
//  Created by Benjamin Tryon on 7/23/25.
//

import Foundation

// All I/O (encoding/decoding) logic here

protocol Persistence {
    func saveHistory<T: Codable>(_ object: T, to key: String) async throws
    func loadHistory<T: Codable>(_ type: T.Type, from key: String) async throws -> T?
    func clear(_ key: String) async
}

/// Make your actor conform
extension PersistenceActor: Persistence {}

//  All business logic (when to save, what to save) belongs in the VM
actor PersistenceActor {
    // Isolated - no need for .detach elsewhere
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    enum PeristenceActorErrorOverlay: Error {
        case encodingFailed(Error)
        case decodingFaile(Error)
        case noData
    }
    
    // MARK: Encode and Save any Codable object and write it (to UserDefaults)
    func saveHistory<T: Codable>(_ object: T, to key: String) async throws {
        do {
            let data = try encoder.encode(object)   // object is `categories` here
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            debugPrint("[PersistenceActor.saveHistory] failed to encode and save:", error)
            throw PeristenceActorErrorOverlay.encodingFailed(error)
            
        }
    }
    
    // MARK: Load a Codable object from UserDefaults
    func loadHistory<T: Codable>(_ type: T.Type, from key: String) async throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            throw PeristenceActorErrorOverlay.noData
        }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            debugPrint("[PersistenceActor.loadHistory] deocding failed: ", error)
            throw PeristenceActorErrorOverlay.decodingFaile(error)
        }
    }
    
    // MARK: Clear stored value at a key (from UserDefaults)
    func clear(_ key: String) async {
        UserDefaults.standard.removeObject(forKey: key) // keeps in-memory state (like categories), is seralized and background-safe
    }
}
