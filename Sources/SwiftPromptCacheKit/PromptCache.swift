import Foundation

/// Main cache class that provides automatic caching for AI prompt-response pairs
public final class PromptCache: @unchecked Sendable {
    
    /// Shared singleton instance
    public static let shared = PromptCache()
    
    private let storage: PromptStorage
    private let hasher = PromptHasher.self
    private let queue = DispatchQueue(label: "SwiftPromptCacheKit.queue", attributes: .concurrent)
    
    /// Initialize with custom storage (primarily for testing)
    internal init(storage: PromptStorage = PromptStorage()) {
        self.storage = storage
    }
    
    /// Fetches a response from cache or executes the API request if not cached
    /// - Parameters:
    ///   - prompt: The prompt string to check in cache
    ///   - apiRequest: Async closure that makes the actual API call
    /// - Returns: The response string, either from cache or fresh API call
    /// - Throws: Any error thrown by the apiRequest closure
    public func fetchOrRequest(
        prompt: String,
        apiRequest: @escaping (String) async throws -> String
    ) async throws -> String {
        
        // Generate hash for the prompt
        let promptHash = hasher.shortHash(prompt: prompt)
        
        // Check if response exists in cache (thread-safe read)
        let cachedResponse = await withCheckedContinuation { continuation in
            queue.async {
                let result = self.storage.retrieve(forPromptHash: promptHash)
                continuation.resume(returning: result)
            }
        }
        
        if let cachedResponse = cachedResponse {
            print("SwiftPromptCacheKit: Cache hit for prompt hash: \(promptHash)")
            return cachedResponse
        }
        
        // Cache miss - execute the API request
        print("SwiftPromptCacheKit: Cache miss for prompt hash: \(promptHash)")
        do {
            let response = try await apiRequest(prompt)
            
            // Store the response in cache (thread-safe write)
            await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    self.storage.store(response: response, forPromptHash: promptHash, originalPrompt: prompt)
                    continuation.resume()
                }
            }
            print("SwiftPromptCacheKit: Cached response for prompt hash: \(promptHash)")
            
            return response
        } catch {
            print("SwiftPromptCacheKit: API request failed: \(error)")
            throw error
        }
    }
    
    /// Manually adds a prompt-response pair to the cache
    /// - Parameters:
    ///   - prompt: The prompt string
    ///   - response: The response to cache
    public func cacheResponse(prompt: String, response: String) {
        let promptHash = hasher.shortHash(prompt: prompt)
        queue.async(flags: .barrier) {
            self.storage.store(response: response, forPromptHash: promptHash, originalPrompt: prompt)
        }
        print("SwiftPromptCacheKit: Manually cached response for prompt hash: \(promptHash)")
    }
    
    /// Checks if a response exists in cache for the given prompt
    /// - Parameter prompt: The prompt string to check
    /// - Returns: True if cached response exists
    public func isCached(prompt: String) -> Bool {
        let promptHash = hasher.shortHash(prompt: prompt)
        return queue.sync {
            return storage.exists(forPromptHash: promptHash)
        }
    }
    
    /// Retrieves a cached response without making an API call
    /// - Parameter prompt: The prompt string
    /// - Returns: The cached response if found, nil otherwise
    public func getCachedResponse(prompt: String) -> String? {
        let promptHash = hasher.shortHash(prompt: prompt)
        return queue.sync {
            return storage.retrieve(forPromptHash: promptHash)
        }
    }
    
    /// Removes a specific prompt from cache
    /// - Parameter prompt: The prompt string to remove
    public func removeCachedResponse(prompt: String) {
        let promptHash = hasher.shortHash(prompt: prompt)
        queue.async(flags: .barrier) {
            self.storage.remove(forPromptHash: promptHash)
        }
        print("SwiftPromptCacheKit: Removed cached response for prompt hash: \(promptHash)")
    }
    
    /// Clears all cached responses
    public func clearCache() {
        queue.async(flags: .barrier) {
            self.storage.clearAll()
        }
        print("SwiftPromptCacheKit: Cleared all cached responses")
    }
    
    /// Returns the number of cached responses
    public func cacheCount() -> Int {
        return queue.sync {
            return storage.count()
        }
    }
} 