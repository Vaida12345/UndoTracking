# ``UndoTracking``

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

``withUndoTracking(_:builder:)`` opens a builder closure that returns an ``UndoComponent``.

## UndoTracking Protocol

Conform your class to ``UndoTracking`` (no requirements other than being a class) to gain a suite of built-in undo components, such as ``UndoTracking/UndoTracking/replace(_:with:)``, ``UndoTracking/UndoTracking/insert(_:at:to:)``, and so on. These methods return ``UndoComponent`` instances that you can use inside ``withUndoTracking(_:builder:)``.


## Creating Custom UndoComponents

To add your own undoable operations, return an ``UndoComponent`` from a method on your ``UndoTracking`` type:

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

- term target: The instance on which the action is performed.  
- term withAnimation: A closure that runs its block with animation if ``UndoComponent/animated()`` was called. You can ignore it if you don’t need animation.  
- term registerUndo: A closure that takes a zero-argument function—in it, register the inverse operation to be executed on undo.

Modifiers applied to the returned ``UndoComponent`` (like ``UndoComponent/named(_:)`` or ``UndoComponent/animated()``) are preserved when the component is executed.

## Topics

### UndoContainer
The closuring containing all undo declarations.
- ``withUndoTracking(_:builder:)``

### Declaration Methods
The declarative methods attached to undo actions.
- ``UndoComponent/named(_:)``
- ``UndoComponent/animated()``

### UndoTracking Protocol
The protocol providing undoable actions to the attached object.
- ``UndoTracking``

### UndoComponent
The internal representation returned by the undoable actions of ``UndoTracking``.
- ``UndoComponent-struct``
- <doc:BuildUndoComponent>
