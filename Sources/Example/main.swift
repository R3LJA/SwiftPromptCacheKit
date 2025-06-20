import Foundation
import SwiftPromptCacheKit

// Mock AI Service for demonstration
final class MockAIService: @unchecked Sendable {
    private let callCountQueue = DispatchQueue(label: "callCount")
    private var _callCount = 0
    
    private var callCount: Int {
        get {
            callCountQueue.sync { _callCount }
        }
        set {
            callCountQueue.sync { _callCount = newValue }
        }
    }
    
    func generateResponse(prompt: String) async throws -> String {
        let currentCall = callCount + 1
        callCount = currentCall
        
        print("🌐 API Call #\(currentCall) - Processing prompt: \"\(prompt)\"")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock responses based on prompt content
        switch prompt.lowercased() {
        case let p where p.contains("weather"):
            return "I don't have access to real-time weather data, but you can check a weather app for current conditions."
        case let p where p.contains("business ideas"):
            return "Here are 3 business ideas: 1) AI-powered meal planning app, 2) Virtual interior design service, 3) Sustainable packaging marketplace."
        case let p where p.contains("hello"):
            return "Hello! How can I assist you today?"
        default:
            return "I understand your question about '\(prompt)'. Here's a helpful response tailored to your query."
        }
    }
}

// Example usage
@main
struct SwiftPromptCacheKitExample {
    @MainActor
    static func main() async {
        print("🚀 SwiftPromptCacheKit Demo\n")
        
        let aiService = MockAIService()
        
        // Clear cache to start fresh
        PromptCache.shared.clearCache()
        print("📝 Cache cleared - starting with \(PromptCache.shared.cacheCount()) cached items\n")
        
        // Test prompts
        let testPrompts = [
            "Hello, how are you?",
            "Give me 3 business ideas for mobile apps",
            "What's the weather like today?",
            "Hello, how are you?" // Repeat to test cache hit
        ]
        
        print("Testing cache functionality with \(testPrompts.count) prompts...\n")
        
        for (index, prompt) in testPrompts.enumerated() {
            print("--- Test \(index + 1) ---")
            
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                let response = try await PromptCache.shared.fetchOrRequest(
                    prompt: prompt,
                    apiRequest: { prompt in
                        return try await aiService.generateResponse(prompt: prompt)
                    }
                )
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                print("💬 Response: \(response)")
                print("⏱️  Time taken: \(String(format: "%.3f", timeElapsed)) seconds")
                print("💾 Cache size: \(PromptCache.shared.cacheCount()) items")
                
                if PromptCache.shared.isCached(prompt: prompt) {
                    print("✅ Prompt is now cached")
                }
                
            } catch {
                print("❌ Error: \(error)")
            }
            
            print() // Empty line for readability
        }
        
        // Demonstrate cache management
        print("--- Cache Management Demo ---")
        
        // Check what's cached
        print("📊 Final cache statistics:")
        print("   Total cached items: \(PromptCache.shared.cacheCount())")
        
        // Test manual caching
        PromptCache.shared.cacheResponse(
            prompt: "What is Swift?",
            response: "Swift is a powerful programming language developed by Apple."
        )
        print("   After manual cache: \(PromptCache.shared.cacheCount()) items")
        
        // Test cache retrieval without API call
        if let cachedResponse = PromptCache.shared.getCachedResponse(prompt: "What is Swift?") {
            print("🔍 Retrieved from cache: \"\(cachedResponse)\"")
        }
        
        // Remove specific item
        PromptCache.shared.removeCachedResponse(prompt: "What is Swift?")
        print("   After removal: \(PromptCache.shared.cacheCount()) items")
        
        print("\n🎉 Demo completed! SwiftPromptCacheKit is working perfectly.")
        print("💡 In a real app, the expensive API calls would be cached automatically,")
        print("   saving you time and money on subsequent requests.")
    }
} 