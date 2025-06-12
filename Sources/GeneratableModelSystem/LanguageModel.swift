//
//  LanguageModel.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 11/06/25.
//

import Foundation

/// Capabilities that a language model may support.
///
/// Different language models support different features. This enum allows
/// you to specify what capabilities a model has for potential future use.
public enum LanguageModelCapabilities: String, CaseIterable {
    /// Basic text generation capabilities.
    case `default`
    /// Function/tool calling capabilities.
    case tools
    /// Advanced reasoning capabilities.
    case reasoning
    /// Vision/image processing capabilities.
    case vision
}

/// Represents a language model with its name and capabilities.
///
/// This is a simple wrapper around a model name that can be extended
/// to include capability information and other metadata about the model.
///
/// ## Example
/// ```swift
/// let model = LanguageModel(name: "gpt-4")
/// let session = LanguageModelSession(model: model) {
///     "You are a helpful assistant."
/// }
/// ```
public struct LanguageModel: Identifiable {
    /// Unique identifier for the model (uses the model name).
    public var id: String {
        name
    }
    
    /// The name/identifier of the language model (e.g., "gpt-4", "claude-3").
    public let name: String
    
    /// Capabilities supported by this model. Currently defaults to basic capabilities.
    public let capabilities: [LanguageModelCapabilities] = [.default]
    
    /// Creates a new language model with the specified name.
    ///
    /// - Parameter name: The name or identifier of the language model.
    public init(name: String) {
        self.name = name
    }
}
