//
//  String+Extensions.swift
//  GeneratableModelSystem
//
//  Created by Morisson Marcel on 10/06/25.
//

import Foundation

extension String {
    /// Extracts valid JSON from a string that may contain additional text.
    ///
    /// This method searches for JSON content within a string, handling cases where
    /// language models return JSON wrapped in markdown code blocks or mixed with
    /// explanatory text. It properly handles nested objects and arrays by counting
    /// braces to find the complete JSON object.
    ///
    /// ## Example
    /// ```swift
    /// let response = """
    /// Here's the JSON response:
    /// ```json
    /// {"name": "John", "age": 30, "data": {"nested": true}}
    /// ```
    /// """
    /// 
    /// let json = response.extractJSON()
    /// // Returns: {"name": "John", "age": 30, "data": {"nested": true}}
    /// ```
    ///
    /// - Returns: The extracted JSON string if valid JSON is found, `nil` otherwise.
    public func extractJSON() -> String? {
        guard let startIndex = self.range(of: "{")?.lowerBound else {
            return nil
        }
        
        // Find the matching closing brace by counting braces
        var braceCount = 0
        var inString = false
        var isEscaped = false
        var endIndex: String.Index? = nil
        
        for (offset, char) in self[startIndex...].enumerated() {
            let currentIndex = self.index(startIndex, offsetBy: offset)
            
            if isEscaped {
                isEscaped = false
                continue
            }
            
            if char == "\\" {
                isEscaped = true
                continue
            }
            
            if char == "\"" && !isEscaped {
                inString.toggle()
                continue
            }
            
            if !inString {
                if char == "{" {
                    braceCount += 1
                } else if char == "}" {
                    braceCount -= 1
                    if braceCount == 0 {
                        endIndex = self.index(after: currentIndex)
                        break
                    }
                }
            }
        }
        
        guard let endIndex = endIndex else {
            return nil
        }
        
        let jsonSubstring = self[startIndex..<endIndex]
        let potentialJSON = String(jsonSubstring)
        
        // Verify if it's valid JSON
        guard let data = potentialJSON.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        
        return potentialJSON
    }
    
    /// Extracts potentially incomplete JSON from a string for partial generation.
    ///
    /// This method is similar to `extractJSON()` but is more lenient and can handle
    /// incomplete JSON objects that might be generated during streaming responses.
    /// It attempts to extract valid JSON fragments even if the complete object
    /// is not yet available.
    ///
    /// ## Example
    /// ```swift
    /// let partialResponse = """
    /// Here's the partial response:
    /// ```json
    /// {"destination": "Japan", "activiti
    /// ```
    /// 
    /// let json = response.extractPartialJSON()
    /// // Returns: {"destination": "Japan"}
    /// ```
    ///
    /// - Returns: The extracted partial JSON string if valid JSON is found, `nil` otherwise.
    public func extractPartialJSON() -> String? {
        guard let startIndex = self.range(of: "{")?.lowerBound else {
            return nil
        }
        
        // Try to find the complete JSON first using the standard method
        if let completeJSON = self.extractJSON() {
            return completeJSON
        }
        
        // If complete JSON extraction fails, try to extract a partial JSON
        var currentJSON = ""
        var braceCount = 0
        var inString = false
        var isEscaped = false
        var lastValidJSON = ""
        
        for (offset, char) in self[startIndex...].enumerated() {
            let currentIndex = self.index(startIndex, offsetBy: offset)
            currentJSON.append(char)
            
            if isEscaped {
                isEscaped = false
                continue
            }
            
            if char == "\\" {
                isEscaped = true
                continue
            }
            
            if char == "\"" && !isEscaped {
                inString.toggle()
                continue
            }
            
            if !inString {
                if char == "{" {
                    braceCount += 1
                } else if char == "}" {
                    braceCount -= 1
                    if braceCount == 0 {
                        // Found a complete object
                        let endIndex = self.index(after: currentIndex)
                        let jsonSubstring = self[startIndex..<endIndex]
                        return String(jsonSubstring)
                    }
                }
                
                // Try to validate current JSON periodically at key boundaries
                if !inString && (char == "," || char == "}") && braceCount > 0 {
                    // Try to make current JSON valid by closing remaining braces
                    let closingBraces = String(repeating: "}", count: braceCount)
                    let potentialJSON = currentJSON + closingBraces
                    
                    if let data = potentialJSON.data(using: .utf8),
                       let _ = try? JSONSerialization.jsonObject(with: data) {
                        lastValidJSON = potentialJSON
                    }
                }
            }
        }
        
        // Return the last valid partial JSON we found
        return lastValidJSON.isEmpty ? nil : lastValidJSON
    }
    
    /// Extracts potentially incomplete JSON from a string with text fragment completion support.
    ///
    /// This method extends `extractPartialJSON()` to handle incomplete text fragments in string properties.
    /// When `allowsTextFragment` is enabled, it can complete partial strings like `{"destination": "Jap`
    /// to `{"destination": "Jap"}` for parsing, enabling real-time text streaming.
    ///
    /// - Parameter allowsTextFragment: When `true`, attempts to complete incomplete string values.
    /// - Parameter scheme: The scheme to validate that fragments only apply to String-type properties.
    /// - Returns: The extracted and potentially completed JSON string, or `nil` if no valid JSON found.
    ///
    /// ## Example
    /// ```swift
    /// let partialText = "{ \"destination\": \"Jap"
    /// let scheme = ["destination": GuideDescriptor(type: "string", description: "Country")]
    /// let completed = partialText.extractPartialJSON(allowsTextFragment: true, scheme: scheme)
    /// // Returns: "{ \"destination\": \"Jap\" }"
    /// ```
    public func extractPartialJSON(allowsTextFragment: Bool, scheme: [String: GuideDescriptor]) -> String? {
        // First try standard partial extraction
        if let standardJSON = self.extractPartialJSON() {
            return standardJSON
        }
        
        // If text fragments are not allowed, return nil
        guard allowsTextFragment else {
            return nil
        }
        
        // Try to complete text fragments
        return self.extractPartialJSONWithTextFragments(scheme: scheme)
    }
    
    /// Internal method to handle text fragment completion logic.
    private func extractPartialJSONWithTextFragments(scheme: [String: GuideDescriptor]) -> String? {
        guard let startIndex = self.range(of: "{")?.lowerBound else {
            return nil
        }
        
        let jsonText = String(self[startIndex...])
        
        // Try to complete incomplete JSON by finding unterminated strings
        return completeIncompleteJSON(jsonText, scheme: scheme)
    }
    
    /// Attempts to complete incomplete JSON by fixing unterminated strings and structures.
    private func completeIncompleteJSON(_ incompleteJSON: String, scheme: [String: GuideDescriptor]) -> String? {
        var json = incompleteJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use regex to find incomplete string patterns like: "key": "partial_tex
        let pattern = #"\"([^\"]+)\"\s*:\s*\"([^\"]*)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: json.utf16.count)
        
        if let matches = regex?.matches(in: json, range: range),
           let match = matches.last {
            let keyRange = Range(match.range(at: 1), in: json)!
            let key = String(json[keyRange])
            
            // Check if this key is a string type in the scheme
            if let descriptor = scheme[key], descriptor.type == "string" {
                // Add closing quote to complete the incomplete string
                json += "\""
            }
        }
        
        // Count braces and brackets to close the JSON properly
        let openBraces = json.filter { $0 == "{" }.count
        let closeBraces = json.filter { $0 == "}" }.count
        let openBrackets = json.filter { $0 == "[" }.count
        let closeBrackets = json.filter { $0 == "]" }.count
        
        // Add missing closing brackets and braces
        json += String(repeating: "]", count: max(0, openBrackets - closeBrackets))
        json += String(repeating: "}", count: max(0, openBraces - closeBraces))
        
        // Validate the completed JSON
        if let data = json.data(using: .utf8),
           let _ = try? JSONSerialization.jsonObject(with: data) {
            return json
        }
        
        return nil
    }
}