//
//  LanguageModelProviderAPI.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 11/06/25.
//


import Foundation

/// Protocol for language model provider responses.
///
/// Different providers return responses in different formats. This protocol standardizes
/// access to the response content regardless of the underlying provider structure.
protocol LanguageModelProviderResponse: Codable {
    /// The text content from the language model response.
    var contents: String { get }
}

/// OpenAI-compatible provider response structure.
///
/// Handles responses from OpenAI API and OpenAI-compatible endpoints.
/// The response typically contains choices with generated text content.
struct CompatibleOpenAIProviderResponse: LanguageModelProviderResponse {
    /// Individual choice in the response.
    struct Choice: Codable {
        /// The index of this choice in the response.
        let index: Int
        /// The generated text content.
        let text: String
    }
    
    /// Token usage information from the API.
    struct Usage: Codable {
        /// Number of tokens in the prompt.
        let promptTokens: Int
        /// Number of tokens in the completion.
        let completionTokens: Int
        /// Total number of tokens used.
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    /// The model used for generation.
    let model: String
    /// Unix timestamp of when the response was created.
    let created: Int
    /// Token usage statistics.
    let usage: Usage
    /// Array of generated choices.
    let choices: [Choice]
    
    /// Returns the text content from the first choice, or empty string if no choices.
    var contents: String {
        choices.first?.text ?? ""
    }
}

extension LanguageModelProviderAPI {
    /// Returns the appropriate response type for this provider API.
    ///
    /// Each provider API has a different response structure. This computed property
    /// returns the correct response type to use for parsing responses from this provider.
    var providerResponseType: any LanguageModelProviderResponse.Type {
        switch self {
        case .openAI:
            return CompatibleOpenAIProviderResponse.self
        }
    }
    
    /// Preprocesses a streaming response line for this provider.
    ///
    /// Different providers use different streaming formats (SSE, raw JSON, etc.).
    /// This method handles provider-specific preprocessing before JSON parsing.
    ///
    /// - Parameter line: Raw line from the streaming response
    /// - Returns: Preprocessed JSON string ready for parsing, or nil if line should be skipped
    func preprocessStreamingLine(_ line: String) -> String? {
        switch self {
        case .openAI:
            // Handle Server-Sent Events (SSE) format: "data: {JSON}"
            if line.hasPrefix("data: ") {
                let jsonPart = String(line.dropFirst(6))
                // Skip SSE control messages
                return jsonPart == "[DONE]" ? nil : jsonPart
            }
            // Skip empty lines or non-data SSE lines
            return line.isEmpty ? nil : line
        }
    }
}
