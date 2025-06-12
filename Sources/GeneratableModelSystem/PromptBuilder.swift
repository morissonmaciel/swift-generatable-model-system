//
//  PromptBuilder.swift
//  Llama Tools Mac
//
//  Created by Morisson Marcel on 10/06/25.
//

@resultBuilder
public struct PromptBuilder {
    public static func buildBlock(_ components: String...) -> String {
        components.joined(separator: "\n")
    }
    
    public static func buildArray(_ components: [String]) -> String {
        components.joined(separator: "\n")
    }
    
    public static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }
    
    public static func buildEither(first component: String) -> String {
        component
    }
    
    public static func buildEither(second component: String) -> String {
        component
    }
    
    public static func buildExpression(_ expression: String) -> String {
        expression
    }
}