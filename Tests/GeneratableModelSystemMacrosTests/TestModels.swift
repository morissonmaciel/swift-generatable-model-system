//
//  TestModels.swift
//  GeneratableModelSystemMacrosTests
//
//  Created by Morisson Marcel on 12/06/25.
//

import Foundation
import GeneratableModelSystem
import GeneratableModelSystemMacros

// Test models extracted from playground files

enum Destination: String, Codable, CaseIterable {
    case japan = "Japan"
    case brazil = "Brazil"
}

@Generatable("Trip reservation appointment")
struct TripReservation {
    var id: UUID = UUID()
    
    @GeneratableGuide("Trip user friendly name", name: "trip_name")
    var tripName: String
    
    @GeneratableGuide("Start date in UTC format", name: "start_date") 
    var startDate: Date
    
    @GeneratableGuide("End date in UTC format", name: "end_date")
    var endDate: Date
    
    @GeneratableGuide("Number of passengers")
    var passengers: Int? = 0
}

@Generatable("User trip plan")
struct TripPlan {
    @GeneratableGuide("Country destination of user trip")
    var destination: Destination
    
    @GeneratableGuide("List of activities planned for user trip")
    var activities: [String] = []
    
    @GeneratableGuide("Duration of user trip in days")
    var duration: Int
}