//
//  GeneratableMacroTests.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import Testing
import GeneratableModelSystem
import GeneratableModelSystemMacros

@Test("TripReservation @Generatable macro synthesizes description property")
func testTripReservationGeneratableMacroDescription() {
    #expect(TripReservation.description == "Trip reservation appointment")
}

@Test("TripReservation @Generatable macro synthesizes scheme property")
func testTripReservationGeneratableMacroScheme() {
    let scheme = TripReservation.scheme
    #expect(scheme.keys.count == 4) // tripName, startDate, endDate, passengers (id excluded)
    
    // Verify properties exist with correct keys
    #expect(scheme["id"] == nil) // id not included since it has default value
    #expect(scheme["trip_name"] != nil) // Custom name
    #expect(scheme["start_date"] != nil) // Custom name
    #expect(scheme["end_date"] != nil) // Custom name
    #expect(scheme["passengers"] != nil)
}

@Test("TripReservation @Generatable macro enables JSON description")
func testTripReservationGeneratableMacroJSONDescription() {
    let jsonDescription = TripReservation.jsonDescription
    #expect(!jsonDescription.isEmpty)
    #expect(!jsonDescription.contains("Unique trip identifier")) // id excluded
    #expect(jsonDescription.contains("trip_name"))
}

@Test("TripReservation scheme contains correct guide descriptors")
func testTripReservationSchemeAttributeDescriptors() {
    let scheme = TripReservation.scheme
    
    // Check that id attribute is not included (has default value)
    #expect(scheme["id"] == nil)
    
    // Check trip_name attribute (custom name)
    if let tripNameAttr = scheme["trip_name"] {
        #expect(tripNameAttr.type == "string")
        #expect(tripNameAttr.description == "Trip user friendly name")
        #expect(tripNameAttr.isOptional == false)
    }
    
    // Check passengers attribute (optional)
    if let passengersAttr = scheme["passengers"] {
        #expect(passengersAttr.type == "integer")
        #expect(passengersAttr.description == "Number of passengers")
        #expect(passengersAttr.isOptional == true)
    }
}

@Test("TripPlan @Generatable macro synthesizes description property")
func testTripPlanGeneratableMacroDescription() {
    #expect(TripPlan.description == "User trip plan")
}

@Test("TripPlan @Generatable macro synthesizes scheme property")
func testTripPlanGeneratableMacroScheme() {
    let scheme = TripPlan.scheme
    #expect(scheme.keys.count == 3) // destination, activities, duration
    
    // Verify properties exist
    #expect(scheme["destination"] != nil)
    #expect(scheme["activities"] != nil)
    #expect(scheme["duration"] != nil)
}

@Test("TripPlan scheme contains correct guide descriptors")
func testTripPlanSchemeAttributeDescriptors() {
    let scheme = TripPlan.scheme
    
    // Check destination attribute (enum with validValues)
    if let destinationAttr = scheme["destination"] {
        #expect(destinationAttr.type == "string")
        #expect(destinationAttr.description == "Country destination of user trip")
        #expect(destinationAttr.isOptional == false)
        #expect(destinationAttr.validValues == ["Japan", "Brazil"])
    }
    
    // Check activities attribute (array)
    if let activitiesAttr = scheme["activities"] {
        #expect(activitiesAttr.type == "array of strings")
        #expect(activitiesAttr.description == "List of activities planned for user trip")
        #expect(activitiesAttr.isOptional == false)
    }
    
    // Check duration attribute
    if let durationAttr = scheme["duration"] {
        #expect(durationAttr.type == "integer")
        #expect(durationAttr.description == "Duration of user trip in days")
        #expect(durationAttr.isOptional == false)
    }
}

@Test("TripPlan @Generatable macro enables JSON description")
func testTripPlanGeneratableMacroJSONDescription() {
    let jsonDescription = TripPlan.jsonDescription
    #expect(!jsonDescription.isEmpty)
    #expect(jsonDescription.contains("Country destination"))
    #expect(jsonDescription.contains("activities"))
}

@Test("Both models conform to GeneratableProtocol")
func testGeneratableProtocolConformance() {
    #expect(TripReservation.self is GeneratableProtocol.Type)
    #expect(TripPlan.self is GeneratableProtocol.Type)
}

@Test("JSON descriptions are valid JSON format")
func testJSONDescriptionsAreValidJSON() {
    let tripReservationJSON = TripReservation.jsonDescription
    let tripPlanJSON = TripPlan.jsonDescription
    
    // Test that JSON descriptions can be parsed
    #expect(Data(tripReservationJSON.utf8) != nil)
    #expect(Data(tripPlanJSON.utf8) != nil)
    
    // Try to parse as JSON
    do {
        _ = try JSONSerialization.jsonObject(with: Data(tripReservationJSON.utf8), options: [])
        _ = try JSONSerialization.jsonObject(with: Data(tripPlanJSON.utf8), options: [])
    } catch {
        #expect(Bool(false), "JSON descriptions should be valid JSON")
    }
}