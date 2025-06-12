import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct GeneratableModelSystemMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GeneratableMacro.self,
        GeneratableGuideMacro.self
    ]
}