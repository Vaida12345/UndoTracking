//
//  Essentials.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import Testing
import UndoTracking


@Suite
@MainActor
struct Essentials {

    @Test func undoRedoRoundTrip() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }

        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Increment")
        #expect(model.index == 1)
        undoManager.undo()
        #expect(!undoManager.canUndo)
        #expect(undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo Increment")
        #expect(model.index == 0)
        undoManager.redo()
        #expect(!undoManager.canRedo)
        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Increment")
        #expect(model.index == 1)
    }

    @Test func undoGroupingBasic() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment 1")
        }
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment 2")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.canUndo)
        #expect(undoManager.groupingLevel == 1)
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }
    
    @Test func undoTwiceNoGroup() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // undoManager groups events together in the same run loop by default, so needs explicit grouping.
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment 1")
        }
        undoManager.endUndoGrouping()
        
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment 2")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.canUndo)
        if #available(macOS 14.4, *) {
            #expect(undoManager.undoCount == 2)
        }
        #expect(undoManager.groupingLevel == 0)
        #expect(model.index == 2)

        #expect(undoManager.canUndo)
        #expect(undoManager.undoActionName == "Increment 2")
        undoManager.undo()
        if #available(macOS 14.4, *) {
            #expect(undoManager.undoCount == 1)
        }
        #expect(model.index == 1)
        
        #expect(undoManager.canUndo)
        #expect(undoManager.undoActionName == "Increment 1")
        undoManager.undo()
        if #available(macOS 14.4, *) {
            #expect(undoManager.undoCount == 0)
        }
        #expect(model.index == 0)
    }

    @Test func undoNestedGroupingBasic() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        for _ in 0..<2 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                model.increment()
                    .named("Increment")
            }
            withUndoTracking(undoManager) {
                model.increment()
                    .named("Increment")
            }
            undoManager.endUndoGrouping()
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.canUndo)
        #expect(model.index == 4)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 4)
    }

    @Test func moveAndRemoveByOffsets() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])
        var copy = container.content

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [3, 4], toOffset: 0)
        }

        copy.move(fromOffsets: [3, 4], toOffset: 0)
        #expect(copy == container.content)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])


        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [1, 3])
        }

        #expect(container.content.map(\.content) == [1, 3, 5])
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])
    }

    // MARK: - Undo / Redo title tracking

    @Test func undoRedoTitleCycle() {
        let undoManager = UndoManager()
        let model = Model()

        // Cycle through undo/redo twice, verifying titles each time.
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }

        for _ in 0..<3 {
            #expect(undoManager.canUndo)
            #expect(undoManager.undoMenuItemTitle == "Undo Increment")
            #expect(model.index == 1)

            undoManager.undo()
            #expect(!undoManager.canUndo)
            #expect(undoManager.canRedo)
            #expect(undoManager.redoMenuItemTitle == "Redo Increment")
            #expect(model.index == 0)

            undoManager.redo()
            #expect(!undoManager.canRedo)
            #expect(undoManager.canUndo)
            #expect(undoManager.undoMenuItemTitle == "Undo Increment")
            #expect(model.index == 1)
        }
    }

    @Test func undoRedoWithoutNaming() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
        }

        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo")
        #expect(model.index == 0)

        undoManager.redo()
        #expect(undoManager.undoMenuItemTitle == "Undo")
        #expect(model.index == 1)
    }

    // MARK: - Grouping with title focus

    @Test func groupUndoTitleWithSingleNamedAction() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Solo")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.undoMenuItemTitle == "Undo Solo")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(undoManager.redoMenuItemTitle == "Redo Solo")
        #expect(model.index == 0)
    }

    @Test func mixedNamedAndUnnamedInGroup() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
        }
        withUndoTracking(undoManager) {
            model.increment()
                .named("Named")
        }
        undoManager.endUndoGrouping()

        // The last action that sets a name wins.
        #expect(undoManager.undoMenuItemTitle == "Undo Named")
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Named")
    }

    @Test func mixedNamedThenUnnamedInGroup() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Named")
        }
        withUndoTracking(undoManager) {
            model.increment()
        }
        undoManager.endUndoGrouping()

        // The unnamed action ran last but did not change the name.
        // UndoManager retains the last-set action name.
        #expect(undoManager.undoMenuItemTitle == "Undo Named")
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Named")
    }

    // MARK: - Grouping depth

    @Test func tripleNestedGrouping() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()        // level 1
        undoManager.beginUndoGrouping()        // level 2
        undoManager.beginUndoGrouping()        // level 3
        withUndoTracking(undoManager) {
            model.increment()
                .named("Deep")
        }
        undoManager.endUndoGrouping()          // close 3
        withUndoTracking(undoManager) {
            model.increment()
                .named("Mid")
        }
        undoManager.endUndoGrouping()          // close 2
        withUndoTracking(undoManager) {
            model.increment()
                .named("Top")
        }
        undoManager.endUndoGrouping()          // close 1

        #expect(model.index == 3)
        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Top")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)

        undoManager.redo()
        #expect(model.index == 3)
    }

    @Test func groupingWithNilBuilder() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            nil as UndoComponent<Model>?
        }
        withUndoTracking(undoManager) {
            model.increment()
                .named("Only")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.undoMenuItemTitle == "Undo Only")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: - Redo stack clearing

    @Test func redoStackClearsAfterNewAction() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("First")
        }
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo First")

        // A new action should clear the redo stack.
        withUndoTracking(undoManager) {
            model.increment()
                .named("Second")
        }
        #expect(model.index == 1)
        #expect(!undoManager.canRedo)
        #expect(undoManager.undoMenuItemTitle == "Undo Second")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Second")
    }

    // MARK: - Animation

    @Test func animatedComponentExecutes() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("Animated")
                .animated()
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Animated")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Animated")

        undoManager.redo()
        #expect(model.index == 1)
    }

    // MARK: - Groups by event (default behavior)

    @Test func groupsByEventDefault() {
        let undoManager = UndoManager()
        // `groupsByEvent` defaults to `true`: actions in the same run loop are grouped.
        #expect(undoManager.groupsByEvent == true)

        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("One")
        }
        withUndoTracking(undoManager) {
            model.increment()
                .named("Two")
        }

        // Both ran in the same run loop → grouped as one undo.
        #expect(undoManager.canUndo)
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: - Multiple sequential operations with title tracking

    @Test func multipleNamedOperationsTrackTitles() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        for i in 1...5 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                model.increment()
                    .named("Step \(i)")
            }
            undoManager.endUndoGrouping()
        }

        #expect(model.index == 5)
        #expect(undoManager.undoMenuItemTitle == "Undo Step 5")

        // Undo in reverse order, checking each title.
        for i in (1...5).reversed() {
            #expect(undoManager.undoMenuItemTitle == "Undo Step \(i)")
            undoManager.undo()
        }
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)

        // Redo in forward order.
        for i in 1...5 {
            #expect(undoManager.redoMenuItemTitle == "Redo Step \(i)")
            undoManager.redo()
        }
        #expect(model.index == 5)
        #expect(!undoManager.canRedo)
    }

    // MARK: - Nil builder edge cases

    @Test func nilBuilderDoesNotAffectUndoStack() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("Real")
        }

        // This should be a no-op.
        withUndoTracking(undoManager) {
            nil as UndoComponent<Model>?
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Real")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func nilBuilderDoesNotClearRedoStack() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("Action")
        }

        undoManager.undo()
        #expect(undoManager.canRedo)

        // Nil builder should not clear redo stack.
        withUndoTracking(undoManager) {
            nil as UndoComponent<Model>?
        }

        #expect(undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo Action")
    }

    // MARK: - Increment / decrement interplay

    /// Decrement alone: index goes negative, undo restores via increment, redo via decrement.
    @Test func decrementUndoRedoRoundTrip() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.decrement()
                .named("Decrement")
        }

        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Decrement")
        #expect(model.index == -1)

        undoManager.undo()
        #expect(!undoManager.canUndo)
        #expect(undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo Decrement")
        #expect(model.index == 0)

        undoManager.redo()
        #expect(!undoManager.canRedo)
        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Decrement")
        #expect(model.index == -1)
    }

    /// Undo of increment runs decrement internally, but the label stays "Redo Increment".
    @Test func incrementUndoRunsDecrementLabelStaysIncrement() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        #expect(model.index == 1)

        // Undo internally calls decrement() → index goes to 0.
        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.canRedo)
        // The label describes the original action, not the inverse.
        #expect(undoManager.redoMenuItemTitle == "Redo Increment")

        // Redo internally calls increment() again → index back to 1.
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Increment")
    }

    /// Undo of decrement runs increment internally, label stays "Redo Decrement".
    @Test func decrementUndoRunsIncrementLabelStaysDecrement() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.decrement()
                .named("Decrement")
        }
        #expect(model.index == -1)

        // Undo internally calls increment() → index goes to 0.
        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo Decrement")

        // Redo internally calls decrement() again → index back to -1.
        undoManager.redo()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Decrement")
    }

    /// Increment then decrement on the stack: undo reverses each in order.
    @Test func incrementThenDecrementUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Up")
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.decrement()
                .named("Down")
        }
        undoManager.endUndoGrouping()

        // Up → 1, Down → 0.
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Down")

        // Undo Down → index goes to 1.
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Up")
        #expect(undoManager.redoMenuItemTitle == "Redo Down")

        // Undo Up → index goes to 0.
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Up")

        // Redo Up → index goes to 1.
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.redoMenuItemTitle == "Redo Down")

        // Redo Down → index goes to 0.
        undoManager.redo()
        #expect(model.index == 0)
        #expect(!undoManager.canRedo)
        #expect(undoManager.undoMenuItemTitle == "Undo Down")
    }

    /// Decrement then increment on the stack: undo reverses each in order.
    @Test func decrementThenIncrementUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.decrement()
                .named("Down")
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Up")
        }
        undoManager.endUndoGrouping()

        // Down → -1, Up → 0.
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Up")

        // Undo Up → index goes to -1.
        undoManager.undo()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Down")
        #expect(undoManager.redoMenuItemTitle == "Redo Up")

        // Undo Down → index goes to 0.
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Down")

        // Redo Down → index goes to -1.
        undoManager.redo()
        #expect(model.index == -1)
        #expect(undoManager.redoMenuItemTitle == "Redo Up")

        // Redo Up → index goes to 0.
        undoManager.redo()
        #expect(model.index == 0)
    }

    /// Alternating increment/decrement in a multi-step stack; walk undo/redo checking each step.
    @Test func alternatingIncrementDecrementMultiStep() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: +1 → 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Up 1") }
        undoManager.endUndoGrouping()

        // Step 2: -1 → 0
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Down") }
        undoManager.endUndoGrouping()

        // Step 3: +1 → 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Up 2") }
        undoManager.endUndoGrouping()

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Up 2")

        // Undo Up 2 → 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Down")
        #expect(undoManager.redoMenuItemTitle == "Redo Up 2")

        // Undo Down → 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Up 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Down")

        // Undo Up 1 → 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Up 1")

        // Redo Up 1 → 1
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.redoMenuItemTitle == "Redo Down")

        // Redo Down → 0
        undoManager.redo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Up 2")

        // Redo Up 2 → 1
        undoManager.redo()
        #expect(model.index == 1)
        #expect(!undoManager.canRedo)
        #expect(undoManager.undoMenuItemTitle == "Undo Up 2")
    }

    /// Repeated undo/redo cycle with decrement, verifying labels survive the round trip.
    @Test func decrementUndoRedoTitleCycle() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.decrement()
                .named("Decrement")
        }

        for _ in 0..<3 {
            #expect(undoManager.canUndo)
            #expect(undoManager.undoMenuItemTitle == "Undo Decrement")
            #expect(model.index == -1)

            undoManager.undo()
            #expect(!undoManager.canUndo)
            #expect(undoManager.canRedo)
            #expect(undoManager.redoMenuItemTitle == "Redo Decrement")
            #expect(model.index == 0)

            undoManager.redo()
            #expect(!undoManager.canRedo)
            #expect(undoManager.canUndo)
            #expect(undoManager.undoMenuItemTitle == "Undo Decrement")
            #expect(model.index == -1)
        }
    }

    /// undoActionName tracks the current undo label correctly through increment/decrement.
    @Test func incrementDecrementUndoActionNameTracking() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc") }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()

        #expect(undoManager.undoActionName == "Dec")
        #expect(model.index == 0)

        undoManager.undo()
        #expect(undoManager.undoActionName == "Inc")
        #expect(model.index == 1)

        undoManager.redo()
        #expect(undoManager.undoActionName == "Dec")
        #expect(model.index == 0)
    }

    // MARK: - Named action without .named()

    @Test func namedMethodChangesTitleMidStack() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("A")
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("B")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.undoMenuItemTitle == "Undo B")

        undoManager.undo()
        #expect(undoManager.undoMenuItemTitle == "Undo A")
        #expect(undoManager.redoMenuItemTitle == "Redo B")

        undoManager.undo()
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo A")

        undoManager.redo()
        #expect(undoManager.redoMenuItemTitle == "Redo B")
        #expect(model.index == 1)
    }

}

@MainActor
@Suite
struct RetainTests {
    
    @Test func precondition() async throws {
        try await confirmation { confirm in
            autoreleasepool {
                let model = DeallocSentinel { confirm() }
                let undoManager = UndoManager()
                withUndoTracking(undoManager) {
                    model.increment()
                }
                
                _ = consume model
                _ = consume undoManager
            }
            try await Task.sleep(for: .seconds(0.1)) // wait for dealloc
        }
    }
    
    @Test func retainTest1() async throws {
        let undoManager = UndoManager()
        
        await withKnownIssue("UndoManager is actually keeping a strong reference to the target") {
            try await confirmation { confirm in
                autoreleasepool {
                    let model = DeallocSentinel { confirm() }
                    withUndoTracking(undoManager) {
                        model.increment()
                    }
                    
                    _ = consume model
                }
                try await Task.sleep(for: .seconds(0.1)) // wait for dealloc
            }
        }
    }
    
    @Test func retainTest2() async throws {
        let undoManager = UndoManager()
        
        try await confirmation { confirm in
            autoreleasepool {
                let model = DeallocSentinel { confirm() }
                withUndoTracking(undoManager) {
                    model.increment()
                }
                
                _ = consume model
            }
            undoManager.removeAllActions()
            try await Task.sleep(for: .seconds(0.1)) // wait for dealloc
        }
    }
    
    final class DeallocSentinel: @unchecked Sendable {
        let deinitCall: () -> Void
        init(deinitCall: @escaping () -> Void) {
            self.deinitCall = deinitCall
        }
        deinit { deinitCall() }
        
        var index: Int = 0
        
        
        func increment() -> UndoComponent<DeallocSentinel> {
            UndoComponent(target: self) { target, withAnimation, registerUndo in
                withAnimation {
                    target.index += 1
                }
                registerUndo {
                    target.decrement()
                }
            }
        }
        
        func decrement() -> UndoComponent<DeallocSentinel> {
            UndoComponent(target: self) { target, withAnimation, registerUndo in
                withAnimation {
                    target.index -= 1
                }
                registerUndo {
                    target.increment()
                }
            }
        }
    }
}
