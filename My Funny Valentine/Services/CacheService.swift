//
//  CacheService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation

class CacheService {
    static let shared = CacheService()
    
    private var sayingsCache: [String: CachedSayings] = [:]
    private let maxCacheSize = 100 // Maximum number of cached entries
    
    private init() {}
    
    // MARK: - Sayings Cache
    
    func getCachedSayings(for inspiration: String) -> [String]? {
        let key = hashInspiration(inspiration)
        return sayingsCache[key]?.sayings
    }
    
    func cacheSayings(_ sayings: [String], for inspiration: String) {
        let key = hashInspiration(inspiration)
        
        // Remove oldest entries if cache is full
        if sayingsCache.count >= maxCacheSize {
            let sortedEntries = sayingsCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let entriesToRemove = sortedEntries.prefix(sayingsCache.count - maxCacheSize + 1)
            for (key, _) in entriesToRemove {
                sayingsCache.removeValue(forKey: key)
            }
        }
        
        sayingsCache[key] = CachedSayings(sayings: sayings, timestamp: Date())
    }
    
    func isCached(_ inspiration: String) -> Bool {
        let key = hashInspiration(inspiration)
        return sayingsCache[key] != nil
    }
    
    func clearCache() {
        sayingsCache.removeAll()
    }
    
    // MARK: - Private Helpers
    
    private func hashInspiration(_ inspiration: String) -> String {
        let normalized = inspiration.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.sha256()
    }
}

struct CachedSayings {
    let sayings: [String]
    let timestamp: Date
}

// MARK: - String Extension for Hashing

import CryptoKit

extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
