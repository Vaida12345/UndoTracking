//
//  EssentialMix.swift
//  UndoTracking
//

import Foundation
import Testing
import UndoTracking


@Suite
@MainActor
struct EssentialMix {

    // MARK: - Static mixed sequences

    /// UndoGroup(inc+inc) → inc → undo → undo → redo → redo
    @Test func groupIncIncThenIncThenUndoAll() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: UndoGroup(inc+inc) → index 2
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("DoubleInc") {
                model.increment()
                model.increment()
            }
        }
        undoManager.endUndoGrouping()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo DoubleInc")

        // Step 2: inc → index 3
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc") }
        undoManager.endUndoGrouping()
        #expect(model.index == 3)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc")

        // Step 3: undo (reverses Inc) → index 2
        undoManager.undo()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo DoubleInc")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc")

        // Step 4: undo (reverses group) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo DoubleInc")

        // Step 5: redo (re-applies group) → index 2
        undoManager.redo()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo DoubleInc")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc")

        // Step 6: redo (re-applies Inc) → index 3
        undoManager.redo()
        #expect(model.index == 3)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc")
        #expect(!undoManager.canRedo)
    }

    /// inc → UndoGroup(inc+dec) → undo → redo
    @Test func incThenGroupIncDecThenUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: inc → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc")

        // Step 2: UndoGroup(inc+dec) → index stays 1 (+1-1=0)
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("IncDec") {
                model.increment()
                model.decrement()
            }
        }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo IncDec")

        // Step 3: undo (reverses group) → index 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc")
        #expect(undoManager.redoMenuItemTitle == "Redo IncDec")

        // Step 4: redo (re-applies group) → index 1
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo IncDec")
        #expect(!undoManager.canRedo)
    }

    /// dec → UndoGroup(inc+inc) → undo → undo → redo
    @Test func decThenGroupThenUndoUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: dec → index -1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")

        // Step 2: UndoGroup(inc+inc) → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("DoubleInc") {
                model.increment()
                model.increment()
            }
        }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo DoubleInc")

        // Step 3: undo (reverses group) → index -1
        undoManager.undo()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(undoManager.redoMenuItemTitle == "Redo DoubleInc")

        // Step 4: undo (reverses Dec) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 5: redo (re-applies Dec) → index -1
        undoManager.redo()
        #expect(model.index == -1)
        #expect(undoManager.redoMenuItemTitle == "Redo DoubleInc")
    }

    /// inc → dec → undo → inc → undo → undo → redo → redo
    @Test func incDecUndoIncUndoUndoRedoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: inc → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 1") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")

        // Step 2: dec → index 0
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")

        // Step 3: undo (reverses Dec) → index 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 4: inc → index 2 (clears redo stack)
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 2") }
        undoManager.endUndoGrouping()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")
        #expect(!undoManager.canRedo)

        // Step 5: undo (reverses Inc 2) → index 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")

        // Step 6: undo (reverses Inc 1) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 1")

        // Step 7: redo (re-applies Inc 1) → index 1
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")

        // Step 8: redo (re-applies Inc 2) → index 2
        undoManager.redo()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")
        #expect(!undoManager.canRedo)
    }

    /// inc → inc → undo → dec → redo (no-op) → undo → undo
    @Test func incIncUndoDecRedoUndoUndo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: inc → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 1") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")

        // Step 2: inc → index 2
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 2") }
        undoManager.endUndoGrouping()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")

        // Step 3: undo (reverses Inc 2) → index 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")

        // Step 4: dec → index 0 (clears redo stack)
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(!undoManager.canRedo)

        // Step 5: redo — no-op, redo stack was cleared by step 4
        undoManager.redo()
        #expect(model.index == 0)
        #expect(!undoManager.canRedo)

        // Step 6: undo (reverses Dec) → index 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 7: undo (reverses Inc 1) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 1")
    }

    /// dec → inc → undo → undo → redo
    @Test func decIncUndoUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: dec → index -1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")

        // Step 2: inc → index 0
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc") }
        undoManager.endUndoGrouping()
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc")

        // Step 3: undo (reverses Inc) → index -1
        undoManager.undo()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc")

        // Step 4: undo (reverses Dec) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 5: redo (re-applies Dec) → index -1
        undoManager.redo()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc")
    }

    /// inc → undo → dec → undo → redo
    @Test func incUndoDecUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: inc → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc")

        // Step 2: undo (reverses Inc) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Inc")

        // Step 3: dec → index -1 (clears redo stack)
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(!undoManager.canRedo)

        // Step 4: undo (reverses Dec) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 5: redo (re-applies Dec) → index -1
        undoManager.redo()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(!undoManager.canRedo)
    }

    /// inc→inc→inc→undo→undo→redo→dec→undo→redo (7 distinct operations interleaved)
    @Test func incIncIncUndoUndoRedoDecUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: inc → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 1") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")

        // Step 2: inc → index 2
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 2") }
        undoManager.endUndoGrouping()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")

        // Step 3: inc → index 3
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 3") }
        undoManager.endUndoGrouping()
        #expect(model.index == 3)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 3")

        // Step 4: undo (reverses Inc 3) → index 2
        undoManager.undo()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 3")

        // Step 5: undo (reverses Inc 2) → index 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")

        // Step 6: redo (re-applies Inc 2) → index 2
        undoManager.redo()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 3")

        // Step 7: dec → index 1 (clears redo stack)
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(!undoManager.canRedo)

        // Step 8: undo (reverses Dec) → index 2
        undoManager.undo()
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 9: redo (re-applies Dec) → index 1
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(!undoManager.canRedo)
    }

    /// dec→undo→inc→undo→inc→undo→undo→redo→redo
    @Test func decUndoIncUndoIncUndoUndoRedoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: dec → index -1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")

        // Step 2: undo (reverses Dec) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 3: inc → index 1 (clears redo)
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 1") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(!undoManager.canRedo)

        // Step 4: undo (reverses Inc 1) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 1")

        // Step 5: inc → index 1 (clears redo)
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 2") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")

        // Step 6: undo (reverses Inc 2) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")

        // Step 7: undo — no-op, nothing to undo
        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")

        // Step 8: redo (re-applies Inc 2) → index 1
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")
        #expect(!undoManager.canRedo)

        // Step 9: redo — no-op
        undoManager.redo()
        #expect(model.index == 1)
    }

    /// inc→dec→inc→undo→undo→undo→redo→redo
    @Test func incDecIncUndoUndoUndoRedoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Step 1: inc → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 1") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)

        // Step 2: dec → index 0
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.decrement().named("Dec") }
        undoManager.endUndoGrouping()
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")

        // Step 3: inc → index 1
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) { model.increment().named("Inc 2") }
        undoManager.endUndoGrouping()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 2")

        // Step 4: undo (reverses Inc 2) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")

        // Step 5: undo (reverses Dec) → index 1
        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 6: undo (reverses Inc 1) → index 0
        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 1")

        // Step 7: redo (re-applies Inc 1) → index 1
        undoManager.redo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Inc 1")
        #expect(undoManager.redoMenuItemTitle == "Redo Dec")

        // Step 8: redo (re-applies Dec) → index 0
        undoManager.redo()
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo Dec")
        #expect(undoManager.redoMenuItemTitle == "Redo Inc 2")
    }


    // MARK: - Randomized mix

    /// Perform an action with explicit grouping (matching the `groupsByEvent = false` pattern).
    private func perform(
        _ action: @escaping () -> UndoComponent<Model>?,
        undoManager: UndoManager
    ) {
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager, builder: action)
        undoManager.endUndoGrouping()
    }

    /// Runs a randomized sequence of increment / decrement / undo / redo operations,
    /// verifying model.index and labels at every step against an expected-state tracker.
    @Test func randomizedMix() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // Track expected state independently so we can verify each step.
        var expectedIndex = 0
        var undoStack: [(name: String, delta: Int)] = []
        var redoStack: [(name: String, delta: Int)] = []

        /// All possible actions.
        enum Action: CaseIterable {
            case increment
            case decrement
            case undo
            case redo
            case undoGroup
        }

        let iterations = 500
        var rng = SystemRandomNumberGenerator()

        for step in 0..<iterations {
            // Determine which actions are available.
            var available: [Action] = [.increment, .decrement, .undoGroup]
            if !undoStack.isEmpty { available.append(.undo) }
            if !redoStack.isEmpty { available.append(.redo) }

            let choice = available.randomElement(using: &rng)!

            switch choice {
            case .increment:
                perform({ model.increment().named("Inc") }, undoManager: undoManager)
                expectedIndex += 1
                undoStack.append(("Inc", +1))
                redoStack.removeAll()

            case .decrement:
                perform({ model.decrement().named("Dec") }, undoManager: undoManager)
                expectedIndex -= 1
                undoStack.append(("Dec", -1))
                redoStack.removeAll()

            case .undoGroup:
                let subCount = Int.random(in: 2...3, using: &rng)
                var netDelta = 0
                var isIncrements: [Bool] = []
                for _ in 0..<subCount {
                    let isIncrement = Bool.random(using: &rng)
                    isIncrements.append(isIncrement)
                    netDelta += isIncrement ? 1 : -1
                }
                let groupName = "Group \(step)"

                undoManager.beginUndoGrouping()
                withUndoTracking(undoManager) {
                    UndoGroup(LocalizedStringResource(stringLiteral: groupName)) {
                        for isIncrement in isIncrements {
                            if isIncrement {
                                model.increment()
                            } else {
                                model.decrement()
                            }
                        }
                    }
                }
                undoManager.endUndoGrouping()

                expectedIndex += netDelta
                undoStack.append((groupName, netDelta))
                redoStack.removeAll()

            case .undo:
                guard let last = undoStack.popLast() else { continue }
                undoManager.undo()
                expectedIndex -= last.delta   // reverse the original effect
                redoStack.append(last)

            case .redo:
                guard let last = redoStack.popLast() else { continue }
                undoManager.redo()
                expectedIndex += last.delta   // re-apply the original effect
                undoStack.append(last)
            }

            // Verify after every step.
            #expect(model.index == expectedIndex,
                    "Step \(step): expected index \(expectedIndex), got \(model.index)")
            #expect(undoManager.canUndo == !undoStack.isEmpty,
                    "Step \(step): canUndo mismatch")
            #expect(undoManager.canRedo == !redoStack.isEmpty,
                    "Step \(step): canRedo mismatch")

            if let expectedName = undoStack.last?.name {
                #expect(undoManager.undoMenuItemTitle == "Undo \(expectedName)",
                        "Step \(step): expected undo title 'Undo \(expectedName)', got '\(undoManager.undoMenuItemTitle)'")
            } else {
                #expect(undoManager.undoMenuItemTitle == "Undo",
                        "Step \(step): expected undo title 'Undo', got '\(undoManager.undoMenuItemTitle)'")
            }

            if let expectedName = redoStack.last?.name {
                #expect(undoManager.redoMenuItemTitle == "Redo \(expectedName)",
                        "Step \(step): expected redo title 'Redo \(expectedName)', got '\(undoManager.redoMenuItemTitle)'")
            } else {
                #expect(undoManager.redoMenuItemTitle == "Redo",
                        "Step \(step): expected redo title 'Redo', got '\(undoManager.redoMenuItemTitle)'")
            }
        }

        // Final sanity: undo all the way back to 0.
        while undoManager.canUndo {
            undoManager.undo()
        }
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

}
