//
//  GuideDescriptor.swift
//  Llama Tools Mac
//
//  Created by Morisson Marcel on 10/06/25.
//

import Foundation

public struct GuideDescriptor: Codable {
    public var type: String
    public var description: String
    public var isOptional: Bool = false
    public var validValues: [String]? = nil
    
    public init(type: String, description: String, isOptional: Bool = false, validValues: [String]? = nil) {
        self.type = type
        self.description = description
        self.isOptional = isOptional
        self.validValues = validValues
    }
}
