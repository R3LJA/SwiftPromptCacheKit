// The Swift Programming Language
// https://docs.swift.org/swift-book

// SwiftPromptCacheKit
// A lightweight Swift Package for caching AI prompt-response pairs locally

import Foundation

// Re-export the main public API
@_exported import struct Foundation.Data
@_exported import struct Foundation.Date

/// SwiftPromptCacheKit provides automatic caching for AI prompt-response pairs
/// to reduce redundant API calls and costs when using services like OpenAI, Claude, or DeepSeek.
///
/// ## Usage
/// ```swift
/// let response = try await PromptCache.shared.fetchOrRequest(
///   prompt: "Give me 3 business ideas for mobile apps",
///   apiRequest: { prompt in
///     try await myAIService.send(prompt)
///   }
/// )
/// print(response)
/// ```
///
/// The package automatically:
/// - Checks if the prompt exists in local cache
/// - Returns cached response immediately if found
/// - Executes your API request if not cached
/// - Stores the new response in cache for future use
public struct SwiftPromptCacheKit {
    
    /// Current version of the SwiftPromptCacheKit
    public static let version = "1.0.0"
    
    /// Access to the main cache functionality
    public static var cache: PromptCache {
        return PromptCache.shared
    }
}
