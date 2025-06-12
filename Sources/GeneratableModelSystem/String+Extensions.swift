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
    /// explanatory text.
    ///
    /// ## Example
    /// ```swift
    /// let response = """
    /// Here's the JSON response:
    /// ```json
    /// {"name": "John", "age": 30}
    /// ```
    /// """
    /// 
    /// let json = response.extractJSON()
    /// // Returns: {"name": "John", "age": 30}
    /// ```
    ///
    /// - Returns: The extracted JSON string if valid JSON is found, `nil` otherwise.
    func extractJSON() -> String? {
        guard let startIndex = self.range(of: "{")?.lowerBound,
              let endIndex = self.range(of: "}", options: .backwards)?.upperBound else {
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