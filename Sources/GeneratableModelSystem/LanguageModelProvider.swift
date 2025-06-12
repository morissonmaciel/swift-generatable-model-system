//
//  LanguageModelProvider.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 11/06/25.
//

import Foundation

/// Supported language model provider APIs.
///
/// Currently supports OpenAI-compatible APIs. Additional providers can be added
/// by extending this enum and implementing the corresponding path components.
public enum LanguageModelProviderAPI: String, CaseIterable {
    /// OpenAI API (and OpenAI-compatible endpoints).
    case openAI = "OpenAI"
}

/// Protocol for language model providers that defines how to connect to and authenticate with LLM services.
///
/// Implement this protocol to create custom providers for different language model services.
/// The provider defines the API type, endpoint URL, and authentication credentials.
///
/// ## Example Implementation
/// ```swift
/// class OpenAIProvider: LanguageModelProvider {
///     var api: LanguageModelProviderAPI { .openAI }
///     var address: URL { URL(string: "https://api.openai.com")! }
///     var apiKey: String { "your-openai-api-key" }
/// }
/// ```
///
/// ## Custom Endpoints
/// You can use this with OpenAI-compatible services by changing the address:
/// ```swift
/// class CustomProvider: LanguageModelProvider {
///     var api: LanguageModelProviderAPI { .openAI }
///     var address: URL { URL(string: "https://your-custom-endpoint.com")! }
///     var apiKey: String { "your-api-key" }
/// }
/// ```
public protocol LanguageModelProvider {
    /// The API type used by this provider.
    var api: LanguageModelProviderAPI { get }
    
    /// The base URL for the provider's API endpoint.
    var address: URL { get }
    
    /// The API key or token for authentication.
    var apiKey: String { get }
}

/// API path components for language model providers.
///
/// Defines the URL structure for different provider APIs.
public struct LanguageModelProviderAPIComponents {
    /// The base API path (e.g., "/v1").
    public var api: String
    
    /// The generation endpoint path (e.g., "/completions").
    public var generate: String
}

public extension LanguageModelProviderAPI {
    /// Returns the API path components for this provider.
    ///
    /// Each provider defines its own URL structure for API endpoints.
    /// This computed property returns the appropriate paths for the provider type.
    var pathComponents: LanguageModelProviderAPIComponents{
        switch self {
        case .openAI:
            return .init(api: "/v1", generate: "/completions")
        }
    }
}
