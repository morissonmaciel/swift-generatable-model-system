//
//  LanguageModelSession.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 10/06/25.
//

import Foundation

/// Errors that can occur during language model session operations.
public enum LanguageModelSessionError: Error {
    /// The response data could not be converted to the expected format.
    case invalidResponseData
    
    /// The HTTP response status code indicates an error (not 2xx).
    case invalidResponseStatusCode
    
    /// The response format is invalid. Associated value contains the actual response content.
    case invalidResponseFormat(String)
    
    /// No language model provider is configured (neither instance nor default).
    case noDefaultProviderSet
}

/// A session for interacting with language models that provides both structured JSON responses
/// and raw text generation capabilities.
///
/// `LanguageModelSession` supports flexible configuration through instance properties and static defaults:
/// - **Instance Configuration**: Set `provider` and `urlSession` properties directly
/// - **Static Defaults**: Configure `defaultProvider` and `defaultURLSession` for convenience
/// - **Fallback Chain**: Instance → Static → Built-in defaults
///
/// ## Usage
///
/// ### Basic Setup
/// ```swift
/// var session = LanguageModelSession("gpt-4")
/// session.provider = myProvider
/// session.urlSession = myURLSession
/// ```
///
/// ### Using Static Defaults
/// ```swift
/// LanguageModelSession.defaultProvider = myProvider
/// LanguageModelSession.defaultURLSession = myURLSession
/// 
/// let session = LanguageModelSession("gpt-4") // Uses defaults
/// ```
///
/// ### Structured JSON Response
/// ```swift
/// let response: UserProfile = try await session.respond(to: "Generate a user profile")
/// ```
///
/// ### Raw Text Response
/// ```swift
/// let text: String = try await session.generate(to: "Tell me a joke")
/// ```
public struct LanguageModelSession {
    private let model: LanguageModel
    private let instructions: String
    
    /// The language model provider for this session. 
    /// If `nil`, falls back to `defaultProvider`. If both are `nil`, methods will throw `noDefaultProviderSet`.
    public var provider: LanguageModelProvider?
    
    /// The URL session for network requests.
    /// If `nil`, falls back to `defaultURLSession`, then to `URLSession.shared`.
    public var urlSession: URLSession?
    
    /// Default provider used when no instance provider is set.
    /// Configure this once to avoid setting provider on each session.
    public static var defaultProvider: LanguageModelProvider?
    
    /// Default URL session used when no instance URL session is set.
    /// If `nil`, falls back to `URLSession.shared`.
    public static var defaultURLSession: URLSession?
    
    /// Creates a language model session with the specified model name.
    /// 
    /// - Parameter name: The name of the language model to use (e.g., "gpt-4", "claude-3").
    /// 
    /// ## Example
    /// ```swift
    /// let session = LanguageModelSession("gpt-4")
    /// session.provider = myProvider
    /// ```
    public init(_ name: String) {
        self.model = LanguageModel(name: name)
        self.instructions = ""
        self.provider = nil
        self.urlSession = nil
    }
    
    /// Creates a language model session with the specified model name and instructions.
    /// 
    /// - Parameters:
    ///   - name: The name of the language model to use.
    ///   - instructions: A closure that builds the system instructions/prompt for the session.
    /// 
    /// ## Example
    /// ```swift
    /// let session = LanguageModelSession("gpt-4") {
    ///     "You are a helpful assistant that generates structured data."
    /// }
    /// ```
    public init(_ name: String, @PromptBuilder instructions: () -> String) {
        self.model = LanguageModel(name: name)
        self.instructions = instructions()
        self.provider = nil
        self.urlSession = nil
    }
    
    /// Creates a language model session with a custom model and task instructions.
    /// 
    /// - Parameters:
    ///   - model: The language model instance to use.
    ///   - task: A closure that builds the task instructions for the session.
    /// 
    /// ## Example
    /// ```swift
    /// let customModel = LanguageModel(name: "custom-model")
    /// let session = LanguageModelSession(model: customModel) {
    ///     "Process the following data: \(inputData)"
    /// }
    /// ```
    public init(model: LanguageModel, @PromptBuilder task: () -> String) {
        self.model = model
        self.instructions = task()
        self.provider = nil
        self.urlSession = nil
    }
    
    private func buildRequest(for address: String, with components: LanguageModelProviderAPIComponents, using urlSession: URLSession) -> URLRequest {
        var urlComponents = URLComponents(string: address)
        urlComponents?.path = components.api
        
        // Append generate path
        if !urlComponents!.path.hasSuffix(components.generate) {
            urlComponents?.path += components.generate
        }
        
        guard let url = urlComponents?.url else {
            fatalError("Invalid URL components")
        }
        
        var request = URLRequest(url: url)
        
        // Copy any mock headers from the URLSession configuration
        if let mockHeaders = urlSession.configuration.httpAdditionalHeaders {
            for (key, value) in mockHeaders {
                request.setValue(value as? String, forHTTPHeaderField: key as! String)
            }
        }
        
        return request
    }
    
    private func buildRequestBody(with input: String, for provider: LanguageModelProvider, streaming: Bool) throws -> Data {
        let finalPrompt = [instructions, input].joined(separator: "\n")
        return try streaming ?
            provider.createStreamingPayload(modelName: model.name, prompt: finalPrompt) :
            provider.createNonStreamingPayload(modelName: model.name, prompt: finalPrompt)
    }
    
    /// Generates a structured response by parsing JSON from the language model output.
    /// 
    /// This method sends the input to the language model, extracts JSON from the response 
    /// (handling markdown code blocks), and decodes it to the specified type.
    /// 
    /// - Parameter input: The prompt text to send to the language model.
    /// - Returns: A decoded instance of type `T`, or `nil` if decoding fails.
    /// - Throws: `LanguageModelSessionError` for various failure scenarios.
    /// 
    /// ## Example
    /// ```swift
    /// let profile: UserProfile = try await session.respond(to: "Generate a user profile")
    /// ```
    /// 
    /// ## Error Handling
    /// - `noDefaultProviderSet`: No provider configured
    /// - `invalidResponseStatusCode`: HTTP error from the provider
    /// - `invalidResponseFormat`: JSON parsing failed
    /// - `invalidResponseData`: Data conversion failed
    public func respond<T: GeneratableProtocol>(to input: String) async throws -> T? {
        try await self.respond(to: { input })
    }
    
    /// Generates raw text from the language model without any JSON parsing.
    /// 
    /// This method sends the input to the language model and returns the unprocessed 
    /// response text. Useful for creative writing, explanations, or non-structured output.
    /// 
    /// - Parameter input: The prompt text to send to the language model.
    /// - Returns: The raw response text from the language model.
    /// - Throws: `LanguageModelSessionError` for network or provider errors.
    /// 
    /// ## Example
    /// ```swift
    /// let joke: String = try await session.generate(to: "Tell me a joke")
    /// let story: String = try await session.generate(to: "Write a short story about space")
    /// ```
    public func generate(to input: String) async throws -> String {
        try await self.generate(to: { input })
    }
    
    /// Generates raw text from the language model using a PromptBuilder closure.
    /// 
    /// This method allows you to build complex prompts with string interpolation and 
    /// returns the unprocessed response text from the language model.
    /// 
    /// - Parameter inputBuilder: A closure that builds the prompt using PromptBuilder syntax.
    /// - Returns: The raw response text from the language model.
    /// - Throws: `LanguageModelSessionError` for network or provider errors.
    /// 
    /// ## Example
    /// ```swift
    /// let story = try await session.generate {
    ///     "Write a story about \(character) in \(setting) with \(theme) theme"
    /// }
    /// ```
    public func generate(@PromptBuilder to inputBuilder: () -> String) async throws -> String {
        // Determine provider with fallback
        guard let activeProvider = provider ?? LanguageModelSession.defaultProvider else {
            throw LanguageModelSessionError.noDefaultProviderSet
        }
        
        // Determine URLSession with fallback
        let activeURLSession = urlSession ?? LanguageModelSession.defaultURLSession ?? .shared
        
        var request = buildRequest(for: activeProvider.address.absoluteString, with: activeProvider.api.pathComponents, using: activeURLSession)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(activeProvider.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try buildRequestBody(with: inputBuilder(), for: activeProvider, streaming: false)
        
        let (bytes, response) = try await activeURLSession.bytes(for: request)
        var accumulator: [String] = []
        
        // Verify if response status code is 200 OK
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LanguageModelSessionError.invalidResponseStatusCode
        }

        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8) else {
                // Log data conversion error but continue processing
                continue
            }
            
            do {
                let providerResponse = try JSONDecoder().decode(activeProvider.api.providerResponseType, from: data)
                accumulator.append(providerResponse.contents)
            } catch {
                // Log JSON decode error but continue processing
                continue
            }
        }
        
        return accumulator
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Generates a structured response using a PromptBuilder closure and JSON parsing.
    /// 
    /// This method allows you to build complex prompts with string interpolation, sends them 
    /// to the language model, extracts JSON from the response, and decodes it to the specified type.
    /// 
    /// - Parameter inputBuilder: A closure that builds the prompt using PromptBuilder syntax.
    /// - Returns: A decoded instance of type `T`, or `nil` if decoding fails.
    /// - Throws: `LanguageModelSessionError` for various failure scenarios.
    /// 
    /// ## Example
    /// ```swift
    /// let profile: UserProfile = try await session.respond {
    ///     "Generate a user profile for a \(profession) from \(country)"
    /// }
    /// ```
    /// 
    /// ## Error Handling
    /// - `noDefaultProviderSet`: No provider configured
    /// - `invalidResponseStatusCode`: HTTP error from the provider  
    /// - `invalidResponseFormat`: JSON parsing failed
    /// - `invalidResponseData`: Data conversion failed
    public func respond<T: GeneratableProtocol>(@PromptBuilder to inputBuilder: () -> String) async throws -> T? {
        // Determine provider with fallback
        guard let activeProvider = provider ?? LanguageModelSession.defaultProvider else {
            throw LanguageModelSessionError.noDefaultProviderSet
        }
        
        // Determine URLSession with fallback
        let activeURLSession = urlSession ?? LanguageModelSession.defaultURLSession ?? .shared
        
        var request = buildRequest(for: activeProvider.address.absoluteString, with: activeProvider.api.pathComponents, using: activeURLSession)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(activeProvider.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try buildRequestBody(with: inputBuilder(), for: activeProvider, streaming: false)
        
        let (bytes, response) = try await activeURLSession.bytes(for: request)
        var accumulator: [String] = []
        
        // Verify if response status code is 200 OK
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LanguageModelSessionError.invalidResponseStatusCode
        }

        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8) else {
                // Log data conversion error but continue processing
                continue
            }
            
            do {
                let providerResponse = try JSONDecoder().decode(activeProvider.api.providerResponseType, from: data)
                accumulator.append(providerResponse.contents)
            } catch {
                // Log JSON decode error but continue processing
                continue
            }
        }
        
        let responseText = accumulator
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        guard let jsonString = responseText.extractJSON() else {
            throw LanguageModelSessionError.invalidResponseFormat(responseText)
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw LanguageModelSessionError.invalidResponseData
        }
        
        guard let structuredResponse = try? JSONDecoder().decode(T.self, from: data) else {
            throw LanguageModelSessionError.invalidResponseFormat(jsonString)
        }
        
        return structuredResponse
    }
    
    /// Generates a streaming partial response from the language model using a PromptBuilder closure.
    ///
    /// This method allows you to receive partial responses as they are generated by the language model,
    /// enabling real-time updates of structured data as it becomes available. Each emitted value in the
    /// stream represents the most complete version of the partial object that could be parsed at that point.
    ///
    /// - Parameter inputBuilder: A closure that builds the prompt using PromptBuilder syntax.
    /// - Parameter allowsTextFragment: When `true`, enables parsing of incomplete text fragments in string properties.
    ///   For example, `{"destination": "Jap"` would be completed to `{"destination": "Jap"}` for parsing.
    ///   Only applies to String-type properties. Defaults to `false`.
    /// - Returns: An AsyncStream of optional partially generated instances of type `T`.
    /// - Throws: `LanguageModelSessionError` for network or provider errors.
    ///
    /// ## Example
    /// ```swift
    /// for await partialPlan in session.respondPartially(allowsTextFragment: true) {
    ///     "Generate a detailed trip plan for Japan"
    /// } as AsyncStream<TripPlan.PartiallyGenerated?> {
    ///     if let plan = partialPlan {
    ///         // Handle incremental updates, including text fragments
    ///         if let destination = plan.destination {
    ///             print("Destination: \(destination)") // Could show "Jap", "Japa", "Japan"
    ///         }
    ///         if let activities = plan.activities, !activities.isEmpty {
    ///             print("Activities so far: \(activities)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Error Handling
    /// - `noDefaultProviderSet`: No provider configured
    /// - `invalidResponseStatusCode`: HTTP error from the provider
    /// - Network or provider errors will complete the stream with an error
    public func respondPartially<T: PartiallyGeneratedProtocol>(@PromptBuilder to inputBuilder: () -> String, allowsTextFragment: Bool = false) -> AsyncThrowingStream<T?, Error> {
        let input = inputBuilder() // Capture the input outside the closure
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Determine provider with fallback
                    guard let activeProvider = provider ?? LanguageModelSession.defaultProvider else {
                        continuation.finish(throwing: LanguageModelSessionError.noDefaultProviderSet)
                        return
                    }
                    
                    // Determine URLSession with fallback
                    let activeURLSession = urlSession ?? LanguageModelSession.defaultURLSession ?? .shared
                    
                    var request = buildRequest(for: activeProvider.address.absoluteString, with: activeProvider.api.pathComponents, using: activeURLSession)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(activeProvider.apiKey)", forHTTPHeaderField: "Authorization")
                    request.httpBody = try buildRequestBody(with: input, for: activeProvider, streaming: true)
                    
                    let (bytes, response) = try await activeURLSession.bytes(for: request)
                    var accumulator: [String] = []
                    
                    // Verify if response status code is 200 OK
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200..<300).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: LanguageModelSessionError.invalidResponseStatusCode)
                        return
                    }

                    var parseErrors: [Error] = []
                    
                    for try await line in bytes.lines {
                        // Use provider-specific preprocessing for streaming format
                        guard let processedLine = activeProvider.api.preprocessStreamingLine(line) else { continue }
                        
                        guard let data = processedLine.data(using: .utf8) else {
                            parseErrors.append(LanguageModelSessionError.invalidResponseData)
                            continue
                        }
                        
                        do {
                            let providerResponse = try JSONDecoder().decode(activeProvider.api.providerResponseType, from: data)
                            let newContent = providerResponse.contents
                            accumulator.append(newContent)
                            
                            // Try parsing with accumulated content
                            let fullText = accumulator.joined().trimmingCharacters(in: .whitespacesAndNewlines)
                            if let partialResponse = tryParsePartialResponse(from: fullText, allowsTextFragment: allowsTextFragment, type: T.self) {
                                continuation.yield(partialResponse)
                            }
                        } catch {
                            parseErrors.append(error)
                            // Continue processing other lines even if one fails
                            continue
                        }
                    }
                    
                    // Final attempt with complete response
                    let responseText = accumulator
                        .joined()
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let jsonString = responseText.extractJSON(),
                       let jsonData = jsonString.data(using: .utf8),
                       let finalResponse = try? JSONDecoder().decode(T.self, from: jsonData) {
                        continuation.yield(finalResponse)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Generates a streaming partial response from the language model.
    ///
    /// This method allows you to receive partial responses as they are generated by the language model,
    /// enabling real-time updates of structured data as it becomes available.
    ///
    /// - Parameter input: The prompt text to send to the language model.
    /// - Parameter allowsTextFragment: When `true`, enables parsing of incomplete text fragments in string properties.
    ///   For example, `{"destination": "Jap"` would be completed to `{"destination": "Jap"}` for parsing.
    ///   Only applies to String-type properties. Defaults to `false`.
    /// - Returns: An AsyncStream of optional partially generated instances of type `T`.
    /// - Throws: `LanguageModelSessionError` for network or provider errors.
    ///
    /// ## Example
    /// ```swift
    /// for await partialPlan in session.respondPartially(to: "Generate a trip plan", allowsTextFragment: true) as AsyncStream<TripPlan.PartiallyGenerated?> {
    ///     if let plan = partialPlan {
    ///         // Handle incremental updates including text fragments
    ///         print("Current state: \(plan)")
    ///     }
    /// }
    /// ```
    public func respondPartially<T: PartiallyGeneratedProtocol>(to input: String, allowsTextFragment: Bool = false) -> AsyncThrowingStream<T?, Error> {
        return self.respondPartially(to: { input }, allowsTextFragment: allowsTextFragment)
    }
    
    /// Helper method to attempt parsing a partial response from text
    private func tryParsePartialResponse<T: PartiallyGeneratedProtocol>(from text: String, allowsTextFragment: Bool, type: T.Type) -> T? {
        let extractedJSON = allowsTextFragment ?
            text.extractPartialJSON(allowsTextFragment: true, scheme: T.scheme) :
            text.extractPartialJSON()
        
        guard let jsonString = extractedJSON,
              let jsonData = jsonString.data(using: .utf8),
              let partialResponse = try? JSONDecoder().decode(T.self, from: jsonData) else {
            return nil
        }
        
        return partialResponse
    }
}
