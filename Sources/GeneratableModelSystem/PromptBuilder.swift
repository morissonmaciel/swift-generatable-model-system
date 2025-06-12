//
//  PromptBuilder.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 10/06/25.
//

/// A result builder for constructing prompts with a declarative DSL syntax.
///
/// `PromptBuilder` allows you to build complex prompts using Swift's result builder syntax,
/// making it easy to compose prompts with conditionals, loops, and string interpolation.
///
/// ## Basic Usage
///
/// ```swift
/// let session = LanguageModelSession("gpt-4") {
///     "You are a helpful assistant."
///     "Please respond in a professional tone."
/// }
/// ```
///
/// ## Advanced Usage with Conditionals
///
/// ```swift
/// let response = try await session.respond {
///     "Generate a user profile"
///     if includeEmail {
///         "Include an email address"
///     }
///     if includePhone {
///         "Include a phone number"  
///     }
///     "Format the response as JSON"
/// }
/// ```
///
/// ## String Interpolation
///
/// ```swift
/// let story = try await session.generate {
///     "Write a story about \(character)"
///     "Set in \(location)"
///     "With a \(theme) theme"
/// }
/// ```
///
/// The builder automatically joins components with newlines to create a well-formatted prompt.
@resultBuilder
public struct PromptBuilder {
    /// Combines multiple string components into a single prompt.
    ///
    /// - Parameter components: Variable number of string components.
    /// - Returns: A single string with components joined by newlines.
    public static func buildBlock(_ components: String...) -> String {
        components.joined(separator: "\n")
    }
    
    /// Combines an array of string components into a single prompt.
    ///
    /// - Parameter components: Array of string components.
    /// - Returns: A single string with components joined by newlines.
    public static func buildArray(_ components: [String]) -> String {
        components.joined(separator: "\n")
    }
    
    /// Handles optional string components.
    ///
    /// - Parameter component: Optional string component.
    /// - Returns: The component if present, empty string otherwise.
    public static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }
    
    /// Handles the first branch of a conditional.
    ///
    /// - Parameter component: String component from the first branch.
    /// - Returns: The component unchanged.
    public static func buildEither(first component: String) -> String {
        component
    }
    
    /// Handles the second branch of a conditional.
    ///
    /// - Parameter component: String component from the second branch.
    /// - Returns: The component unchanged.
    public static func buildEither(second component: String) -> String {
        component
    }
    
    /// Converts expressions to string components.
    ///
    /// - Parameter expression: A string expression.
    /// - Returns: The expression as a string component.
    public static func buildExpression(_ expression: String) -> String {
        expression
    }
}