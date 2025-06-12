//
//  GuideDescriptor.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 10/06/25.
//

import Foundation

/// Describes the schema for a property in a generatable type.
///
/// `GuideDescriptor` provides detailed information about a property's type, description,
/// and constraints to help language models generate properly structured responses.
/// This is typically created automatically by the `@GeneratableGuide` macro.
///
/// ## Automatic Creation with @GeneratableGuide
///
/// ```swift
/// @Generatable("User profile")
/// struct UserProfile {
///     @GeneratableGuide("Full name of the user")
///     var name: String
///     
///     @GeneratableGuide("Account status")
///     var isActive: Bool
///     
///     @GeneratableGuide("User role")
///     var role: UserRole?  // Optional property
/// }
/// ```
///
/// ## Manual Creation
///
/// ```swift
/// let descriptor = GuideDescriptor(
///     type: "String",
///     description: "User's full name",
///     isOptional: false,
///     validValues: nil
/// )
/// ```
///
/// ## Enum Validation
///
/// For enum properties, valid values are automatically extracted:
///
/// ```swift
/// enum Status: String, CaseIterable {
///     case active = "Active"
///     case inactive = "Inactive"
/// }
/// 
/// // Creates descriptor with validValues: ["Active", "Inactive"]
/// ```
public struct GuideDescriptor: Codable {
    /// The type name of the property (e.g., "String", "Int", "Bool").
    public var type: String
    
    /// Human-readable description explaining the purpose of this property.
    public var description: String
    
    /// Whether this property is optional in the generated JSON.
    public var isOptional: Bool = false
    
    /// Valid values for enum properties. `nil` for non-enum types.
    public var validValues: [String]? = nil
    
    /// Creates a new guide descriptor.
    ///
    /// - Parameters:
    ///   - type: The Swift type name for this property.
    ///   - description: Human-readable description of the property's purpose.
    ///   - isOptional: Whether the property is optional (defaults to `false`).
    ///   - validValues: Array of valid values for enum types (defaults to `nil`).
    public init(type: String, description: String, isOptional: Bool = false, validValues: [String]? = nil) {
        self.type = type
        self.description = description
        self.isOptional = isOptional
        self.validValues = validValues
    }
}
