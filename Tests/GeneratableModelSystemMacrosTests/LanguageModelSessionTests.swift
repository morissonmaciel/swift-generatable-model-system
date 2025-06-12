//
//  LanguageModelSessionTests.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import Testing
import GeneratableModelSystem

// Test model for JSON responses
struct TestResponse: GeneratableProtocol, Codable, Equatable {
    let message: String
    let code: Int
    
    static var description: String {
        "A test response model for validating JSON parsing"
    }
    
    static var scheme: [String: GuideDescriptor] {
        [
            "message": .init(type: "String", description: "Response message"),
            "code": .init(type: "Int", description: "Response code")
        ]
    }
}

// Mock response struct
private struct MockResponse: Codable {
    let content: String
}

// Mock provider for testing
struct MockLanguageModelProvider: LanguageModelProvider {
    var api: LanguageModelProviderAPI { _api }
    var address: URL { _address }
    var apiKey: String { _apiKey }
    
    private let _api: LanguageModelProviderAPI
    private let _address: URL
    private let _apiKey: String
    
    // Custom response for testing
    var mockResponse: String
    
    init(mockResponse: String = "",
         api: LanguageModelProviderAPI = .openAI,
         address: URL = URL(string: "https://api.test.com")!,
         apiKey: String = "test-api-key") {
        self.mockResponse = mockResponse
        self._api = api
        self._address = address
        self._apiKey = apiKey
    }
    
    func makeURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        
        // Store mock response in the session configuration
        let mockData = try! JSONEncoder().encode(MockResponse(content: mockResponse))
        configuration.httpAdditionalHeaders = ["Provider-Mock": String(data: mockData, encoding: .utf8)!]
        
        return URLSession(configuration: configuration)
    }
}

// Mock URL Protocol for simulating network responses
class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let client = client else { return }
        
        // Get the mock response from the provider
        guard let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.path.contains("/completions") else {
            client.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Use the stored mock response from the session configuration
        guard let mockDataString = request.allHTTPHeaderFields?["Provider-Mock"],
              let mockData = mockDataString.data(using: .utf8),
              let mockResponse = try? JSONDecoder().decode(MockResponse.self, from: mockData) else {
            client.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Create mock response data in expected format - escape newlines in content
        let escapedContent = mockResponse.content.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\"", with: "\\\"")
        let responseJSON = """
        {"model":"test-model","created":1623456789,"usage":{"prompt_tokens":10,"completion_tokens":20,"total_tokens":30},"choices":[{"index":0,"text":"\(escapedContent)"}]}
        """
        
        
        let response = HTTPURLResponse(url: url,
                                     statusCode: 200,
                                     httpVersion: "2.0",
                                     headerFields: ["Content-Type": "application/json"])!
        
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: responseJSON.data(using: .utf8)!)
        client.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

@Test("LanguageModelSession creation with provider")
func testLanguageModelSessionCreation() async throws {
    let provider = MockLanguageModelProvider(mockResponse: "test")
    let mockURLSession = provider.makeURLSession()
    var session = LanguageModelSession("test-model") {
        "Test prompt"
    }
    session.provider = provider
    session.urlSession = mockURLSession
    
    #expect(session.provider?.apiKey == provider.apiKey)
}

@Test("LanguageModelSession creation with simple provider")
func testLanguageModelSessionSimpleCreation() {
    let provider = MockLanguageModelProvider()
    let mockURLSession = provider.makeURLSession()
    var session = LanguageModelSession("simple-model")
    session.provider = provider
    session.urlSession = mockURLSession
    
    // Test passes if no exception is thrown during creation
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
func testLanguageModelSessionDefaultProvider() async throws {
    // Store original state
    let originalProvider = LanguageModelSession.defaultProvider
    let originalURLSession = LanguageModelSession.defaultURLSession
    
    defer {
        // Restore original state
        LanguageModelSession.defaultProvider = originalProvider
        LanguageModelSession.defaultURLSession = originalURLSession
    }
    
    // Set up default provider and session
    let provider = MockLanguageModelProvider(mockResponse: "test")
    let mockURLSession = provider.makeURLSession()
    LanguageModelSession.defaultProvider = provider
    LanguageModelSession.defaultURLSession = mockURLSession
    
    // Test creation without explicit provider
    let session1 = LanguageModelSession("test-model")
    let session2 = LanguageModelSession("test-model") {
        "Test prompt"
    }
    
    // Verify sessions use default provider when none is set
    #expect(session1.provider == nil) // Should fallback to default
    #expect(session2.provider == nil) // Should fallback to default
    #expect(LanguageModelSession.defaultProvider?.apiKey == "test-api-key")
}

@Test("LanguageModelSession default provider not set error")
func testLanguageModelSessionNoDefaultProvider() async throws {
    // Store original state
    let originalProvider = LanguageModelSession.defaultProvider
    
    defer {
        LanguageModelSession.defaultProvider = originalProvider
    }
    
    // Ensure no default provider is set
    LanguageModelSession.defaultProvider = nil
    
    let session = LanguageModelSession("test-model")
    
    do {
        let _: TestResponse? = try await session.respond(to: "test prompt")
        #expect(Bool(false), "Expected noDefaultProviderSet error but request succeeded")
    } catch LanguageModelSessionError.noDefaultProviderSet {
        // Test passes - we got the expected error
    }
}

@Test("LanguageModelSession default provider setting and getting")
func testLanguageModelSessionDefaultProviderSetGet() async throws {
    // Store original provider to restore later
    let originalProvider = LanguageModelSession.defaultProvider
    
    defer {
        // Restore original state
        LanguageModelSession.defaultProvider = originalProvider
    }
    
    let provider = MockLanguageModelProvider(mockResponse: "test")
    LanguageModelSession.defaultProvider = provider
    
    // Verify provider is set correctly
    guard let defaultProvider = LanguageModelSession.defaultProvider as? MockLanguageModelProvider else {
        throw LanguageModelSessionError.noDefaultProviderSet
    }
    
    #expect(defaultProvider.apiKey == "test-api-key")
    #expect(defaultProvider.address.absoluteString == "https://api.test.com")
}

@Test("JSON handling with valid markdown code block")
func testValidJsonInMarkdown() async throws {
    let provider = MockLanguageModelProvider(mockResponse: """
    Here's the response:
    ```json
    {
        "message": "Success",
        "code": 200
    }
    ```
    """)
    
    let mockURLSession = provider.makeURLSession()
    var session = LanguageModelSession("test-model")
    session.provider = provider
    session.urlSession = mockURLSession
    
    let response: TestResponse? = try await withTimeout(seconds: 5) {
        try await session.respond(to: "test prompt")
    }
    
    #expect(response != nil)
    #expect(response?.message == "Success")
    #expect(response?.code == 200)
}

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw LanguageModelSessionError.invalidResponseData
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

@Test("JSON handling with invalid JSON format")
func testInvalidJsonFormat() async throws {
    let provider = MockLanguageModelProvider(mockResponse: """
    ```json
    {
        "message": "Invalid,
        "code": 500,
    }
    ```
    """)
    
    let mockURLSession = provider.makeURLSession()
    var session = LanguageModelSession("test-model")
    session.provider = provider
    session.urlSession = mockURLSession
    
    do {
        let _: TestResponse? = try await withTimeout(seconds: 5) {
            try await session.respond(to: "test prompt")
        }
        #expect(Bool(false), "Expected JSON parsing to fail but it succeeded")
    } catch is LanguageModelSessionError {
        // Test passes - we got the expected error type
    }
}

@Test("JSON handling without markdown formatting")
func testJsonWithoutMarkdown() async throws {
    let provider = MockLanguageModelProvider(mockResponse: """
    {
        "message": "Direct JSON",
        "code": 201
    }
    """)
    
    let mockURLSession = provider.makeURLSession()
    var session = LanguageModelSession("test-model")
    session.provider = provider
    session.urlSession = mockURLSession
    
    let response: TestResponse? = try await withTimeout(seconds: 5) {
        try await session.respond(to: "test prompt")
    }
    
    #expect(response != nil)
    #expect(response?.message == "Direct JSON")
    #expect(response?.code == 201)
}

@Test("Static URLSession configuration")
func testStaticURLSessionConfiguration() {
    let provider = MockLanguageModelProvider()
    let mockURLSession = provider.makeURLSession()
    
    // Set custom URLSession
    LanguageModelSession.defaultURLSession = mockURLSession
    #expect(LanguageModelSession.defaultURLSession !== URLSession.shared)
    
    // Reset to nil
    LanguageModelSession.defaultURLSession = nil
    #expect(LanguageModelSession.defaultURLSession == nil)
}

@Test("Generate method returns raw response text")
func testGenerateRawResponse() async throws {
    let provider = MockLanguageModelProvider(mockResponse: """
    Here's the response:
    ```json
    {
        "message": "Success",
        "code": 200
    }
    ```
    """)
    
    let mockURLSession = provider.makeURLSession()
    var session = LanguageModelSession("test-model")
    session.provider = provider
    session.urlSession = mockURLSession
    
    let response = try await withTimeout(seconds: 5) {
        try await session.generate(to: "test prompt")
    }
    
    #expect(response.contains("Here's the response:"))
    #expect(response.contains("```json"))
    #expect(response.contains("\"message\": \"Success\""))
    #expect(response.contains("\"code\": 200"))
    #expect(response.contains("```"))
}

@Test("Generate method with PromptBuilder")
func testGenerateWithPromptBuilder() async throws {
    let provider = MockLanguageModelProvider(mockResponse: "Simple response text")
    
    let mockURLSession = provider.makeURLSession()
    var session = LanguageModelSession("test-model")
    session.provider = provider
    session.urlSession = mockURLSession
    
    let response = try await withTimeout(seconds: 5) {
        try await session.generate {
            "Complex prompt"
        }
    }
    
    #expect(response == "Simple response text")
}

@Test("Generate method error handling when no provider set")
func testGenerateNoProviderError() async throws {
    // Store original state
    let originalProvider = LanguageModelSession.defaultProvider
    
    defer {
        LanguageModelSession.defaultProvider = originalProvider
    }
    
    // Ensure no default provider is set
    LanguageModelSession.defaultProvider = nil
    
    let session = LanguageModelSession("test-model")
    
    do {
        let _ = try await session.generate(to: "test prompt")
        #expect(Bool(false), "Expected noDefaultProviderSet error but request succeeded")
    } catch LanguageModelSessionError.noDefaultProviderSet {
        // Test passes - we got the expected error
    }
}

@Test("JSON extraction with complex nested content and escaped characters")
func testComplexJsonExtraction() async throws {
    let complexJson = """
    {
      "message": "A RAG system combines a large language model with an external knowledge base. Here's how it works:\\n\\n1. **Retrieval:** When a user asks a question, the system searches a knowledge base.\\n2. **Augmentation:** The retrieved information is added to the original question, effectively \\"augmenting\\" it with context.\\n3. **Generation:** The augmented query is fed to the LLM.",
      "suggestions": [
        "What are some common knowledge bases used in RAG systems?",
        "How does RAG improve upon traditional LLM-based question answering?",
        "Can you explain the different retrieval methods used in RAG systems?"
      ],
      "topics": [
        "RAG System",
        "Large Language Models",
        "Knowledge Retrieval"
      ]
    }
    """
    
    let responseWithMarkdown = "```json\n\(complexJson)\n```"
    
    // Test that extractJSON correctly handles this complex case
    let extractedJSON = responseWithMarkdown.extractJSON()
    #expect(extractedJSON != nil, "Should extract JSON from markdown wrapper")
    
    if let extractedJSON = extractedJSON {
        // Verify the extracted JSON is valid
        let data = extractedJSON.data(using: String.Encoding.utf8)!
        let _ = try JSONSerialization.jsonObject(with: data)
        
        // Test that it can be decoded to a structure with the same fields
        struct ComplexTestResponse: Codable {
            let message: String
            let topics: [String]
            let suggestions: [String]
        }
        
        let response = try JSONDecoder().decode(ComplexTestResponse.self, from: data)
        #expect(response.message.contains("RAG system"), "Should decode message correctly")
        #expect(response.topics.count == 3, "Should have correct number of topics")
        #expect(response.suggestions.count == 3, "Should have correct number of suggestions")
    }
}