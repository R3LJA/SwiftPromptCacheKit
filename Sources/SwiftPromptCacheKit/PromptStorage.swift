import Foundation

/// Data structure for cached prompt responses
internal struct CachedResponse: Codable {
    let response: String
    let timestamp: Date
    let prompt: String // Store original prompt for debugging/validation
    
    init(response: String, prompt: String) {
        self.response = response
        self.prompt = prompt
        self.timestamp = Date()
    }
}

/// Handles storage and retrieval of cached prompt responses using UserDefaults
internal class PromptStorage {
    
    private let userDefaults: UserDefaults
    private let keyPrefix = "SwiftPromptCacheKit_"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Stores a prompt-response pair in cache
    /// - Parameters:
    ///   - response: The AI response to cache
    ///   - forPromptHash: The hashed key for the prompt
    ///   - originalPrompt: The original prompt (for debugging/validation)
    func store(response: String, forPromptHash hash: String, originalPrompt: String) {
        let cachedResponse = CachedResponse(response: response, prompt: originalPrompt)
        let key = keyPrefix + hash
        
        do {
            let data = try JSONEncoder().encode(cachedResponse)
            userDefaults.set(data, forKey: key)
        } catch {
            print("SwiftPromptCacheKit: Failed to encode cached response: \(error)")
        }
    }
    
    /// Retrieves a cached response for the given prompt hash
    /// - Parameter promptHash: The hashed key for the prompt
    /// - Returns: The cached response if found and valid, nil otherwise
    func retrieve(forPromptHash hash: String) -> String? {
        let key = keyPrefix + hash
        
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            let cachedResponse = try JSONDecoder().decode(CachedResponse.self, from: data)
            return cachedResponse.response
        } catch {
            print("SwiftPromptCacheKit: Failed to decode cached response: \(error)")
            // Clean up corrupted cache entry
            userDefaults.removeObject(forKey: key)
            return nil
        }
    }
    
    /// Checks if a cached response exists for the given prompt hash
    /// - Parameter promptHash: The hashed key for the prompt
    /// - Returns: True if a valid cached response exists
    func exists(forPromptHash hash: String) -> Bool {
        return retrieve(forPromptHash: hash) != nil
    }
    
    /// Removes a cached response for the given prompt hash
    /// - Parameter promptHash: The hashed key for the prompt
    func remove(forPromptHash hash: String) {
        let key = keyPrefix + hash
        userDefaults.removeObject(forKey: key)
    }
    
    /// Clears all cached responses
    func clearAll() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(keyPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    /// Returns the number of cached responses
    func count() -> Int {
        let keys = userDefaults.dictionaryRepresentation().keys
        return keys.filter { $0.hasPrefix(keyPrefix) }.count
    }
} 