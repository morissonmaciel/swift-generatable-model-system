# Generatable Model System

A structured and type-safe Swift library for communicating with large language models. Provides Language Model Sessions and type-safe structures whose JSON descriptions are used in prompts to ensure structured response types.

## Overview

This library enables type-safe communication with large language models by:

- **Structured Language Model Sessions** - Type-safe session management for LLM interactions
- **Generatable Models** - Swift types that automatically generate JSON Schema descriptions
- **Type Safety** - Compile-time guarantees for LLM request/response structures
- **JSON Schema Generation** - Automatic conversion of Swift types to JSON Schema for prompt engineering

### Core Components

- `@Generatable` - Macro that automatically generates GeneratableProtocol conformance, Codable support, and JSON Schema
- `@GeneratableGuide` - Marks properties for inclusion in schema with descriptions and custom names
- `LanguageModelSession` - Structured session management for LLM communications with default provider support
- `LanguageModelProvider` - Abstraction layer for different LLM providers

## Usage

The library provides powerful macros that automatically generate JSON Schema from your Swift types with zero boilerplate.

### Level 1: Basic Struct with @Generatable

```swift
@Generatable("User profile information")
struct UserProfile {
    var id: UUID = UUID()  // Properties without @GeneratableGuide need default values
    
    @GeneratableGuide("Full name")
    var name: String
    
    @GeneratableGuide("Email address")  
    var email: String
    
    @GeneratableGuide("Account status")
    var isActive: Bool
}

// ✨ Automatically generates:
// - GeneratableProtocol conformance + Codable support
// - static var description = "User profile information"
// - static var scheme with all property descriptors
// - CodingKeys enum (when custom names are used)
```

### Level 2: Optional Properties and Custom Names

```swift
@Generatable("Trip reservation appointment")
struct TripReservation {
    var id: UUID = UUID()  // Auto-generated, not included in schema
    
    @GeneratableGuide("Trip user friendly name", name: "trip_name")
    var tripName: String
    
    @GeneratableGuide("Start date in UTC format", name: "start_date") 
    var startDate: Date
    
    @GeneratableGuide("Number of passengers")
    var passengers: Int? = 0  // Optional with default value
}

// ✨ Automatically generates CodingKeys enum for custom names:
// enum CodingKeys: String, CodingKey {
//     case id, tripName = "trip_name", startDate = "start_date", passengers
// }
// ✨ Correctly handles optional properties
```

### Level 3: Arrays and Complex Types

```swift
@Generatable("User trip plan")
struct TripPlan {
    @GeneratableGuide("Country destination of user trip")
    var destination: Destination  // Custom enum (must be CaseIterable)
    
    @GeneratableGuide("List of activities planned for user trip")
    var activities: [String] = []  // Array with default
    
    @GeneratableGuide("Duration of user trip in days")
    var duration: Int
}

// ✨ Automatically detects:
// - Array types → "array of strings"
// - Enum types → validates CaseIterable conformance at compile time
```

### Level 4: Enum Validation with CaseIterable

```swift
enum Destination: String, Codable, CaseIterable {  // ⚠️ CaseIterable is REQUIRED
    case japan = "Japan"
    case brazil = "Brazil"
}

// ✨ The macro automatically:
// - Validates enum conforms to CaseIterable at compile time
// - Generates validValues: ["Japan", "Brazil"] from raw values
// - Creates proper JSON Schema constraints for LLM guidance

// ❌ This will cause a compilation error:
enum InvalidDestination: String, Codable {  // Missing CaseIterable
    case paris = "Paris"
}
```

### Level 5: Type-Safe Language Model Communication

```swift
// Set up a default provider (optional - for convenience)
LanguageModelSession.defaultProvider = MyLanguageModelProvider()

// Create a language model session (using default provider)
let session = LanguageModelSession("gpt-4") {
    "You are a helpful assistant that generates structured data."
}

// Or with explicit provider
let session2 = LanguageModelSession("claude-3", provider: customProvider)

// The macro automatically generates JSON Schema
let schema = UserProfile.scheme

// Type-safe request with structured response
let response: UserProfile = try await session.generate(
    prompt: "Generate a user profile for a software developer",
    responseType: UserProfile.self
)

// ✨ Zero boilerplate - the macro handles everything!
```

### Level 6: Complex Nested Structures

```swift
@Generatable("Complete travel booking request")
struct BookingRequest {
    @GeneratableGuide("Primary traveler information")
    var traveler: UserProfile  // Nested generatable struct
    
    @GeneratableGuide("Trip reservation details")
    var reservation: TripReservation  // Another generatable struct
    
    @GeneratableGuide("Payment method", name: "payment_method")
    var paymentMethod: PaymentType  // CaseIterable enum
    
    @GeneratableGuide("Special requests or notes")
    var notes: String? = nil  // Optional with no default
}

// ✨ Macro automatically handles:
// - Nested generatable structs
// - Multiple custom names → CodingKeys enum generation
// - Mixed optional/required properties
// - Enum validation chains (all must be CaseIterable)
// - Full Codable conformance
```

## Built-in Type Support

The `@Generatable` macro automatically maps Swift types to JSON Schema:

### Basic Types
- `String` → `"string"`
- `Int`, `Int32`, `Int64` → `"integer"`
- `Double`, `Float` → `"number"`
- `Bool` → `"boolean"`
- `Date` → `"string"` (ISO 8601 format)
- `UUID` → `"string"` (UUID format)

### Complex Types
- `Array<T>` → `"array of {T}s"` (e.g., `[String]` → `"array of strings"`)
- `Optional<T>` → Sets `isOptional: true` in GuideDescriptor
- **Custom Enums** → `"string"` with `validValues: [...]` (⚠️ **REQUIRES** `CaseIterable`)

### Type Safety Features
- ✅ **Compile-time validation** - Properties without `@GeneratableGuide` must have default values
- ✅ **Enum validation** - Custom enums **must** conform to `CaseIterable` (compilation error if not)
- ✅ **Optional detection** - Automatically detects `?` and default values
- ✅ **Custom naming** - JSON keys can differ from Swift property names
- ✅ **Auto CodingKeys** - Automatically generates `CodingKeys` enum when custom names are used
- ✅ **Auto Codable** - Automatically adds `Codable` conformance to `@Generatable` structs

## Important Requirements & Features

### 🚨 CaseIterable Requirement for Enums
When using custom enums with `@GeneratableGuide`, they **MUST** conform to `CaseIterable`:

```swift
// ✅ Correct - will work
enum Status: String, Codable, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
}

// ❌ Will cause compilation error
enum Status: String, Codable {  // Missing CaseIterable
    case active = "Active"
    case inactive = "Inactive"
}
```

### 🔧 Automatic CodingKeys Generation
The macro automatically generates `CodingKeys` enum when custom names are used:

```swift
@Generatable("Example")
struct Example {
    @GeneratableGuide("Field one", name: "field_one")
    var fieldOne: String
    
    @GeneratableGuide("Field two", name: "field_two") 
    var fieldTwo: Int
}

// ✨ Auto-generates:
// enum CodingKeys: String, CodingKey {
//     case fieldOne = "field_one"
//     case fieldTwo = "field_two"
// }
```

### 📋 Property Requirements
Properties in `@Generatable` structs must either:
1. Have `@GeneratableGuide` annotation, OR
2. Have a default value

```swift
@Generatable("Example")
struct Example {
    var id: UUID = UUID()           // ✅ Has default value
    var timestamp = Date()          // ✅ Has default value
    
    @GeneratableGuide("User name")
    var name: String                // ✅ Has @GeneratableGuide
    
    var email: String              // ❌ Compilation error - needs @GeneratableGuide or default
}
```

## ManualSchemaBuilder API

### Adding Properties

```swift
// Required property
builder.addProperty("name", type: String.self, description: "Property description")

// Optional property  
builder.addOptionalProperty("age", wrappedType: Int.self, description: "Optional age")

// Array property
builder.addArrayProperty("tags", itemType: String.self, description: "List of tags")

// Set overall description
builder.setDescription("Overall model description")
```

### Building Schema

```swift
let schema = builder.build()
// Returns: [String: Any] dictionary in JSON Schema format
```

## Integration with Existing Models

The system integrates with existing codebase models:

```swift
// ChatRole enum
extension ChatRole: GeneratableModel {
    static func generateSchema() -> [String: Any] {
        return SchemaGenerator.schemaForEnum(
            cases: ["user", "assistant", "system", "tool"],
            description: "Chat message role"
        )
    }
}

// StructuredChatResponse struct  
extension StructuredChatResponse: GeneratableModel {
    static func generateSchema() -> [String: Any] {
        // Uses ManualSchemaBuilder for complex structures
    }
}
```

## ✨ Production-Ready Swift Macro Implementation

The system now uses **true Swift macros** for automatic code generation:

```swift
@Generatable("User profile information")
struct UserProfile {
    var id: UUID = UUID()  // Auto-generated, excluded from schema
    
    @GeneratableGuide("Full name of the user")
    var name: String
    
    @GeneratableGuide("Email address")
    var email: String
}

// ✨ The macro automatically generates:
// - GeneratableProtocol conformance
// - Codable conformance  
// - CodingKeys enum (when needed)
// - JSON Schema generation
// - Compile-time validation
```

**All code generation happens at compile time** with full type safety and validation.

## Files Structure

```
Sources/
├── GeneratableModelSystem/            # Core library
│   ├── GeneratableProtocol.swift      # Core protocol
│   ├── GuideDescriptor.swift          # Schema descriptor model
│   ├── LanguageModel.swift            # Language model abstraction
│   ├── LanguageModelProvider.swift    # Provider protocol
│   ├── LanguageModelSession.swift     # Session management
│   └── PromptBuilder.swift            # Prompt building utilities
├── GeneratableModelSystemMacros/      # Macro definitions
│   └── GeneratableModelSystemMacros.swift
└── GeneratableModelSystemMacrosPlugin/ # Macro implementation
    ├── GeneratableMacro.swift          # Main @Generatable macro
    ├── GeneratableGuideMacro.swift     # @GeneratableGuide macro
    └── GeneratableModelSystemMacrosPlugin.swift

Tests/
└── GeneratableModelSystemMacrosTests/ # Comprehensive test suite
    ├── GeneratableMacroTests.swift     # Macro functionality tests
    ├── GuideDescriptorTests.swift      # Model tests
    ├── LanguageModelSessionTests.swift # Session tests
    └── TestModels.swift                # Test data models
```