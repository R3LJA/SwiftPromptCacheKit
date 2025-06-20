import Foundation
import CryptoKit

/// Utility class for hashing prompt strings using SHA256
public struct PromptHasher {
    
    /// Generates a SHA256 hash of the given prompt string
    /// - Parameter prompt: The prompt string to hash
    /// - Returns: A hexadecimal string representation of the SHA256 hash
    public static func hash(prompt: String) -> String {
        let inputData = Data(prompt.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Generates a shorter hash suitable for cache keys (first 16 characters of SHA256)
    /// - Parameter prompt: The prompt string to hash
    /// - Returns: A shortened hexadecimal string (32 chars -> 16 chars)
    public static func shortHash(prompt: String) -> String {
        let fullHash = hash(prompt: prompt)
        return String(fullHash.prefix(16))
    }
} 