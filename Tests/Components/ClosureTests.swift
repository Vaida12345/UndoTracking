//
//  ClosureTests.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation
import Testing
import UndoTracking


/// Verifies correctness of undo/redo when escaping closures capture state that later changes.
///
/// Both `UndoGroup` and `withUndoTracking` accept `@escaping` closures.
/// The `UndoManager.registerUndo` handler forms an escaping closure chain.
/// These tests ensure the undo/redo chain remains correct even after
/// captured references, non-captured references, and copied values are mutated.
@Suite
@MainActor
struct EscapingClosureTests {

    // MARK: - UndoGroup builder captures

    @Test("builder captures mutable var changed before execution")
    func groupBuilderCapturesMutableVarChangedBeforeExecution() {
        let undoManager = UndoManager()
        let model = Model()
        var capturedValue = 5

        let group = UndoGroup("Capture") {
            model.replace(\.index, with: capturedValue)
        }

        capturedValue = 42

        withUndoTracking(undoManager) {
            group
        }

        #expect(model.index == 42)
        #expect(undoManager.undoMenuItemTitle == "Undo Capture")

        cycle(undoManager: undoManager, model: model, redoValue: 42) { capturedValue = 99 }
        cycle(undoManager: undoManager, model: model, redoValue: 42) { capturedValue = 7 }
    }

    @Test("builder captures mutable var, multiple cycles")
    func groupBuilderCapturesMutableVarMultipleCycles() {
        let undoManager = UndoManager()
        let model = Model()
        var delta = 3

        let group = UndoGroup("Delta") {
            model.replace(\.index, with: delta)
        }

        delta = 7

        withUndoTracking(undoManager) {
            group
        }

        #expect(model.index == 7)

        cycle(undoManager: undoManager, model: model, redoValue: 7) { delta = 15 }
        cycle(undoManager: undoManager, model: model, redoValue: 7) { delta = 22 }
    }

    // MARK: - UndoComponent action captures

    @Test("action captures mutable var changed before execution")
    func componentActionCapturesMutableVarChangedBeforeExecution() {
        let undoManager = UndoManager()
        let model = Model()
        var newValue = 10

        let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
            let old = target.index
            target.index = newValue
            registerUndo {
                target.replace(\.index, with: old)
            }
        }

        newValue = 99

        withUndoTracking(undoManager) {
            component
        }

        #expect(model.index == 99)

        cycle(undoManager: undoManager, model: model, redoValue: 99) { newValue = 55 }
        cycle(undoManager: undoManager, model: model, redoValue: 99) { newValue = -5 }
    }

    // MARK: - Target strong capture

    @Test("target strongly captured, survives local reassignment")
    func targetStrongCaptureSurvivesLocalReassignment() {
        let undoManager = UndoManager()
        let model1 = Model()

        let component = model1.increment().named("Inc")

        withUndoTracking(undoManager) {
            component
        }

        #expect(model1.index == 1)
        #expect(undoManager.canUndo)

        cycle(undoManager: undoManager, model: model1, redoValue: 1) {}
        cycle(undoManager: undoManager, model: model1, redoValue: 1) {}
    }

    @Test("target strongly captured, survives local set to nil")
    func targetStrongCaptureWhenLocalSetToNil() {
        let undoManager = UndoManager()
        var model: Model? = Model()
        let keepAlive = model!

        let component = UndoComponent(target: model!) { target, withAnimation, registerUndo in
            target.index = 77
            registerUndo {
                target.replace(\.index, with: 0)
            }
        }.named("Set77")

        model = nil

        withUndoTracking(undoManager) {
            component
        }

        #expect(keepAlive.index == 77)

        cycle(undoManager: undoManager, model: keepAlive, redoValue: 77) {}
        cycle(undoManager: undoManager, model: keepAlive, redoValue: 77) {}
    }

    // MARK: - Reference type state mutation

    @Test("captured reference state mutated before undo")
    func capturedReferenceStateMutatedBeforeUndo() {
        let undoManager = UndoManager()
        let model = Model()

        class SharedNote {
            var text: String
            init(_ text: String) { self.text = text }
        }
        let note = SharedNote("forward")

        let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
            target.index = 1
            registerUndo {
                target.replace(\.index, with: note.text == "forward" ? 0 : -1)
            }
        }.named("WithNote")

        withUndoTracking(undoManager) {
            component
        }

        #expect(model.index == 1)

        cycle(undoManager: undoManager, model: model, redoValue: 1) { note.text = "changed" }
        cycle(undoManager: undoManager, model: model, redoValue: 1) { note.text = "another" }
    }

    // MARK: - Value type capture semantics

    @Test("registerUndo captures value at undo time")
    func registerUndoCapturesValueAtUndoTime() {
        let model = Model()
        let undoManager = UndoManager()

        var value = 0
        undoManager.registerUndo(withTarget: model) {
            $0.index = value
        }
        value = 10
        undoManager.undo()
        #expect(model.index == 10)
    }

    @Test("value type explicitly captured, independent of original")
    func valueTypeCaptureIndependentOfOriginalExplicitCopy() {
        let undoManager = UndoManager()
        let model = Model()

        var restoreValue = 0

        let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
            target.index = 10
            registerUndo { [restoreValue] in
                target.replace(\.index, with: restoreValue)
            }
        }

        restoreValue = 999

        withUndoTracking(undoManager) {
            component
        }

        #expect(model.index == 10)

        cycle(undoManager: undoManager, model: model, redoValue: 10, undoValue: 999) { restoreValue = 123 }
        cycle(undoManager: undoManager, model: model, redoValue: 10, undoValue: 999) { restoreValue = 456 }
    }

    @Test("value type implicitly captured, independent of original")
    func valueTypeCaptureIndependentOfOriginal() {
        let undoManager = UndoManager()
        let model = Model()

        var restoreValue = 0

        let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
            target.index = 10
            registerUndo {
                target.replace(\.index, with: restoreValue)
            }
        }

        restoreValue = 20

        withUndoTracking(undoManager) {
            component
        }

        #expect(model.index == 10)

        cycle(undoManager: undoManager, model: model, redoValue: 10, undoValue: 20) { restoreValue = 123 }
        cycle(undoManager: undoManager, model: model, redoValue: 10, undoValue: 20) { restoreValue = 456 }
    }

    // MARK: - Multiple cycles with captured references

    @Test("multiple cycles with persistent captured reference")
    func multipleCyclesWithPersistentCapturedReference() {
        let undoManager = UndoManager()
        let model = Model()

        class Metadata {
            var label: String
            init(_ label: String) { self.label = label }
        }
        let metadata = Metadata("undo-step")

        let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
            target.index = 100
            registerUndo {
                let restoreValue = metadata.label == "undo-step" ? 0 : -1
                return target.replace(\.index, with: restoreValue)
            }
        }

        withUndoTracking(undoManager) {
            component.named("Cycles")
        }

        #expect(model.index == 100)
        #expect(metadata.label == "undo-step")

        cycle(undoManager: undoManager, model: model, redoValue: 100) { metadata.label = "changed" }
        cycle(undoManager: undoManager, model: model, redoValue: 100) { metadata.label = "reset" }
    }

    // MARK: - Multiple UndoGroups with shared state

    @Test("multiple groups share captured state, each uses execution-time value")
    func multipleGroupsSharedCapturedStateEachUsesOwnExecutionTimeValue() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        var value = 10

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("First") {
                model.replace(\.index, with: value)
            }
        }
        undoManager.endUndoGrouping()

        #expect(model.index == 10)

        value = 20

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("Second") {
                model.replace(\.index, with: value)
            }
        }
        undoManager.endUndoGrouping()

        #expect(model.index == 20)

        undoManager.undo()
        #expect(model.index == 10)
        #expect(undoManager.undoMenuItemTitle == "Undo First")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)

        undoManager.redo()
        #expect(model.index == 10)

        undoManager.redo()
        #expect(model.index == 20)
    }

    // MARK: - UndoGroup _isEmpty calls builder

    @Test("UndoGroup isEmpty calls builder with captured state")
    func isEmptyCalledWithDifferentCapturedState() {
        let undoManager = UndoManager()
        let model = Model()

        let shouldExecute = true

        let group = UndoGroup("Conditional") {
            if shouldExecute {
                model.increment()
            }
        }

        withUndoTracking(undoManager) {
            group
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Conditional")

        cycle(undoManager: undoManager, model: model, redoValue: 1) {}
        cycle(undoManager: undoManager, model: model, redoValue: 1) {}
    }

    // MARK: - Weak undoManager capture

    @Test("weak undoManager capture allows deallocation")
    func weakUndoManagerCaptureDoesNotPreventDeallocation() throws {
        let model = Model()

        var undoManager: UndoManager? = UndoManager()
        undoManager?.groupsByEvent = false

        undoManager?.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment().named("Inc")
        }
        undoManager?.endUndoGrouping()

        #expect(model.index == 1)

        undoManager = nil

        #expect(model.index == 1)
    }

    // MARK: - UndoManager reassignment

    @Test("undoManager reassignment between calls isolates stacks")
    func undoManagerReassignmentBetweenCalls() {
        let model = Model()

        var undoManager: UndoManager? = UndoManager()

        withUndoTracking(undoManager) {
            model.increment().named("First")
        }

        #expect(model.index == 1)
        #expect(undoManager?.canUndo == true)

        let oldManager = undoManager
        undoManager = UndoManager()

        withUndoTracking(undoManager) {
            model.increment().named("Second")
        }

        #expect(model.index == 2)
        #expect(undoManager?.canUndo == true)

        undoManager?.undo()
        #expect(model.index == 1)

        #expect(oldManager?.canUndo == true)
        oldManager?.undo()
        #expect(model.index == 0)
    }

    // MARK: - Helpers

    /// Runs one mutate/undo/redo/undo cycle, asserting the chain remains correct.
    private func cycle(
        undoManager: UndoManager,
        model: Model,
        redoValue: Int,
        undoValue: Int = 0,
        mutate: () -> Void
    ) {
        mutate()
        undoManager.undo()
        #expect(model.index == undoValue)
        undoManager.redo()
        #expect(model.index == redoValue)
        undoManager.undo()
        #expect(model.index == undoValue)
    }
}
