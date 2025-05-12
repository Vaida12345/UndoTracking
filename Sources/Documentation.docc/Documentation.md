# ``UndoTracking``

Wrapper for UndoManager

## Getting Started

The `UndoTracking` uses a closure-based structure similar to SwiftUI declaration.

```swift
withUndoTracking(undoManager) {                 
    document.replace(\.selection, with: [note]) 
        .named("Select \([note])")                                
}
```

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
