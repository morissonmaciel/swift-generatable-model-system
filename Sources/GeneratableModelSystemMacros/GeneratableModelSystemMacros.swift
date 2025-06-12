import Foundation
@_exported import GeneratableModelSystem

/// Macro that marks a property for inclusion in the generatable scheme
@attached(peer)
public macro GeneratableGuide(_ description: String, name: String? = nil) = #externalMacro(module: "GeneratableModelSystemMacrosPlugin", type: "GeneratableGuideMacro")

/// Macro that synthesizes GeneratableProtocol conformance and members
@attached(member, names: named(description), named(scheme), named(CodingKeys))
@attached(extension, conformances: GeneratableProtocol, Codable, names: named(description), named(scheme), named(jsonDescription))
public macro Generatable(_ description: String) = #externalMacro(module: "GeneratableModelSystemMacrosPlugin", type: "GeneratableMacro")