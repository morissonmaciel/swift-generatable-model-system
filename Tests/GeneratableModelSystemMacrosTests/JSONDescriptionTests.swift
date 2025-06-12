//
//  JSONDescriptionTests.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import Testing
import GeneratableModelSystem

@Test("JSON description is valid JSON format")
func testJSONDescriptionValidFormat() throws {
    let jsonDescription = TripReservation.jsonDescription
    
    // Should be valid JSON
    let jsonData = jsonDescription.data(using: String.Encoding.utf8)!
    let parsedJSON = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    #expect(parsedJSON.keys.count > 0)
}

@Test("JSON description contains all scheme properties")
func testJSONDescriptionContainsSchemeProperties() throws {
    let jsonDescription = TripReservation.jsonDescription
    let jsonData = jsonDescription.data(using: String.Encoding.utf8)!
    let parsedJSON = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // Check that all scheme keys are present in JSON
    let schemeKeys = Set(TripReservation.scheme.keys)
    let jsonKeys = Set(parsedJSON.keys.compactMap { $0 as? String })
    
    for key in schemeKeys {
        #expect(jsonKeys.contains(key), "JSON should contain scheme key: \(key)")
    }
}

@Test("JSON description formatting is consistent")
func testJSONDescriptionFormatting() {
    let jsonDescription1 = TripReservation.jsonDescription
    let jsonDescription2 = TripReservation.jsonDescription
    
    // Should be consistent between calls
    #expect(jsonDescription1 == jsonDescription2)
    
    // Should be properly formatted (pretty printed)
    #expect(jsonDescription1.contains("\n"))
    #expect(!jsonDescription1.contains("Error"))
}

@Test("TripPlan JSON description structure")
func testTripPlanJSONDescription() throws {
    let jsonDescription = TripPlan.jsonDescription
    let jsonData = jsonDescription.data(using: String.Encoding.utf8)!
    let parsedJSON = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    #expect(parsedJSON["destination"] != nil)
    #expect(parsedJSON["activities"] != nil)
    #expect(parsedJSON["duration"] != nil)
}