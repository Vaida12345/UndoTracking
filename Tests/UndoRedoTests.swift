//
//  UndoRedoTests.swift
//  UndoTracking
//

import Foundation
import Testing
import UndoTracking


@Suite
@MainActor
struct UndoRedoTests {

    @Test func singleUndo() {
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

    @Test func undoThenNewAction() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }

        #expect(model.index == 1)
        undoManager.undo()
        #expect(model.index == 0)

        withUndoTracking(undoManager) {
            model.increment()
        }
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)

        undoManager.redo()
        #expect(model.index == 1)
    }

    @Test func redoReappliesLastAction() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
        }

        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.canRedo)

        undoManager.redo()
        #expect(model.index == 1)
        #expect(!undoManager.canRedo)
    }

    @Test func unnamedAction() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
        }

        #expect(undoManager.canUndo)
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func noActionRegistered() {
        let undoManager = UndoManager()

        withUndoTracking(undoManager) {
            nil as UndoComponent<Model>?
        }

        #expect(!undoManager.canUndo)
    }

    @Test func undoWithoutPreviousAction() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

    @Test func redoWithoutPreviousUndo() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment()
        }

        undoManager.redo()
        #expect(model.index == 1)
    }

    @Test func undoRedoCycle() {
        let undoManager = UndoManager()
        let model = Model()

        for _ in 0..<5 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                model.increment()
            }
            undoManager.endUndoGrouping()
        }

        #expect(model.index == 5)

        for _ in 0..<5 {
            undoManager.undo()
        }
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.canRedo)

        for _ in 0..<5 {
            undoManager.redo()
        }
        #expect(model.index == 5)
        #expect(!undoManager.canRedo)
        #expect(undoManager.canUndo)
    }

}
