# Concurrency

UndoTracking components are synchronous and run on `@MainActor`. To mix async work with undo, do the async work *before* calling `withUndoTracking`.

## The pattern: async work, then sync component

```swift
Task { @MainActor in
    let processed = await applyExpensiveFilter(to: document.image)
    withUndoTracking(undoManager) {
        document.replace(\.image, with: processed)
            .named("Apply Filter")
    }
}
```

The component is always sync. The only requirement is that `withUndoTracking` is called on the main actor, which the `Task` and `@MainActor` already guarantee.

## Why not make the component itself async?

An escaping `registerUndo` that can be deferred into a `Task` introduces several problems:

- **Undo is not instant.** If the undo body also spawns a `Task`, hitting Cmd-Z does nothing for seconds. Undo should feel like a state toggle, not an operation.
- **Grouping breaks.** `UndoGroup` uses synchronous `beginUndoGrouping`/`endUndoGrouping`. A deferred undo registration escapes the group.

All of this is avoided by keeping the component sync and doing the expensive work before the component exists.

## Caching for undo

If the forward operation transforms data in-place, cache the old value before mutating:

```swift
func applyFilter() -> UndoComponent<Document> {
    let cached = image
    return UndoComponent(target: self) { target, withAnimation, registerUndo in
        withAnimation {
            target.image = filtered
        }
        registerUndo {
            target.replace(\.image, with: cached)
        }
    }
}
```

The undo is a sync `.replace` — instant, no `Task` needed.

## Actor isolation

Everything runs on `@MainActor`. UndoManager is main-actor-isolated. There is no data-race risk through the undo system.
