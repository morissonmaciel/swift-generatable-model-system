//
//  LanguageModelProviderAPI.swift
//  Llama Tools Mac
//
//  Created by Morisson Marcel on 11/06/25.
//


import Foundation

protocol LanguageModelProviderResponse: Codable {
    var contents: String { get }
}

struct CompatibleOpenAIProviderResponse: LanguageModelProviderResponse {
    struct Choice: Codable {
        let index: Int
        let text: String
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    let model: String
    let created: Date
    let usage: Usage
    let choices: [Choice]
    
    var contents: String {
        choices.first?.text ?? ""
    }
}

extension LanguageModelProviderAPI {
    var providerResponseType: any LanguageModelProviderResponse.Type {
        switch self {
        case .openAI:
            return CompatibleOpenAIProviderResponse.self
        }
    }
}
