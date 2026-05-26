//
//  ValueReplacementTests.swift
//  UndoTracking
//

import Foundation
import Testing
import UndoTracking


final class StructModel: UndoTracking {

    var inner = Inner(value: 0)

    struct Inner {
        var value: Int
    }

}


@Suite
@MainActor
struct ValueReplacementTests {

    @Test func replaceValue() {
        let undoManager = UndoManager()
        let model = StructModel()

        withUndoTracking(undoManager) {
            model.replace(\.inner, with: StructModel.Inner(value: 42))
        }

        #expect(model.inner.value == 42)

        undoManager.undo()
        #expect(model.inner.value == 0)

        undoManager.redo()
        #expect(model.inner.value == 42)
    }

    @Test func replaceIndexValue() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.replace(\.index, with: 99)
        }

        #expect(model.index == 99)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 99)
    }

    @Test func replacementRoundTrip() {
        let undoManager = UndoManager()
        let model = StructModel()

        withUndoTracking(undoManager) {
            model.replace(\.inner, with: StructModel.Inner(value: 10))
        }
        withUndoTracking(undoManager) {
            model.replace(\.inner, with: StructModel.Inner(value: 20))
        }

        #expect(model.inner.value == 20)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.inner.value == 0)
        #expect(!undoManager.canUndo)

        undoManager.redo()
        #expect(model.inner.value == 20)
    }

    @Test func replaceWithSameValue() {
        let undoManager = UndoManager()
        let model = Model()
        model.index = 5

        withUndoTracking(undoManager) {
            model.replace(\.index, with: 5)
        }

        #expect(model.index == 5)

        undoManager.undo()
        #expect(model.index == 5)
    }

}
