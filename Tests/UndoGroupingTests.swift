//
//  UndoGroupingTests.swift
//  UndoTracking
//

import Foundation
import Testing
import UndoTracking


@Suite
@MainActor
struct UndoGroupingTests {

    @Test func simpleGrouping() {
        let undoManager = UndoManager()
        let model = Model()

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

        #expect(undoManager.canUndo)
        #expect(undoManager.groupingLevel == 1)
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }

    @Test func nestedGrouping() {
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

    @Test func groupingWithSingleAction() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.canUndo)
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

    @Test func deepNestedGrouping() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        for _ in 0..<3 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                model.increment()
            }
            undoManager.endUndoGrouping()
        }
        undoManager.endUndoGrouping()

        #expect(model.index == 3)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.index == 0)
    }

}
