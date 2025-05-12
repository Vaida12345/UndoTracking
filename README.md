# UndoTracking
Wrapper for UndoManager

## Getting Started

The `UndoTracking` uses a closure-based structure similar to SwiftUI declaration.

```swift
withUndoTracking(undoManager) {                
    document.replace(\.selection, with: [note])
        .named("Select \([note])")                                   
}
```

