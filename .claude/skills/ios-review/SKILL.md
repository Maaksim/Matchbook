---
name: ios-review
description: Review Swift / iOS code and report ONLY actionable issues that must be fixed. Supports file paths, glob patterns, and branch comparisons for PR reviews. No praise, no summaries, no explanations of good code.
argument-hint: "<file-path> | Code review {source-branch} to {target-branch}"
---

Review Swift code and report ONLY issues that must be fixed.

**Input:** `$ARGUMENTS`

## Mode Detection

Detect the mode from the arguments:

### Mode A — File Review

Arguments contain a file path or glob pattern (e.g., `path/to/File.swift`, `Modules/**/*.swift`).

1. Read all matching Swift files
2. Analyze against every rule below
3. Report all violations found

### Mode B — Code Review (Branch Comparison)

Arguments start with `Code review` and contain `to` between two branch names.

Pattern: `Code review {source-branch} to {target-branch}

Examples:
- `Code review feature/login to develop`
- `Code review feature/login to develop
- `Code review feature/player to main

**Steps for Mode B:**

1. **Parse arguments** — extract source branch, target branch
2. **Get changed files** — for each applicable repo, run:
   ```bash
   cd <repo-path> && git diff --name-only --diff-filter=ACMR <target-branch>...<source-branch> -- '*.swift'
   ```
   If a branch doesn't exist in a repo, skip that repo silently.
3. **Get the diff** — for each repo with changes:
   ```bash
   cd <repo-path> && git diff <target-branch>...<source-branch> -- '*.swift'
   ```
4. **Read and review** — for each changed file:
   - Read the **full file** from the working tree (not just the diff)
   - **Focus on changed/added lines and their immediate context** (the function or type containing the change)
   - Apply ALL rules below to changed code and its surrounding context
   - Do NOT report pre-existing issues in unchanged code unless they directly interact with the changes

## Output Format

Every issue MUST include a **Before / After** code snippet when a concrete fix exists.
- **Before**: the actual code from the file (copy exact lines)
- **After**: the corrected version

Omit Before / After only when the fix is purely structural (e.g., "split this class into two files") and cannot be shown as a short snippet.

### Mode A — File Review

````
### {path/to/file.swift} (N issues)

[SEVERITY] Issue Title
Line: NN
Problem: Short explanation of what is wrong.
Fix: Concrete recommendation on how to fix the issue.

Before:
```swift
// exact code from the file
```

After:
```swift
// corrected code
```
````

### Mode B — Code Review

````
# Code Review: {source-branch} → {target-branch}

## {repo-name}

### {path/to/file.swift} (N issues)

[SEVERITY] Issue Title
Line: NN
Problem: Short explanation of what is wrong.
Fix: Concrete recommendation on how to fix the issue.

Before:
```swift
// exact code from the file
```

After:
```swift
// corrected code
```

---

## Summary
- Files reviewed: N
- Issues found: N (X critical, Y high, Z medium, W low)
````

### Common Rules

- Group issues by file, then by severity (CRITICAL first)
- Every issue with a concrete fix MUST show Before / After code snippets
- Before snippet: copy the exact lines from the source file
- After snippet: show the corrected version, ready to paste
- Keep snippets focused — include only the relevant lines (± a few lines of context), not entire functions
- If a file has no issues, do not list it
- If no issues are found at all, output: "No issues found."
- Do NOT output praise, summaries, or explanations of good code

## Severity Levels

- **CRITICAL** — security risks, crashes, memory leaks, threading issues
- **HIGH** — architectural violations, strong maintainability problems
- **MEDIUM** — best practice violations
- **LOW** — style, readability, minor improvements

## Constraints

- Target: **Swift 6** codebase (iOS 17+)
- Respect the project architecture defined in CLAUDE.md

---

## Rules

### 1. Code Structure Order

The order of elements inside a class/struct must be:
1. Properties
2. Initializers
3. Public functions
4. Internal functions
5. Private functions
6. Extensions (protocol conformances separated into extensions)

Report when this order is violated.

### 2. Xcode Warnings

Detect any potential Xcode warnings:
- Unused variables or constants
- Unused imports
- Unreachable code
- Redundant casts or type annotations
- Deprecated API usage
- Unused function results (missing `@discardableResult` or `_ =`)
- Redundant protocol conformances
- Ambiguous references

### 3. Streamlined Code

Detect unnecessary or redundant code:
- Unused imports
- Unused variables, properties, or functions
- Commented-out code blocks (more than 2 lines)
- Default template code that serves no purpose
- Unnecessary framework imports (e.g., `import UIKit` when only `import Foundation` is needed)
- Empty method bodies that do nothing

### 4. Typos

Check spelling in:
- Comments
- Variable / function / type names
- Documentation strings
- User-facing strings

Report as LOW unless the typo causes ambiguity or confusion.

### 5. Deprecated APIs

Detect deprecated Apple APIs or frameworks. Recommend the modern replacement.

Examples:
- `UIWebView` → `WKWebView`
- `UIAlertView` → `UIAlertController`
- `UISearchDisplayController` → `UISearchController`
- Deprecated SwiftUI modifiers (check against deployment target iOS 17+)

### 6. Encapsulation and Access Control

- Properties should be `private` whenever possible
- Mutable state exposed externally should use `private(set)`
- Do not write `internal` explicitly unless required for disambiguation
- Published properties in ViewModels: use `@Published private(set)` when only the ViewModel should mutate
- Protocols must not expose more than necessary

### 7. Hardcoded Values

Detect hardcoded:
- UI spacing / padding / sizing values (should use `SizeConstants` or equivalent)
- Colors (should use named colors from asset catalog or `Color.clm*` constants)
- Font sizes (should use typography constants)
- Duration values (animation, delay)
- Repeated string/numeric literals
- API paths or URLs

Constants should live in a constants enum or configuration. Strings must be localized.

### 8. Localization

All user-facing strings must be localized via `LocalizationUtility` or equivalent.

```swift
// BAD
Text("Welcome")
label.text = "Loading..."

// GOOD
Text(Localization.welcome)
label.text = localizationUtility.localized(.loading)
```

### 9. DispatchQueue.main.asyncAfter

Every `DispatchQueue.main.asyncAfter` call MUST have a comment explaining WHY the delay is needed. If missing, report as MEDIUM.

### 10. Static Constants vs Computed Properties

Prefer `static let` over `static var` with a getter when the value is constant.

```swift
// BAD
static var timeout: Int { return 30 }

// GOOD
static let timeout: Int = 30
```

Exception: computed properties that depend on other values are fine.

### 11. Enumerations Over Long Conditionals

If an if-else chain has 3+ branches for the same decision, recommend:
- Using an `enum` with a `switch`
- Or refactoring into a strategy/lookup pattern

### 12. Deeply Nested Structures

Flag nesting deeper than 3 levels (nested ifs, loops, closures). Recommend:
- Early returns via `guard`
- Extracting inner logic into separate functions

### 13. Force Unwrapping

Any use of `!` (force unwrap) is a red flag. Report as:
- **CRITICAL** if it can crash at runtime (optionals from API, collections, user input)
- **MEDIUM** if arguably safe but should still use safe unwrapping

Prefer: `guard let`, `if let`, `??`, optional chaining.

Exception: `IBOutlet` force unwraps and `fatalError` in `required init?(coder:)` are acceptable.

### 14. Polymorphism and Class Design

- Classes that are not subclassed should be marked `final`
- Prefer `static` over `class` for methods/properties unless override is intended
- Favor composition over inheritance
- Use protocols to define abstractions

### 15. Single Responsibility

- Functions longer than ~40 lines likely do too much — recommend splitting
- Classes with 500+ lines may have too many responsibilities
- Views containing networking or business logic violate separation of concerns
- ViewModels containing UI layout code violate separation of concerns

### 16. Multithreading

- UI updates (`@Published`, UIKit view mutations) must happen on the main thread
- Use `.receive(on: DispatchQueue.main)` before `.sink` that updates UI state
- Background work should not block the main thread
- Check for `DispatchQueue.main.sync` called from the main thread (deadlock)

### 17. Memory Management

- Closures must capture `[weak self]` when stored or escaping (Combine `.sink`, completion handlers, notification observers)
- Use `guard let self else { return }` after weak capture (not `guard let self = self`)
- Delegates must be declared `weak`
- Detect retain cycles: object A holds B, B holds A without weak
- `unowned` should be avoided unless the lifetime relationship is guaranteed

### 18. Security

- Hardcoded tokens, API keys, or secrets
- Sensitive data logged via `print()` or `NSLog()`
- Insecure data storage (plain `UserDefaults` for sensitive data)
- Unsafe URL construction from user input without validation

### 19. Naming Conventions

- Booleans: must start with `is`, `has`, `can`, `should`, `will`, or `did`
- Types/protocols: `UpperCamelCase`
- Variables/functions: `lowerCamelCase`
- Prefer descriptive names over abbreviations (`viewController` not `vc`, `button` not `btn`)
- Follow project naming conventions from CLAUDE.md (Assembly, Router, ViewModel, UseCase, etc.)

### 20. Duplicate Code

Detect duplicated logic (3+ lines repeated 2+ times). Recommend extracting into:
- Functions or methods
- Extensions
- Helpers or utilities

### 21. Unnecessary Code

- Commented-out code blocks → remove
- Unused variables / properties / functions → remove
- Unused imports → remove
- Empty code blocks (empty `catch {}`, empty `else {}`) → handle or remove
- Explicit default `init()` on structs that don't customize it → remove
- Redundant `return` in single-expression bodies → remove

### 22. Potential Crashes

- Array/collection access without bounds checking (e.g., `array[index]` without guard)
- Forced unwrapping (see Rule 13)
- Forced casting (`as!`) without safety check
- Unhandled `nil` from `Dictionary` subscript in critical paths
- Division by zero potential
- Index-based access on potentially empty collections

### 23. API Response Parsing

- Use `Decodable` for response models
- Use `Encodable` for request models
- Use `Codable` only when both encoding and decoding are needed
- Do not parse raw dictionaries (`[String: Any]`) — use typed models
- Follow project patterns: `KalturaRequestEntityProtocol`, `KalturaResponse<T>`

### 24. Architecture and Design

**Separation of Concerns**:
- Views: UI only (no networking, no business logic)
- ViewModels: presentation logic, state management
- UseCases: business logic
- Routers: navigation
- Services/DataLoaders: data access

**Protocol-Oriented**:
- Dependencies should be injected via protocols
- Protocol conformance should be in extensions when possible
- Follow the Assembly/Router/View+ViewModel module pattern

### 25. Combine Patterns (Project-Specific)

- Store subscriptions in `private var cancellables: Set<AnyCancellable> = []`
- Always `.store(in: &cancellables)` — never let subscriptions float
- Use `[weak self]` in `.sink` closures
- Prefer `PassthroughSubject` for events, `CurrentValueSubject` for state
- Do not use `@Published` in non-ObservableObject types

### 26. SwiftUI Patterns (Project-Specific)

When reviewing SwiftUI views, also check:
- `@StateObject` with `_viewModel = StateObject(wrappedValue:)` pattern for ViewModel injection
- `.hosted()` for full-screen views, `.subviewHosted()` for cells/embedded views
- `.onViewDidLoad` for one-time setup instead of `.onAppear` (which fires multiple times)
- Background + content layering via `ZStack` with named subview properties
- Follow `/swiftui-view`, `/view-structure`, `/state-management`, `/performance-patterns` skill rules
