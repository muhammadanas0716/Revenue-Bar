# Contributing to MRR Bar

First off, thanks for taking the time to contribute! 🎉

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**When reporting a bug, include:**

- macOS version
- App version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots if applicable

### Suggesting Features

Feature requests are welcome! Please provide:

- Clear description of the feature
- Why it would be useful
- Possible implementation approach (optional)

### Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Follow the code style** - SwiftUI conventions, clear naming
3. **Test your changes** - Make sure the app builds and runs
4. **Update documentation** if needed
5. **Write a clear PR description**

## Development Guidelines

### Code Style

- Use Swift's standard naming conventions
- Keep functions small and focused
- Add comments for complex logic
- Use `// MARK: -` to organize code sections

### SwiftUI Best Practices

- Extract reusable views into separate structs
- Use `@StateObject` for owned data, `@ObservedObject` for passed data
- Keep views lightweight, move logic to view models

### Commit Messages

Use clear, descriptive commit messages:

```
Add Lemon Squeezy integration

- Add LemonSqueezyAPI enum with fetchStats method
- Update RevenueManager with new properties
- Add settings fields for API key
```

### Project Structure

```
MRR Bar/
├── MRR_BarApp.swift      # App entry, menu bar setup
├── Views/
│   ├── MenuBarView.swift  # Main popover
│   └── SettingsView.swift # Settings window
├── Models/
│   └── RevenueManager.swift # Business logic
├── Helpers/
│   └── KeychainHelper.swift # Secure storage
└── Assets.xcassets/
```

## Adding a New Payment Platform

1. **Add API types** in `RevenueManager.swift`:

```swift
// MARK: - NewPlatform API
enum NewPlatformAPI {
    static func fetchStats(apiKey: String) async throws -> RevenueStats {
        // Implementation
    }
}
```

2. **Add properties** to `RevenueManager`:

```swift
@Published var newPlatformRevenue: Double = 0
@Published var newPlatformOrderCount: Int = 0

var newPlatformAPIKey: String {
    get { KeychainHelper.get(key: "newPlatformAPIKey") ?? "" }
    set { KeychainHelper.save(key: "newPlatformAPIKey", value: newValue) }
}
```

3. **Add fetch method**:

```swift
@MainActor
private func fetchNewPlatformData() async {
    guard !newPlatformAPIKey.isEmpty else { return }
    do {
        let stats = try await NewPlatformAPI.fetchStats(apiKey: newPlatformAPIKey)
        newPlatformRevenue = stats.revenue
        newPlatformOrderCount = stats.orderCount
    } catch {
        self.error = "NewPlatform: \(error.localizedDescription)"
    }
}
```

4. **Update UI** in `MenuBarView.swift` and `SettingsView.swift`

## Testing

Currently, testing is manual. When testing:

- [ ] App launches without errors
- [ ] Settings save correctly
- [ ] API keys are stored securely (check Keychain)
- [ ] Revenue displays correctly
- [ ] Auto-refresh works
- [ ] Error states display properly

## Questions?

Feel free to open an issue for any questions about contributing.

Thank you for helping make MRR Bar better! 🚀
