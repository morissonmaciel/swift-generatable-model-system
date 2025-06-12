# swift-generatable-model-system.
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

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/morissonmaciel/swift-generatable-model-system.git", branch: "main")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "GeneratableModelSystem", package: "swift-generatable-model-system"),
        .product(name: "GeneratableModelSystemMacros", package: "swift-generatable-model-system")
    ]
)
```

## Requirements

- Swift 5.9 or higher
- macOS 14.0+ / iOS 17.0+
- Xcode 15.0+

## Building

1. Clone the repository
```bash
git clone https://github.com/morissonmaciel/swift-generatable-model-system.git
cd swift-generatable-model-system
```

2. Build the package
```bash
swift build
```

Note: The following files are generated during build and should not be committed:
- `.build/` - Build artifacts
- `.swiftpm/` - Swift Package Manager data
- `*.xcodeproj` - Xcode project files
- `Package.pins` - Package version pins

## Running Tests

Run the test suite using:
```bash
swift test
```

For more detailed test output:
```bash
swift test --verbose
```


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
// Set up default providers (optional - for convenience)
LanguageModelSession.defaultProvider = MyLanguageModelProvider()
LanguageModelSession.defaultURLSession = customURLSession // Optional custom session

// Create a language model session
var session = LanguageModelSession("gpt-4") {
    "You are a helpful assistant that generates structured data."
}

// Option 1: Set provider and URLSession via properties
session.provider = myProvider
session.urlSession = myURLSession

// Option 2: Use default providers (if set)
// session will automatically fallback to LanguageModelSession.defaultProvider
// and LanguageModelSession.defaultURLSession (or .shared if nil)

// The macro automatically generates JSON Schema
let schema = UserProfile.scheme

// Type-safe request with structured JSON response
let response: UserProfile = try await session.respond(to: "Generate a user profile for a software developer")

// Raw text generation (no JSON parsing)
let rawText: String = try await session.generate(to: "Tell me a joke")

// ✨ Zero boilerplate - the macro handles everything!
```

### Level 6: Streaming Partial Generation

The `@Generatable` macro automatically generates a `PartiallyGenerated` type for each struct, enabling real-time streaming updates:

```swift
@Generatable("Trip planning information")
struct TripPlan {
    @GeneratableGuide("Destination country")
    var destination: String
    
    @GeneratableGuide("List of planned activities")
    var activities: [String]
    
    @GeneratableGuide("Trip duration in days")
    var duration: Int
}

// ✨ The macro automatically generates TripPlan.PartiallyGenerated:
// struct PartiallyGenerated: PartiallyGeneratedProtocol {
//     var destination: String?      // All @GeneratableGuide properties become optional
//     var activities: [String]?
//     var duration: Int?
// }

// Stream partial updates as they're generated
for await partialPlan in session.respondPartially(to: "Create a detailed trip plan for Japan") {
    if let plan = partialPlan as TripPlan.PartiallyGenerated? {
        // Handle incremental updates in real-time
        if let destination = plan.destination {
            print("🌍 Destination: \(destination)")
        }
        if let activities = plan.activities, !activities.isEmpty {
            print("🎯 Activities so far: \(activities.joined(separator: ", "))")
        }
        if let duration = plan.duration {
            print("📅 Duration: \(duration) days")
        }
    }
}

// Enable text fragment streaming for even more granular updates
for await partialPlan in session.respondPartially(to: "Create a trip plan", allowsTextFragment: true) {
    if let plan = partialPlan as TripPlan.PartiallyGenerated? {
        // Now you can see text as it's being generated character by character
        if let destination = plan.destination {
            print("🌍 Destination: \(destination)") // Shows "J" → "Ja" → "Jap" → "Japan"
        }
    }
}
```

**Partial Generation Features:**
- ✅ **Real-time streaming** - Get updates as the LLM generates content
- ✅ **Type safety** - Partial types maintain full compile-time checking
- ✅ **Optional properties** - All `@GeneratableGuide` fields become optional
- ✅ **Automatic generation** - Zero additional code required
- ✅ **Incremental parsing** - Handles incomplete JSON gracefully
- ✅ **Text fragment streaming** - See text being generated character by character with `allowsTextFragment: true`
- ✅ **Type validation** - Text fragments only applied to String-type properties
- ✅ **AsyncStream support** - Full Swift concurrency integration

### Level 7: Complex Nested Structures

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

## Configuration

### Setting Up Language Model Provider

Before using the library, configure your language model provider:

```swift
// Create your custom provider implementing LanguageModelProvider
class MyLanguageModelProvider: LanguageModelProvider {
    var api: LanguageModelProviderAPI { .openAI }
    var address: URL { URL(string: "https://api.openai.com")! }
    var apiKey: String { "your-api-key" }
    
    // Optional: Custom URLSession factory
    func makeURLSession() -> URLSession {
        return URLSession.shared
    }
}

// Set as default provider (optional)
LanguageModelSession.defaultProvider = MyLanguageModelProvider()
LanguageModelSession.defaultURLSession = customURLSession // Optional
```

### Basic Configuration

1. Import the library:
```swift
import GeneratableModelSystem
import GeneratableModelSystemMacros
```

2. Create your models using the @Generatable macro:
```swift
@Generatable("User profile")
struct UserProfile {
    @GeneratableGuide("User's full name")
    var name: String
    
    @GeneratableGuide("Email address")
    var email: String
}
```

3. Initialize a language model session:
```swift
var session = LanguageModelSession("gpt-4") {
    "You are a helpful assistant that generates structured data."
}

// Set provider via properties (recommended)
session.provider = myProvider
session.urlSession = myURLSession // Optional
```

4. Generate responses:
```swift
// Structured JSON response
let profile: UserProfile = try await session.respond(to: "Generate a profile for a software developer")

// Raw text response  
let rawResponse: String = try await session.generate(to: "Tell me about Swift programming")
```

## LanguageModelSession API

The `LanguageModelSession` provides three main methods for interacting with language models:

### respond(to:) - Structured JSON Response

Returns a strongly-typed response by parsing JSON from the LLM output:

```swift
// Simple string input
let response: UserProfile = try await session.respond(to: "Generate a user profile")

// With PromptBuilder
let response: UserProfile = try await session.respond {
    "Generate a user profile for a \(profession) from \(country)"
}
```

**Features:**
- ✅ Automatic JSON extraction from LLM response (handles markdown code blocks)
- ✅ Strong typing with compile-time safety
- ✅ Automatic Codable decoding to your struct
- ✅ Throws `LanguageModelSessionError` on parsing failures

### respondPartially(to:) - Streaming Partial Response

Returns an AsyncStream of partial responses as they're generated:

```swift
// Stream partial updates
for await partialResponse in session.respondPartially(to: "Generate a trip plan") {
    if let plan = partialResponse as TripPlan.PartiallyGenerated? {
        // Handle real-time updates
        if let destination = plan.destination {
            print("Destination updated: \(destination)")
        }
    }
}

// Enable text fragment streaming for character-by-character updates
for await partialResponse in session.respondPartially(to: "Generate a trip plan", allowsTextFragment: true) {
    if let plan = partialResponse as TripPlan.PartiallyGenerated? {
        // See text being generated in real-time: "J" → "Ja" → "Jap" → "Japan"
        if let destination = plan.destination {
            print("Destination: \(destination)")
        }
    }
}

// With PromptBuilder
for await partialResponse in session.respondPartially(allowsTextFragment: true) {
    "Generate a detailed trip plan for \(destination) with \(activities.count) activities"
} {
    // Handle streaming updates with text fragments
}
```

**Features:**
- ✅ Real-time streaming of partial responses
- ✅ Type-safe partial generation with optional properties
- ✅ **Text fragment streaming** with `allowsTextFragment: true` parameter
- ✅ **Character-by-character updates** for String properties only
- ✅ AsyncStream integration for Swift concurrency
- ✅ Incremental JSON parsing for incomplete data
- ✅ Same error handling and provider support

### generate(to:) - Raw Text Response

Returns the raw text response without any JSON parsing:

```swift
// Simple string input
let rawText: String = try await session.generate(to: "Tell me a joke")

// With PromptBuilder  
let rawText: String = try await session.generate {
    "Write a story about \(character) in \(setting)"
}
```

**Features:**
- ✅ Returns unprocessed LLM response text
- ✅ No JSON parsing or structure validation
- ✅ Useful for creative writing, explanations, or non-structured output
- ✅ Same error handling for network/provider issues

### Provider and URLSession Configuration

All methods support flexible configuration:

```swift
var session = LanguageModelSession("model-name")

// Option 1: Instance-level configuration
session.provider = myProvider
session.urlSession = myURLSession

// Option 2: Use static defaults
LanguageModelSession.defaultProvider = myProvider
LanguageModelSession.defaultURLSession = myURLSession

// Option 3: Mixed approach
session.provider = myProvider  // Instance-specific provider
// Uses LanguageModelSession.defaultURLSession or .shared as fallback
```

**Fallback Order:**
1. Instance `session.provider` → Static `LanguageModelSession.defaultProvider` → Throws error
2. Instance `session.urlSession` → Static `LanguageModelSession.defaultURLSession` → `URLSession.shared`

### Error Handling

All methods throw `LanguageModelSessionError`:

```swift
do {
    let response: UserProfile = try await session.respond(to: "Generate profile")
} catch LanguageModelSessionError.noDefaultProviderSet {
    // No provider configured
} catch LanguageModelSessionError.invalidResponseStatusCode {
    // HTTP error from LLM provider
} catch LanguageModelSessionError.invalidResponseFormat(let content) {
    // JSON parsing failed (respond only)
} catch LanguageModelSessionError.invalidResponseData {
    // Data conversion failed
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
