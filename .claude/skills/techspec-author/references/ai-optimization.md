# AI Optimization Patterns

Writing patterns that maximize AI agent effectiveness when implementing from specs.

## Core Principles

### 1. Self-Contained Sections

Each section must be understandable without reading other sections.

**Bad**:
```markdown
## User Model
See the configuration section for the fields.

## Configuration
Uses the same validation as User Model.
```

**Good**:
```markdown
## User Model

```dart
class User {
  final String id;      // UUID v4 format
  final String email;   // Valid email, max 255 chars
  final String name;    // Non-empty, max 100 chars
}
```

Validation rules:
- `id`: Must be valid UUID v4
- `email`: Must match RFC 5322, max 255 characters
- `name`: Non-empty string, max 100 characters
```

### 2. Complete Code Examples

Include imports, configuration, and all context needed to run.

**Bad**:
```dart
final result = processor.process(data);
```

**Good**:
```dart
import 'package:my_package/my_package.dart';

void main() {
  final processor = DataProcessor(
    config: ProcessorConfig(
      timeout: Duration(seconds: 30),
      retryCount: 3,
    ),
  );

  final data = InputData(values: [1, 2, 3]);
  final result = processor.process(data);

  print(result.summary); // Output: "Processed 3 values"
}
```

### 3. Explicit Contracts

Define inputs, outputs, and error conditions precisely.

**Bad**:
```markdown
The method processes the input and returns results.
Errors should be handled appropriately.
```

**Good**:
```markdown
### process(input)

**Input**: `InputData` with non-empty `values` list
**Output**: `ProcessResult` containing:
  - `summary`: String description
  - `count`: Number of processed items
  - `duration`: Processing time

**Errors**:
| Exception | Condition | Recovery |
|-----------|-----------|----------|
| `EmptyInputException` | `values` is empty | Provide non-empty list |
| `TimeoutException` | Processing > 30s | Increase timeout or reduce input |
| `ProcessingException` | Invalid value type | Ensure all values are `int` |
```

### 4. Structured Data Over Prose

Use tables, lists, and schemas instead of paragraphs.

**Bad**:
```markdown
The configuration accepts several options. You can set the timeout
which defaults to 30 seconds. The retry count can be between 1 and 5,
with a default of 3. Debug mode is off by default but can be enabled
for verbose logging.
```

**Good**:
```markdown
### Configuration Options

| Option | Type | Default | Valid Range | Description |
|--------|------|---------|-------------|-------------|
| timeout | Duration | 30s | 1s - 5min | Request timeout |
| retryCount | int | 3 | 1-5 | Retry attempts |
| debug | bool | false | - | Enable verbose logging |
```

---

## Given/When/Then Format

Use this exact format for all acceptance criteria.

### Format

```markdown
**Acceptance Criteria**:

- GIVEN [precondition/context]
  WHEN [action/trigger]
  THEN [expected outcome]
```

### Examples

**Simple**:
```markdown
- GIVEN a valid email "user@example.com"
  WHEN AuthService.validateEmail() is called
  THEN returns true
```

**With State**:
```markdown
- GIVEN a user with id "123" exists in the database
  AND the user has role "admin"
  WHEN UserService.getPermissions("123") is called
  THEN returns list containing "read", "write", "delete"
```

**Error Case**:
```markdown
- GIVEN a network connection is unavailable
  WHEN ApiClient.fetch() is called
  THEN throws NetworkException with message "No connection"
  AND does not cache the error response
```

**Async**:
```markdown
- GIVEN a slow endpoint that takes 5 seconds to respond
  AND timeout is set to 3 seconds
  WHEN ApiClient.fetch() is called
  THEN throws TimeoutException after 3 seconds
  AND cancels the underlying request
```

---

## Uncertainty Markers

Mark unknowns explicitly so AI agents don't guess.

### Format

```markdown
[NEEDS CLARIFICATION: specific question]
```

### Usage

```markdown
## Error Handling

When the API returns a 429 rate limit error:
- [NEEDS CLARIFICATION: Should we auto-retry with exponential backoff, or immediately throw?]

## Caching Strategy

Cache duration: [NEEDS CLARIFICATION: What TTL is appropriate? 5 minutes? 1 hour?]
```

### Resolution

Once clarified, replace with the answer:

```markdown
## Error Handling

When the API returns a 429 rate limit error:
- Auto-retry with exponential backoff (base 1s, max 3 retries)
- After max retries, throw RateLimitException
```

---

## Good vs Bad Examples

### Requirements

**Bad Requirement**:
```markdown
### Data Validation
The system should validate data properly and show appropriate errors.
```

**Good Requirement**:
```markdown
### REQ-003: Email Validation

**User Story**:
As a developer using this package
I want to validate email addresses
So that I can ensure user input is valid before submission

**Acceptance Criteria**:
- GIVEN an email "user@example.com"
  WHEN Validator.email() is called
  THEN returns ValidationResult.valid

- GIVEN an email "invalid-email"
  WHEN Validator.email() is called
  THEN returns ValidationResult.invalid with error "Invalid email format"

- GIVEN an email longer than 255 characters
  WHEN Validator.email() is called
  THEN returns ValidationResult.invalid with error "Email exceeds maximum length"

- GIVEN an empty string
  WHEN Validator.email() is called
  THEN returns ValidationResult.invalid with error "Email is required"
```

### API Documentation

**Bad API**:
```markdown
### process()
Processes the data and returns results.
```

**Good API**:
```markdown
### process(data, options)

Transforms input data according to specified rules.

```dart
Future<ProcessResult> process(
  InputData data, {
  ProcessOptions? options,
})
```

**Parameters**:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| data | InputData | Yes | Data to process |
| options | ProcessOptions | No | Processing configuration |

**Returns**: `Future<ProcessResult>`

```dart
class ProcessResult {
  final List<OutputItem> items;
  final Duration processingTime;
  final int inputCount;
  final int outputCount;
}
```

**Throws**:

| Exception | When | Contains |
|-----------|------|----------|
| InvalidDataException | data.items is empty | "Input data cannot be empty" |
| ProcessingException | Transformation fails | Original error message |
| TimeoutException | Processing exceeds options.timeout | "Processing timed out after {duration}" |

**Example**:
```dart
final data = InputData(items: [Item(value: 1), Item(value: 2)]);
final options = ProcessOptions(timeout: Duration(seconds: 10));

try {
  final result = await processor.process(data, options: options);
  print('Processed ${result.inputCount} → ${result.outputCount} items');
} on InvalidDataException catch (e) {
  print('Invalid input: ${e.message}');
} on TimeoutException catch (e) {
  print('Timeout: ${e.message}');
}
```
```

---

## Terminology Consistency

Use the same term for the same concept throughout the spec.

### Create a Glossary

```markdown
## Terminology

| Term | Definition | Do NOT Use |
|------|------------|------------|
| User | An authenticated account holder | customer, client, member |
| Session | Active authentication period | login, connection |
| Token | JWT authentication credential | key, secret, auth |
| Refresh | Obtain new token before expiry | renew, extend |
```

### Enforcement

Before using a term, check if it's in the glossary. If not, add it.

---

## JSON Schemas for Data

When specs involve data structures, include JSON schemas.

```markdown
## Configuration Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["apiKey", "environment"],
  "properties": {
    "apiKey": {
      "type": "string",
      "minLength": 32,
      "description": "API authentication key"
    },
    "environment": {
      "type": "string",
      "enum": ["development", "staging", "production"],
      "description": "Target environment"
    },
    "timeout": {
      "type": "integer",
      "minimum": 1000,
      "maximum": 60000,
      "default": 30000,
      "description": "Request timeout in milliseconds"
    }
  }
}
```

**Example Valid Configuration**:
```json
{
  "apiKey": "sk_live_abcdef123456789012345678901234",
  "environment": "production",
  "timeout": 15000
}
```
```

---

## AI-Readability Checklist

Before finalizing a spec, verify:

- [ ] **No Ambiguous Language**: Remove "should", "might", "could", "appropriate"
- [ ] **No Implicit Knowledge**: Explain all domain terms
- [ ] **No Partial Examples**: All code examples are complete and runnable
- [ ] **No Circular References**: Each section stands alone
- [ ] **No Unresolved Questions**: All `[NEEDS CLARIFICATION]` resolved
- [ ] **Consistent Terminology**: Same term = same concept
- [ ] **Structured Data**: Tables/schemas over prose
- [ ] **Explicit Contracts**: All inputs, outputs, errors documented
- [ ] **Given/When/Then**: All acceptance criteria in correct format
- [ ] **Measurable Success**: Every requirement has testable criteria
