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
}