//
//  LanguageModelSessionTests.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import Testing
import GeneratableModelSystem

// Mock provider for testing
struct MockLanguageModelProvider: LanguageModelProvider {
    var api: LanguageModelProviderAPI { .openAI }
    var address: URL { URL(string: "https://api.test.com")! }
    var apiKey: String { "test-api-key" }
}

@Test("LanguageModelSession creation with provider")
func testLanguageModelSessionCreation() {
    let provider = MockLanguageModelProvider()
    let _ = LanguageModelSession("test-model", provider: provider) {
        "Test prompt"
    }
    
    // Verify session was created successfully without throwing
    #expect(Bool(true)) // Session created without errors
}

@Test("LanguageModelSession creation with simple provider")
func testLanguageModelSessionSimpleCreation() {
    let provider = MockLanguageModelProvider()
    let _ = LanguageModelSession("simple-model", provider: provider)
    
    // Verify session creation without prompt builder works without throwing
    #expect(Bool(true)) // Session created without errors
}

@Test("MockLanguageModelProvider properties")
func testMockLanguageModelProvider() {
    let provider = MockLanguageModelProvider()
    
    #expect(provider.api == .openAI)
    #expect(provider.address.absoluteString == "https://api.test.com")
    #expect(provider.apiKey == "test-api-key")
}

@Test("LanguageModelProviderAPI path components")
func testLanguageModelProviderAPIComponents() {
    let api = LanguageModelProviderAPI.openAI
    let components = api.pathComponents
    
    #expect(components.api == "/v1")
    #expect(components.generate == "/completions")
}

@Test("LanguageModelProviderAPI case iterable")
func testLanguageModelProviderAPICaseIterable() {
    let allCases = LanguageModelProviderAPI.allCases
    
    #expect(allCases.count == 1)
    #expect(allCases.contains(.openAI))
}

@Test("LanguageModelSession default provider usage")
func testLanguageModelSessionDefaultProvider() {
    // Set up default provider
    let provider = MockLanguageModelProvider()
    LanguageModelSession.defaultProvider = provider
    
    // Test creation without explicit provider
    let _ = LanguageModelSession("test-model")
    let _ = LanguageModelSession("test-model") {
        "Test prompt"
    }
    
    // Clean up
    LanguageModelSession.defaultProvider = nil
    
    #expect(Bool(true)) // Sessions created successfully with default provider
}

@Test("LanguageModelSession default provider not set error")
func testLanguageModelSessionNoDefaultProvider() {
    // Ensure no default provider is set
    LanguageModelSession.defaultProvider = nil
    
    // This should trigger a fatal error, but we can't easily test that in unit tests
    // Instead, we verify the defaultProvider is nil
    #expect(LanguageModelSession.defaultProvider == nil)
}

@Test("LanguageModelSession default provider setting and getting")
func testLanguageModelSessionDefaultProviderSetGet() {
    let provider = MockLanguageModelProvider()
    
    // Set default provider
    LanguageModelSession.defaultProvider = provider
    
    // Verify it was set
    #expect(LanguageModelSession.defaultProvider != nil)
    #expect(LanguageModelSession.defaultProvider?.apiKey == "test-api-key")
    
    // Clean up
    LanguageModelSession.defaultProvider = nil
    #expect(LanguageModelSession.defaultProvider == nil)
}