//
//  LanguageModelProvider.swift
//  Llama Tools Mac
//
//  Created by Morisson Marcel on 11/06/25.
//

import Foundation

public enum LanguageModelProviderAPI: String, CaseIterable {
    case openAI = "OpenAI"
}

public protocol LanguageModelProvider {
    var api: LanguageModelProviderAPI { get }
    var address: URL { get }
    var apiKey: String { get }
}

public struct LanguageModelProviderAPIComponents {
    public var api: String
    public var generate: String
}

public extension LanguageModelProviderAPI {
    var pathComponents: LanguageModelProviderAPIComponents{
        switch self {
        case .openAI:
            return .init(api: "/v1", generate: "/completions")
        }
    }
}
