# SwiftPromptCacheKit

A lightweight Swift Package that automatically caches AI prompt → response pairs locally, helping developers avoid redundant API calls and reduce costs when using services like OpenAI, Claude, DeepSeek, or any other AI API.

## Features

- 🚀 **Simple API**: One main function to handle all caching logic
- 🔐 **Secure Hashing**: Uses SHA256 to create cache keys from prompts
- 💾 **Persistent Storage**: Automatically saves to UserDefaults for persistence across app launches
- 🔒 **Thread-Safe**: Built with concurrency in mind using Swift's modern async/await
- 📦 **Zero Dependencies**: No third-party dependencies required
- 🧪 **Well Tested**: Comprehensive unit test coverage
- 🎯 **Platform Support**: Works on iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftPromptCacheKit.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Choose your version requirements

## Usage

### Basic Usage

The main function you'll use is `fetchOrRequest(prompt:apiRequest:)`:

```swift
import SwiftPromptCacheKit

// Example with a hypothetical AI service
let response = try await PromptCache.shared.fetchOrRequest(
    prompt: "Give me 3 business ideas for mobile apps",
    apiRequest: { prompt in
        // Your API call here - this only runs if not cached
        try await myAIService.send(prompt)
    }
)

print(response)
```

### Real-World Example

Here's a more complete example showing how you might integrate it with an actual AI service:

```swift
import SwiftPromptCacheKit

class AIService {
    private let apiKey = "your-api-key"
    
    func generateResponse(for prompt: String) async throws -> String {
        return try await PromptCache.shared.fetchOrRequest(
            prompt: prompt,
            apiRequest: { prompt in
                // This closure only executes if the prompt isn't cached
                return try await self.callOpenAI(prompt: prompt)
            }
        )
    }
    
    private func callOpenAI(prompt: String) async throws -> String {
        // Your actual OpenAI API call implementation
        // This is expensive and will be cached automatically
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return response.choices.first?.message.content ?? ""
    }
}
```

### Cache Management

The package provides several utility functions for cache management:

```swift
// Check if a prompt is cached
if PromptCache.shared.isCached(prompt: "Hello, world!") {
    print("This prompt is already cached!")
}

// Get cached response without making API call
if let cachedResponse = PromptCache.shared.getCachedResponse(prompt: "Hello, world!") {
    print("Cached response: \(cachedResponse)")
}

// Manually add to cache
PromptCache.shared.cacheResponse(
    prompt: "What's the weather?", 
    response: "I don't have access to real-time weather data."
)

// Remove specific cached response
PromptCache.shared.removeCachedResponse(prompt: "Old prompt")

// Clear all cached responses
PromptCache.shared.clearCache()

// Get count of cached items
let count = PromptCache.shared.cacheCount()
print("Cache contains \(count) responses")
```

### Alternative Access

You can also access the cache through the main struct:

```swift
import SwiftPromptCacheKit

let response = try await SwiftPromptCacheKit.cache.fetchOrRequest(
    prompt: "Your prompt here",
    apiRequest: { prompt in
        // Your API call
        return "Response from AI"
    }
)
```

## How It Works

1. **Prompt Hashing**: When you call `fetchOrRequest`, the prompt is hashed using SHA256
2. **Cache Check**: The system checks if a response exists for that hash
3. **Cache Hit**: If found, returns the cached response immediately
4. **Cache Miss**: If not found, executes your `apiRequest` closure
5. **Store Result**: The API response is stored in cache for future use
6. **Return Response**: Returns the fresh response from the API

## Cache Storage

- **Location**: Uses `UserDefaults` for storage
- **Persistence**: Cache persists across app launches
- **Key Format**: Prompt hashes are prefixed with `SwiftPromptCacheKit_`
- **Data Format**: Responses are stored as JSON with metadata (timestamp, original prompt)

## Thread Safety

SwiftPromptCacheKit is fully thread-safe:
- Uses concurrent dispatch queues for read operations
- Uses barrier dispatch queues for write operations
- Implements the `Sendable` protocol for safe concurrent access

## Architecture

The package consists of three main components:

- **`PromptCache`**: Main singleton class providing the public API
- **`PromptHasher`**: Utility for creating SHA256 hashes from prompts
- **`PromptStorage`**: Handles UserDefaults read/write operations

## Testing

Run the test suite:

```bash
swift test
```

The package includes comprehensive unit tests covering:
- Hash generation and consistency
- Cache hit/miss scenarios
- Thread safety
- Error handling
- Storage operations

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.7+
- Xcode 14.0+

## Future Enhancements

Planned features for future versions:
- TTL (Time-To-Live) support for automatic cache expiration
- Memory + disk caching layers
- Configuration options (max cache size, custom storage location)
- Cache statistics and analytics
- Compression for large responses

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any issues or have questions, please file an issue on the GitHub repository. 