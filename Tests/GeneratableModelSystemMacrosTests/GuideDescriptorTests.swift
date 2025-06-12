//
//  GuideDescriptorTests.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import Testing
import GeneratableModelSystem

@Test("GuideDescriptor basic creation")
func testGuideDescriptorCreation() {
    let descriptor = GuideDescriptor(
        type: "string",
        description: "Test description"
    )
    
    #expect(descriptor.type == "string")
    #expect(descriptor.description == "Test description")
    #expect(descriptor.isOptional == false) // Default value
}

@Test("GuideDescriptor with optional parameter")
func testGuideDescriptorOptional() {
    let descriptor = GuideDescriptor(
        type: "integer",
        description: "Optional field",
        isOptional: true
    )
    
    #expect(descriptor.type == "integer")
    #expect(descriptor.description == "Optional field")
    #expect(descriptor.isOptional == true)
}

@Test("GuideDescriptor is Codable")
func testGuideDescriptorCodable() throws {
    let original = GuideDescriptor(
        type: "boolean",
        description: "Test boolean field",
        isOptional: false
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GuideDescriptor.self, from: data)
    
    #expect(decoded.type == original.type)
    #expect(decoded.description == original.description)
    #expect(decoded.isOptional == original.isOptional)
}

@Test("GuideDescriptor supports various types")
func testGuideDescriptorTypes() {
    let stringDescriptor = GuideDescriptor(type: "string", description: "String field")
    let integerDescriptor = GuideDescriptor(type: "integer", description: "Integer field")
    let dateDescriptor = GuideDescriptor(type: "date", description: "Date field")
    let arrayDescriptor = GuideDescriptor(type: "array of strings", description: "Array field")
    
    #expect(stringDescriptor.type == "string")
    #expect(integerDescriptor.type == "integer")
    #expect(dateDescriptor.type == "date")
    #expect(arrayDescriptor.type == "array of strings")
}