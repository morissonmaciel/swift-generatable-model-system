//
//  LanguageModelTests.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import Testing
import GeneratableModelSystem

@Test("LanguageModel basic creation")
func testLanguageModelCreation() {
    let model = LanguageModel(name: "gemma3:4b")
    
    #expect(model.id == "gemma3:4b")
    #expect(model.name == "gemma3:4b")
    #expect(model.capabilities == [.default])
}

@Test("LanguageModel id matches name")
func testLanguageModelIdMatchesName() {
    let model1 = LanguageModel(name: "llama3:8b")
    let model2 = LanguageModel(name: "codellama:13b")
    
    #expect(model1.id == model1.name)
    #expect(model2.id == model2.name)
    #expect(model1.id != model2.id)
}

@Test("LanguageModelCapabilities enum cases")
func testLanguageModelCapabilities() {
    let allCases = LanguageModelCapabilities.allCases
    
    #expect(allCases.contains(.default))
    #expect(allCases.contains(.tools))
    #expect(allCases.contains(.reasoning))
    #expect(allCases.contains(.vision))
    #expect(allCases.count == 4)
}

@Test("LanguageModelCapabilities raw values")
func testLanguageModelCapabilitiesRawValues() {
    #expect(LanguageModelCapabilities.default.rawValue == "default")
    #expect(LanguageModelCapabilities.tools.rawValue == "tools")
    #expect(LanguageModelCapabilities.reasoning.rawValue == "reasoning")
    #expect(LanguageModelCapabilities.vision.rawValue == "vision")
}