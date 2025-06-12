//
//  GeneratableProtocolTests.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import Testing
import GeneratableModelSystem

@Test("GeneratableProtocol generates JSON description")
func testGeneratableProtocolJSONDescription() throws {
    let jsonDescription = TripReservation.jsonDescription
    
    #expect(!jsonDescription.isEmpty)
    #expect(jsonDescription.contains("trip_name"))
    #expect(jsonDescription.contains("start_date"))
    #expect(jsonDescription.contains("end_date"))
    #expect(jsonDescription.contains("passengers"))
    
    // Verify it's valid JSON
    let jsonData = jsonDescription.data(using: String.Encoding.utf8)!
    let parsedJSON = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    #expect(parsedJSON.keys.count > 0)
}

@Test("GeneratableProtocol description property works")
func testGeneratableProtocolDescription() {
    #expect(TripReservation.description == "Trip reservation appointment")
    #expect(TripPlan.description == "User trip plan")
}

@Test("GeneratableProtocol scheme property contains correct attributes")
func testGeneratableProtocolScheme() {
    let scheme = TripReservation.scheme
    
    #expect(scheme.count == 4) // tripName, startDate, endDate, passengers (id excluded)
    #expect(scheme["id"] == nil) // id not included since it has default value
    #expect(scheme["trip_name"] != nil)
    #expect(scheme["start_date"] != nil)
    #expect(scheme["end_date"] != nil)
    #expect(scheme["passengers"] != nil)
    
    // Test optional attribute
    #expect(scheme["passengers"]?.isOptional == true)
}

@Test("TripPlan GeneratableProtocol conformance")
func testTripPlanGeneratableProtocol() {
    let scheme = TripPlan.scheme
    
    #expect(scheme.count == 3)
    #expect(scheme["destination"]?.type == "string")
    #expect(scheme["activities"]?.type == "array of strings")
    #expect(scheme["duration"]?.type == "integer")
}