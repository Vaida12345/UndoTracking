
# Building UndoComponent

Guides on constructing ``UndoComponent``


Here is an example of returning an ``UndoComponent`` that can be used within ``withUndoTracking(_:builder:)``

```swift
final class Counter: UndoTracking {

    var index: Int = 0

    func increment() -> UndoComponent<Counter> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                target.index += 1
            }
            registerUndo {
                target.decrement()
            }
    }

    func decrement() -> UndoComponent<Counter> { ... }
}
```



###  Closure Parameters
- term target: The target document, as passed from `target` to avoid capture.

- term withAnimation: The conditional `withAnimation` block. 

    Similar to that in `SwiftUI`, functions are executed with animation attached when ``UndoComponent/animated()``.

    You can choose to ignore this parameter if animation is not required.

- term registerUndo: The block for registering undo. The returned value is executed when `undo()`.

    The return component will inherit any attributes set to `self`.

---

## Using UndoComponent

To use the returned component, use ``withUndoTracking(_:builder:)``

```swift
withUndoTracking(undoManager) {
    model.increment()
        .named("Increment")
}
```

This will register the increment action, and its undo/redo chain to the `undoManager`, which can restore to the previous state using `undoManager.undo()` and `undoManager.redo()`
