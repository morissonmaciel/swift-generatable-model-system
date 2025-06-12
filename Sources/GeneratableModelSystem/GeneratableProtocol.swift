//
//  GeneratableProtocol.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 10/06/25.
//

import Foundation
import SwiftUI

/// Protocol for types that can generate structured JSON schemas for language model communication.
///
/// Types conforming to `GeneratableProtocol` can automatically generate JSON Schema descriptions
/// that guide language models to produce properly structured responses. This is typically implemented
/// using the `@Generatable` macro.
///
/// ## Automatic Implementation with @Generatable
///
/// The recommended way to implement this protocol is using the `@Generatable` macro:
///
/// ```swift
/// @Generatable("User profile information")
/// struct UserProfile {
///     @GeneratableGuide("Full name of the user")
///     var name: String
///     
///     @GeneratableGuide("Email address")
///     var email: String
/// }
/// ```
///
/// ## Manual Implementation
///
/// You can also implement this protocol manually:
///
/// ```swift
/// struct CustomModel: GeneratableProtocol {
///     static var description: String {
///         "Custom model description"
///     }
///     
///     static var scheme: [String: GuideDescriptor] {
///         [
///             "name": GuideDescriptor(type: "String", description: "Name field"),
///             "value": GuideDescriptor(type: "Int", description: "Value field")
///         ]
///     }
/// }
/// ```
public protocol GeneratableProtocol: Codable, Sendable {
    /// A human-readable description of what this type represents.
    static var description: String { get }
    
    /// A dictionary mapping property names to their schema descriptors.
    /// Used to generate JSON Schema for language model guidance.
    static var scheme: [String: GuideDescriptor] { get }
}

public extension GeneratableProtocol {
    /// Returns a formatted JSON string representation of the type's schema.
    ///
    /// This method converts the `scheme` dictionary to a pretty-printed JSON string
    /// that can be used in prompts to guide language model responses.
    ///
    /// ## Example Output
    /// ```json
    /// {
    ///   "name": {
    ///     "description": "Full name of the user",
    ///     "type": "String"
    ///   },
    ///   "email": {
    ///     "description": "Email address", 
    ///     "type": "String"
    ///   }
    /// }
    /// ```
    static var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let json = try? encoder.encode(scheme)
        let string = String(data: json ?? Data(), encoding: String.Encoding.utf8) ?? ""
        return string
    }
}
