# UndoTracking

A closure-based wrapper for `UndoManager`, inspired by SwiftUI’s declarative style.

## Overview

`UndoTracking` lets you register undo and redo actions using a closure builder. For example:

```swift
withUndoTracking(undoManager) {
    document.replace(\.selection, with: [note])
        .named("Select \(note)")
        .animated()
}
```

- `withUndoTracking(_:)` opens a builder closure that returns an `UndoComponent`.
- You can chain modifiers on the component:
  - `named(_:)` sets the undo/redo action’s name.  
  - `animated()` marks the action to run inside a `withAnimation` block (when used in SwiftUI).

## UndoTracking Protocol

Conform your class to `UndoTracking` (no requirements other than being a class) to gain a suite of built-in undo components, such as `replace(_:with:)`, `insert(_:at:)`, and so on. These methods return `UndoComponent` instances that you can use inside `withUndoTracking(_:)`.


## Creating Custom UndoComponents

To add your own undoable operations, return an `UndoComponent` from a method on your `UndoTracking` type:

```swift
final class Counter: UndoTracking {
    var count: Int = 0

    func increment() -> UndoComponent<Counter> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            // Primary action
            withAnimation {
                target.count += 1
            }
            // Register the inverse action
            registerUndo {
                target.decrement()
            }
        }
    }

    func decrement() -> UndoComponent<Counter> { ... }
}
```

### Closure Parameters

- `target`: The instance on which the action is performed.  
- `withAnimation`: A closure that runs its block with animation if `animated()` was called. You can ignore it if you don’t need animation.  
- `registerUndo`: A closure that takes a zero-argument function—in it, register the inverse operation to be executed on undo.

Modifiers applied to the returned `UndoComponent` (like `named` or `animated`) are preserved when the component is executed.


## Getting Started

`UndoTracking` uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) as its build tool. If you want to import in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://www.github.com/Vaida12345/UndoTracking", branch: "main")
]
```
and then adding the appropriate module to your target dependencies.

### Using Xcode Package support

You can add this framework as a dependency to your Xcode project by clicking File -> Swift Packages -> Add Package Dependency. The package is located at:
```
https://www.github.com/Vaida12345/UndoTracking
```

## Documentation

This package uses [DocC](https://www.swift.org/documentation/docc/) for documentation.
