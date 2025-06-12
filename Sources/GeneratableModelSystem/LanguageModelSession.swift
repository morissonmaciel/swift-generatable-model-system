//
//  LanguageModelSession.swift
//  Llama Tools Mac
//
//  Created by Morisson Marcel on 10/06/25.
//

import Foundation

public enum LanguageModelSessionError: Error {
    case invalidResponseData
    case invalidResponseStatusCode
    case invalidResponseFormat(String)
    case noDefaultProviderSet
}

public struct LanguageModelSession {
    private let model: LanguageModel
    private let provider: LanguageModelProvider
    private let instructions: String
    
    public static var defaultProvider: LanguageModelProvider?
    
    public init(_ name: String, provider: LanguageModelProvider) {
        self.model = LanguageModel(name: name)
        self.provider = provider
        self.instructions = ""
    }
    
    public init(_ name: String, provider: LanguageModelProvider, @PromptBuilder instructions: () -> String) {
        self.model = LanguageModel(name: name)
        self.provider = provider
        self.instructions = instructions()
    }
    
    public init(_ name: String) {
        guard let defaultProvider = LanguageModelSession.defaultProvider else {
            fatalError("No default provider set. Use LanguageModelSession.defaultProvider = <provider> or provide a provider explicitly.")
        }
        self.model = LanguageModel(name: name)
        self.provider = defaultProvider
        self.instructions = ""
    }
    
    public init(_ name: String, @PromptBuilder instructions: () -> String) {
        guard let defaultProvider = LanguageModelSession.defaultProvider else {
            fatalError("No default provider set. Use LanguageModelSession.defaultProvider = <provider> or provide a provider explicitly.")
        }
        self.model = LanguageModel(name: name)
        self.provider = defaultProvider
        self.instructions = instructions()
    }
    
    public init(model: LanguageModel, provider: LanguageModelProvider, @PromptBuilder task: () -> String) {
        self.model = model
        self.provider = provider
        self.instructions = task()
    }
    
    private func buildRequest(for address: String, with components: LanguageModelProviderAPIComponents) -> URLRequest {
        var urlComponents = URLComponents(string: address)
        urlComponents?.path = components.api
        
        // Append generate path
        if !urlComponents!.path.hasSuffix(components.generate) {
            urlComponents?.path += components.generate
        }
        
        guard let url = urlComponents?.url else {
            fatalError("Invalid URL components")
        }
        
        return URLRequest(url: url)
    }
    
    private func buildRequestBody(with input: String, for api: LanguageModelProviderAPI) -> Data? {
        let finalPrompt = [instructions, input].joined(separator: "\n")
        
        let payload: [String: Codable] =
            switch api {
            case .openAI: ["model": model.name, "prompt": finalPrompt]
            }
        
        return try? JSONSerialization.data(withJSONObject: payload)
    }
    
    func respond<T: GeneratableProtocol>(to input: String) async throws -> T? {
        try await self.respond(to: { input })
    }
    
    func respond<T: GeneratableProtocol>(@PromptBuilder to inputBuilder: () -> String) async throws -> T? {
        var request = buildRequest(for: provider.address.absoluteString, with: provider.api.pathComponents)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = buildRequestBody(with: inputBuilder(), for: provider.api)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        var accumulator: [String] = []
        
        // Verify if response status code is 200 OK
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LanguageModelSessionError.invalidResponseStatusCode
        }

        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8),
                  let providerResponse = try? JSONDecoder().decode(provider.api.providerResponseType, from: data) else { continue }
            accumulator.append(providerResponse.contents)
        }
        
        let responseText = accumulator
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = responseText.data(using: String.Encoding.utf8) else {
            throw LanguageModelSessionError.invalidResponseData
        }

        guard let structuredResponse = try? JSONDecoder().decode(T.self, from: data) else {
            throw LanguageModelSessionError.invalidResponseFormat(responseText)
        }
        
        return structuredResponse
    }
}
