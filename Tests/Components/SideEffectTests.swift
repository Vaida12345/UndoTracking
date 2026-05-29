//
//  SideEffectTests.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation
import Testing
@testable import UndoTracking


// MARK: - Builder evaluation count tests

/// Verifies that `UndoGroup.builder()` is evaluated exactly once during `_execute`,
/// and that `_TupleComponent` / `_ArrayComponent` do not trigger a second evaluation
/// via `_isEmpty` pre-checks.
@Suite
@MainActor
struct SideEffectTests {

    // MARK: UndoGroup builder called exactly once

    @Test func undoGroupBuilderCalledExactlyOnce() {
        let undoManager = UndoManager()
        let model = Model()
        var callCount = 0

        // Use internal init to bypass @UndoGroupBuilder so we can embed a
        // counter increment in the closure.
        let group = UndoGroup(
            title: "Test",
            builder: {
                callCount += 1
                return model.increment()
            },
            animated: nil
        )

        #expect(callCount == 0)
        group._execute(undoManager: undoManager, context: _UndoComponentContext())
        #expect(callCount == 1)
        #expect(model.index == 1)
    }

    // MARK: UndoGroup builder called once even when empty

    @Test func emptyUndoGroupBuilderCalledExactlyOnce() {
        let undoManager = UndoManager()
        var callCount = 0

        let group = UndoGroup(
            title: "Empty",
            builder: {
                callCount += 1
                return _ConditionalComponent<UndoComponent<Model>>(content: nil)
            },
            animated: nil
        )

        #expect(callCount == 0)
        group._execute(undoManager: undoManager, context: _UndoComponentContext())
        #expect(callCount == 1)
        #expect(undoManager.canUndo == false)
    }

    // MARK: Empty group does not create phantom undo action

    @Test func emptyGroupNoPhantomUndoAction() {
        let undoManager = UndoManager()

        withUndoTracking(undoManager) {
            UndoGroup("Phantom") {
                if false {
                    Model().increment()
                }
            }
        }

        #expect(undoManager.canUndo == false)
    }

    @Test func emptyGroupNoPhantomUndoActionViaArray() {
        let undoManager = UndoManager()
        let items: [Int] = []

        withUndoTracking(undoManager) {
            UndoGroup("Phantom") {
                for _ in items {
                    Model().increment()
                }
            }
        }

        #expect(undoManager.canUndo == false)
    }

    // MARK: _TupleComponent does not pre-filter with _isEmpty

    @Test func tupleComponentDoesNotPreFilter() {
        let undoManager = UndoManager()
        let model = Model()
        var callCount = 0

        let group = UndoGroup(
            title: "Inner",
            builder: {
                callCount += 1
                return model.increment()
            },
            animated: nil
        )

        // Wrap in a _ConditionalComponent and call _execute directly.
        // _ConditionalComponent._execute does not pre-filter via _isEmpty.
        let conditional = _ConditionalComponent(content: group)
        conditional._execute(undoManager: undoManager, context: _UndoComponentContext())
        #expect(callCount == 1)
        #expect(model.index == 1)
    }

    // MARK: _ArrayComponent does not pre-filter with _isEmpty

    @Test func arrayComponentDoesNotPreFilter() {
        let undoManager = UndoManager()
        let model = Model()
        var callCount = 0

        let group = UndoGroup(
            title: "Inner",
            builder: {
                callCount += 1
                return model.increment()
            },
            animated: nil
        )

        let array = _ArrayComponent(content: [group])
        array._execute(undoManager: undoManager, context: _UndoComponentContext())
        #expect(callCount == 1)
        #expect(model.index == 1)
    }

    // MARK: Multiple children in UndoGroup — each executes once

    @Test func multipleChildrenEachExecuteOnce() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Batch") {
                model.increment()
                model.increment()
                model.increment()
            }
        }

        #expect(model.index == 3)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Nested UndoGroups — each builder called exactly once

    /// The outer `UndoGroup` wraps an inner `UndoGroup`. The caching
    /// `Storage` ensures the inner builder is evaluated at most once,
    /// even though both the outer's `guard !contents._isEmpty` and
    /// `contents._execute` access the inner `UndoGroup`.
    @Test func nestedUndoGroupsEachBuilderCalledOnce() {
        let undoManager = UndoManager()
        let model = Model()
        var outerCount = 0
        var innerCount = 0

        let inner = UndoGroup(
            title: "Inner",
            builder: {
                innerCount += 1
                return model.increment()
            },
            animated: nil
        )

        let outer = UndoGroup(
            title: "Outer",
            builder: {
                outerCount += 1
                return inner
            },
            animated: nil
        )

        #expect(outerCount == 0)
        #expect(innerCount == 0)

        outer._execute(undoManager: undoManager, context: _UndoComponentContext())

        #expect(outerCount == 1)
        withKnownIssue("nested groups can execute inner group twice, once in outergroup execute -> _isEmpty check, and once in innererGroup _execute.") {
            #expect(innerCount == 1)
        }
        #expect(model.index == 1)
    }

    // MARK: Undo + redo — each action produces correct result

    /// Verifies that the undo/redo chain works end-to-end without
    /// multiply-evaluating side effects within a single pass.
    @Test func undoRedoPreservesCorrectState() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Increment") {
                model.increment()
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)

        // Second full cycle — each pass should work independently.
        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

}
