import XCTest
@testable import SwiftPromptCacheKit

final class SwiftPromptCacheKitTests: XCTestCase {
    
    var cache: PromptCache!
    var mockStorage: PromptStorage!
    
    override func setUp() {
        super.setUp()
        // Use a separate UserDefaults suite for testing
        let testDefaults = UserDefaults(suiteName: "SwiftPromptCacheKitTests")!
        mockStorage = PromptStorage(userDefaults: testDefaults)
        cache = PromptCache(storage: mockStorage)
        
        // Clear any existing test data
        cache.clearCache()
    }
    
    override func tearDown() {
        cache.clearCache()
        cache = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - PromptHasher Tests
    
    func testPromptHasher_GeneratesConsistentHash() {
        let prompt = "Test prompt"
        let hash1 = PromptHasher.hash(prompt: prompt)
        let hash2 = PromptHasher.hash(prompt: prompt)
        
        XCTAssertEqual(hash1, hash2, "Hash should be consistent for the same prompt")
        XCTAssertEqual(hash1.count, 64, "SHA256 hash should be 64 characters long")
    }
    
    func testPromptHasher_GeneratesDifferentHashesForDifferentPrompts() {
        let hash1 = PromptHasher.hash(prompt: "Prompt 1")
        let hash2 = PromptHasher.hash(prompt: "Prompt 2")
        
        XCTAssertNotEqual(hash1, hash2, "Different prompts should generate different hashes")
    }
    
    func testPromptHasher_ShortHashIsCorrectLength() {
        let prompt = "Test prompt"
        let shortHash = PromptHasher.shortHash(prompt: prompt)
        
        XCTAssertEqual(shortHash.count, 16, "Short hash should be 16 characters long")
    }
    
    // MARK: - PromptStorage Tests
    
    func testPromptStorage_StoreAndRetrieve() {
        let prompt = "Test prompt"
        let response = "Test response"
        let hash = PromptHasher.shortHash(prompt: prompt)
        
        mockStorage.store(response: response, forPromptHash: hash, originalPrompt: prompt)
        let retrievedResponse = mockStorage.retrieve(forPromptHash: hash)
        
        XCTAssertEqual(retrievedResponse, response, "Retrieved response should match stored response")
    }
    
    func testPromptStorage_ExistsCheck() {
        let prompt = "Test prompt"
        let response = "Test response"
        let hash = PromptHasher.shortHash(prompt: prompt)
        
        XCTAssertFalse(mockStorage.exists(forPromptHash: hash), "Should not exist before storing")
        
        mockStorage.store(response: response, forPromptHash: hash, originalPrompt: prompt)
        
        XCTAssertTrue(mockStorage.exists(forPromptHash: hash), "Should exist after storing")
    }
    
    func testPromptStorage_Remove() {
        let prompt = "Test prompt"
        let response = "Test response"
        let hash = PromptHasher.shortHash(prompt: prompt)
        
        mockStorage.store(response: response, forPromptHash: hash, originalPrompt: prompt)
        XCTAssertTrue(mockStorage.exists(forPromptHash: hash))
        
        mockStorage.remove(forPromptHash: hash)
        XCTAssertFalse(mockStorage.exists(forPromptHash: hash))
    }
    
    func testPromptStorage_ClearAll() {
        let prompt1 = "Test prompt 1"
        let prompt2 = "Test prompt 2"
        let response = "Test response"
        
        mockStorage.store(response: response, forPromptHash: PromptHasher.shortHash(prompt: prompt1), originalPrompt: prompt1)
        mockStorage.store(response: response, forPromptHash: PromptHasher.shortHash(prompt: prompt2), originalPrompt: prompt2)
        
        XCTAssertEqual(mockStorage.count(), 2)
        
        mockStorage.clearAll()
        
        XCTAssertEqual(mockStorage.count(), 0)
    }
    
    // MARK: - PromptCache Tests
    
    func testPromptCache_FetchOrRequest_CacheMiss() async throws {
        let prompt = "Test prompt"
        let expectedResponse = "Test response"
        var apiCallCount = 0
        
        let apiRequest: (String) async throws -> String = { _ in
            apiCallCount += 1
            return expectedResponse
        }
        
        let response = try await cache.fetchOrRequest(prompt: prompt, apiRequest: apiRequest)
        
        XCTAssertEqual(response, expectedResponse)
        XCTAssertEqual(apiCallCount, 1, "API should be called once on cache miss")
        XCTAssertTrue(cache.isCached(prompt: prompt), "Response should be cached after API call")
    }
    
    func testPromptCache_FetchOrRequest_CacheHit() async throws {
        let prompt = "Test prompt"
        let expectedResponse = "Test response"
        var apiCallCount = 0
        
        let apiRequest: (String) async throws -> String = { _ in
            apiCallCount += 1
            return expectedResponse
        }
        
        // First call - cache miss
        let response1 = try await cache.fetchOrRequest(prompt: prompt, apiRequest: apiRequest)
        XCTAssertEqual(response1, expectedResponse)
        XCTAssertEqual(apiCallCount, 1)
        
        // Second call - cache hit
        let response2 = try await cache.fetchOrRequest(prompt: prompt, apiRequest: apiRequest)
        XCTAssertEqual(response2, expectedResponse)
        XCTAssertEqual(apiCallCount, 1, "API should not be called again on cache hit")
    }
    
    func testPromptCache_FetchOrRequest_APIError() async {
        let prompt = "Test prompt"
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: nil)
        
        let apiRequest: (String) async throws -> String = { _ in
            throw expectedError
        }
        
        do {
            _ = try await cache.fetchOrRequest(prompt: prompt, apiRequest: apiRequest)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).code, expectedError.code)
        }
        
        XCTAssertFalse(cache.isCached(prompt: prompt), "Failed response should not be cached")
    }
    
    func testPromptCache_ManualCaching() {
        let prompt = "Test prompt"
        let response = "Test response"
        
        XCTAssertFalse(cache.isCached(prompt: prompt))
        
        cache.cacheResponse(prompt: prompt, response: response)
        
        XCTAssertTrue(cache.isCached(prompt: prompt))
        XCTAssertEqual(cache.getCachedResponse(prompt: prompt), response)
    }
    
    func testPromptCache_GetCachedResponse() {
        let prompt = "Test prompt"
        let response = "Test response"
        
        XCTAssertNil(cache.getCachedResponse(prompt: prompt))
        
        cache.cacheResponse(prompt: prompt, response: response)
        
        XCTAssertEqual(cache.getCachedResponse(prompt: prompt), response)
    }
    
    func testPromptCache_RemoveCachedResponse() {
        let prompt = "Test prompt"
        let response = "Test response"
        
        cache.cacheResponse(prompt: prompt, response: response)
        XCTAssertTrue(cache.isCached(prompt: prompt))
        
        cache.removeCachedResponse(prompt: prompt)
        XCTAssertFalse(cache.isCached(prompt: prompt))
    }
    
    func testPromptCache_ClearCache() {
        let prompt1 = "Test prompt 1"
        let prompt2 = "Test prompt 2"
        let response = "Test response"
        
        cache.cacheResponse(prompt: prompt1, response: response)
        cache.cacheResponse(prompt: prompt2, response: response)
        
        XCTAssertEqual(cache.cacheCount(), 2)
        
        cache.clearCache()
        
        XCTAssertEqual(cache.cacheCount(), 0)
        XCTAssertFalse(cache.isCached(prompt: prompt1))
        XCTAssertFalse(cache.isCached(prompt: prompt2))
    }
    
    func testPromptCache_CacheCount() {
        XCTAssertEqual(cache.cacheCount(), 0)
        
        cache.cacheResponse(prompt: "Prompt 1", response: "Response 1")
        XCTAssertEqual(cache.cacheCount(), 1)
        
        cache.cacheResponse(prompt: "Prompt 2", response: "Response 2")
        XCTAssertEqual(cache.cacheCount(), 2)
        
        cache.removeCachedResponse(prompt: "Prompt 1")
        XCTAssertEqual(cache.cacheCount(), 1)
    }
    
    // MARK: - SwiftPromptCacheKit Tests
    
    func testSwiftPromptCacheKit_Version() {
        XCTAssertEqual(SwiftPromptCacheKit.version, "1.0.0")
    }
    
    func testSwiftPromptCacheKit_CacheAccess() {
        let cache1 = SwiftPromptCacheKit.cache
        let cache2 = SwiftPromptCacheKit.cache
        
        XCTAssertTrue(cache1 === cache2, "Should return the same singleton instance")
        XCTAssertTrue(cache1 === PromptCache.shared, "Should be the same as PromptCache.shared")
    }
}
