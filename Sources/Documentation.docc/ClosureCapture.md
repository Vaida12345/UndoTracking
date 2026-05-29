# Closure Capture

How `UndoTracking` captures values in closures.

## One rule

**All closures capture their values at ``withUndoTracking(_:builder:)`` time**, where builder closures, `UndoComponent` actions, and `registerUndo` closures all fire together.

```swift
var restoreValue = 0

let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
    target.index = 10
    registerUndo {
        target.replace(\.index, with: restoreValue)
    }
}

restoreValue = 20

withUndoTracking(undoManager) { component }
// model.index == 10         (forward action ran with restoreValue = 20)
```

Once captured, values are baked into the undo/redo chain — mutations after `withUndoTracking` has no effect.

This applies equally to value types and reference types. Property reads on reference types happen at `withUndoTracking` time, not at undo time.


## Target and undoManager references

`UndoComponent` stores a **strong** reference to `target`. Reassigning or nilling out the local variable has no effect.

The `registerUndo` handler captures `undoManager` **weakly** to prevent a retain cycle. Deallocating the undo manager with pending actions is safe.
