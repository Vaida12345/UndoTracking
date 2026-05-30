# Closure Capture

How `UndoTracking` captures values in closures.

## Two capture phases

UndoTracking closures capture values in two distinct phases:

1. **`withUndoTracking` time** — ``UndoComponent`` action closures and ``UndoGroup`` builder closures execute here, so any variables they read are captured at this point.

2. **Undo time** — `registerUndo`'s body is called later when the user invokes undo (Cmd-Z). Variables captured by this closure are read at *undo time*, not at registration time.

- Remark: This is to ensure all code in `registerUndo` is executed at Undo Time.

### Forward action (withUndoTracking time)

```swift
var newValue = 10

let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
    target.index = newValue   // ← captured at withUndoTracking time
    registerUndo {
        target.replace(\.index, with: 0)
    }
}

newValue = 99

withUndoTracking(undoManager) { component }
// model.index == 99  (forward action ran with newValue = 99)
```

The forward action closure executes during `withUndoTracking`, so `newValue` is read at that moment — after the mutation to 99.

### registerUndo makeUndoComponent (undo time)

```swift
var restoreValue = 0

let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
    target.index = 10
    registerUndo {
        target.replace(\.index, with: restoreValue)  // ← captured at UNDO time
    }
}

restoreValue = 20

withUndoTracking(undoManager) { component }
// model.index == 10  (forward action ran)

// At this point, restoreValue == 20. But the undo hasn't fired yet.

restoreValue = 123

undoManager.undo()
// model.index == 123  (undo read restoreValue = 123, not 20)
```

Because `makeUndoComponent` is `@escaping`, its body is deferred until undo fires. It reads `restoreValue` at that later time — so mutations between `withUndoTracking` and undo **do** affect the result.

### Explicit capture lists

Use an explicit capture list `[value]` to snap a copy when the closure is created — that is, when the action block runs (inside `withUndoTracking`). The closure body still executes at undo time, but `value` is frozen at its creation-time value:

```swift
var restoreValue = 0

let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
    target.index = 10
    registerUndo { [restoreValue] in
        target.replace(\.index, with: restoreValue)  // ← snapshotted when action runs
    }
}

withUndoTracking(undoManager) { component }
// model.index == 10  (forward action ran)

// Mutate AFTER withUndoTracking — explicit capture already snapped 0.
restoreValue = 999

undoManager.undo()
// model.index == 0  (uses the snapshotted value 0, not the mutated 999)
```

### After the first undo

Once undo fires, `replace(_:with:)` captures the old index into a local `var value` inside its own action. The undo/redo chain thereafter uses that captured value — the original captured variables are no longer referenced.
