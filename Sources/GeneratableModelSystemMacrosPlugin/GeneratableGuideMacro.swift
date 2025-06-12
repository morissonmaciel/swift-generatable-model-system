//
//  GeneratableGuideMacro.swift
//  GeneratableModelSystemMacrosPlugin
//
//  Created by Morisson Marcel on 12/06/25.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct GeneratableGuideMacro: PeerMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro is purely for marking properties
        // The actual processing happens in GeneratableMacro
        return []
    }
}