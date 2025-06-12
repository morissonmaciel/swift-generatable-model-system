//
//  LanguageModel.swift
//  Llama Tools Mac
//
//  Created by Morisson Marcel on 11/06/25.
//

import Foundation

public enum LanguageModelCapabilities: String, CaseIterable {
    case `default`
    case tools
    case reasoning
    case vision
}

public struct LanguageModel: Identifiable {
    public var id: String {
        name
    }
    
    public let name: String
    public let capabilities: [LanguageModelCapabilities] = [.default]
    
    public init(name: String) {
        self.name = name
    }
}
