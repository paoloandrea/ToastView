# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ToastView is a Swift Package that provides a toast notification system for iOS and tvOS applications. It displays non-intrusive messages with optional icons, progress indicators, and blurred backgrounds.

## Commands

### Building
```bash
swift build
```

### Testing
```bash
# Run all tests
swift test

# Run specific test
swift test --filter ToastViewTests.testShowWithMessage
```

## Architecture

### Core Components

**ToastManager** (`Sources/ToastView/ToastManager.swift`)
- Singleton pattern managing toast lifecycle and queuing
- Controls toast display, dismissal, and positioning
- Key properties:
  - `allowMultipleToasts`: Controls whether multiple toasts can stack (default: false)
  - `toastQueue`: Internal queue of pending/active toasts
  - `message`: Property for updating current toast message without creating new instance

**ToastView** (`Sources/ToastView/ToastView.swift`)
- Custom UIView with blurred background using UIVisualEffectView
- Contains stack view organizing icon/spinner + message label
- Supports 7 position options via `ToastPosition` enum (topLeft, top, topRight, center, bottomLeft, bottom, bottomRight)
- Platform-specific sizing: iOS uses smaller dimensions, tvOS uses larger

### Key Interactions

1. **Toast Display Flow**:
   - `ToastManager.showToast()` creates new `ToastView` instance
   - Toast added to queue and container view
   - `updateToastPositions()` recalculates layout constraints when `allowMultipleToasts` is enabled
   - Auto-dismissal scheduled via `DispatchQueue.main.asyncAfter` if duration > 0

2. **Multiple Toast Handling**:
   - When `allowMultipleToasts = true`, toasts stack vertically based on position
   - `updateToastPositions()` deactivates old constraints and recalculates yOffset for each toast
   - Animation handled via `UIView.animate(withDuration: 0.3)`

3. **Message Updates**:
   - `ToastManager.message` property updates current toast without creating new instance
   - Directly modifies `toastLabel.text` via `updateMessage()` method

### Platform Support

- Minimum iOS: 13.0
- Minimum tvOS: 13.0
- Uses conditional compilation (`#if os(iOS)` / `#elseif os(tvOS)`) for platform-specific sizing

## Testing Notes

Current tests in `Tests/ToastViewTests/ToastViewTests.swift` reference static methods (`ToastView.show()`, `ToastView.activeToasts`) that don't exist in the current implementation. The actual API uses the `ToastManager.shared` singleton pattern. Tests need updating to match the implementation.
