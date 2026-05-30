//
//  ArrayEdgeCaseTests.swift
//  UndoTracking
//

import Foundation
import Testing
import UndoTracking


// MARK: - removeLast edge cases

@Suite
@MainActor
struct RemoveLastEdgeCaseTests {

    @Test func removeLastZero() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.removeLast(0, from: \.content)
        }

        #expect(container.content == [1, 2, 3])
        try #require(undoManager.canUndo)

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    @Test func removeLastAll() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.removeLast(3, from: \.content)
        }

        #expect(container.content == [])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [])
    }

    @Test func removeLastAllThenUndoRedo() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4])

        withUndoTracking(undoManager) {
            container.removeLast(4, from: \.content)
        }

        #expect(container.content == [])

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4])

        undoManager.redo()
        #expect(container.content == [])
    }

}


// MARK: - remove(atOffsets:) edge cases

@Suite
@MainActor
struct RemoveAtOffsetsEdgeCaseTests {

    @Test func removeSingleOffset() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3)])

        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [1])
        }

        #expect(container.content.map(\.content) == [1, 3])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3])

        undoManager.redo()
        #expect(container.content.map(\.content) == [1, 3])
    }

    @Test func removeFirstAndLastOffsets() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])

        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [0, 4])
        }

        #expect(container.content.map(\.content) == [2, 3, 4])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])

        undoManager.redo()
        #expect(container.content.map(\.content) == [2, 3, 4])
    }

    @Test func removeNonContiguousOffsets() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5), Container(6)])

        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [0, 2, 4])
        }

        #expect(container.content.map(\.content) == [2, 4, 6])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5, 6])
    }

    @Test func removeAtOffsetsUndoRedoCycle() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])

        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [1, 2])
            .named("Remove 2-3")
        }

        #expect(container.content.map(\.content) == [1, 4, 5])

        for _ in 0..<2 {
            undoManager.undo()
            #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])

            undoManager.redo()
            #expect(container.content.map(\.content) == [1, 4, 5])
        }
    }

}


// MARK: - move edge cases

@Suite
@MainActor
struct MoveEdgeCaseTests {

    @Test func moveAllElementsToBeginning() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [2, 3, 4], toOffset: 0)
        }

        #expect(container.content.map(\.content) == [3, 4, 5, 1, 2])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])

        undoManager.redo()
        #expect(container.content.map(\.content) == [3, 4, 5, 1, 2])
    }

    @Test func moveSingleElementToEnd() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [0], toOffset: 3)
        }

        #expect(container.content.map(\.content) == [2, 3, 1])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3])
    }

    @Test func moveSingleElementToBeginning() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [2], toOffset: 0)
        }

        #expect(container.content.map(\.content) == [3, 1, 2])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3])
    }

    @Test func moveAdjacentElements() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [1, 2], toOffset: 0)
        }

        #expect(container.content.map(\.content) == [2, 3, 1, 4])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4])
    }

    @Test func moveUndoRedoCycle() throws {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [0, 3], toOffset: 2)
            .named("Move")
        }

        for _ in 0..<2 {
            undoManager.undo()
            #expect(container.content.map(\.content) == [1, 2, 3, 4])

            undoManager.redo()
        }
    }

}


// MARK: - removeAll edge cases

@Suite
@MainActor
struct RemoveAllEdgeCaseTests {

    @Test func removeAllWithAlwaysTruePredicate() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4, 5])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { _ in true })
        }

        #expect(container.content == [])

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4, 5])

        undoManager.redo()
        #expect(container.content == [])
    }

    @Test func removeAllWithAlwaysFalsePredicate() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { _ in false })
        }

        #expect(container.content == [1, 2, 3])
        try #require(undoManager.canUndo)

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    @Test func removeAllWithComplexPredicate() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { $0 > 3 && $0 < 8 })
        }

        #expect(container.content == [1, 2, 3, 8, 9, 10])

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    }

    @Test func removeAllFromSingleElement() throws {
        let undoManager = UndoManager()
        let container = Container([42])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { $0 == 42 })
        }

        #expect(container.content == [])

        undoManager.undo()
        #expect(container.content == [42])

        undoManager.redo()
        #expect(container.content == [])
    }

    @Test func removeAllUndoRedoCycle() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4, 5, 6])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { $0 % 2 == 0 })
            .named("Remove Evens")
        }

        for _ in 0..<2 {
            undoManager.undo()
            #expect(container.content == [1, 2, 3, 4, 5, 6])

            undoManager.redo()
            #expect(container.content == [1, 3, 5])
        }
    }

}


// MARK: - Append / Insert edge cases

@Suite
@MainActor
struct AppendInsertEdgeCaseTests {

    @Test func appendContentsOfSingleElement() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2])

        withUndoTracking(undoManager) {
            container.append(contentsOf: [3], to: \.content)
        }

        #expect(container.content == [1, 2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2])

        undoManager.redo()
        #expect(container.content == [1, 2, 3])
    }

    @Test func appendContentsOfLargeSequence() throws {
        let undoManager = UndoManager()
        let container = Container([Int]())

        let sequence = Array(1...1000)

        withUndoTracking(undoManager) {
            container.append(contentsOf: sequence, to: \.content)
        }

        #expect(container.content.count == 1000)
        #expect(container.content.first == 1)
        #expect(container.content.last == 1000)

        undoManager.undo()
        #expect(container.content == [])

        undoManager.redo()
        #expect(container.content.count == 1000)
    }

    @Test func insertAtStartIndex() throws {
        let undoManager = UndoManager()
        let container = Container([2, 3, 4])

        withUndoTracking(undoManager) {
            container.insert(1, at: container.content.startIndex, to: \.content)
        }

        #expect(container.content == [1, 2, 3, 4])

        undoManager.undo()
        #expect(container.content == [2, 3, 4])
    }

    @Test func insertAtEndIndexThenUndo() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        let endIndex = container.content.endIndex
        withUndoTracking(undoManager) {
            container.insert(4, at: endIndex, to: \.content)
        }

        #expect(container.content == [1, 2, 3, 4])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    @Test func removeAtStartIndex() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.remove(at: container.content.startIndex, from: \.content)
        }

        #expect(container.content == [2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

}


// MARK: - Array replace edge cases

@Suite
@MainActor
struct ArrayReplaceEdgeCaseTests {

    @Test func replaceWithSwapVerification() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.replace(\.content, at: 0, with: 99)
        }

        #expect(container.content == [99, 2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [99, 2, 3])
    }

    @Test func arrayReplaceSameValue() throws {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.replace(\.content, at: 1, with: 2)
        }

        #expect(container.content == [1, 2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

}


// MARK: - Chained undo/redo across mixed operation types

@Suite
@MainActor
struct MixedOperationEdgeCaseTests {

    @Test func appendThenRemoveLastThenUndoAll() throws {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let container = Container([1, 2])

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            container.append(3, to: \.content)
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            container.removeLast(1, from: \.content)
        }
        undoManager.endUndoGrouping()

        #expect(container.content == [1, 2])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2])

        undoManager.redo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [1, 2])
    }

    @Test func removeAllThenAppendUndoRedo() throws {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let container = Container([1, 2, 3])

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { _ in true })
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            container.append(4, to: \.content)
        }
        undoManager.endUndoGrouping()

        #expect(container.content == [4])

        undoManager.undo()
        #expect(container.content == [])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [])

        undoManager.redo()
        #expect(container.content == [4])
    }

}


// MARK: - Value replace (protocol) edge cases

@Suite
@MainActor
struct ValueReplaceEdgeCaseTests {

    @Test func replaceSinglePropertyMultipleCycles() throws {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.replace(\.index, with: 42)
            .named("Set 42")
        }

        #expect(model.index == 42)
        try #require(undoManager.undoMenuItemTitle == "Undo Set 42")

        for _ in 0..<3 {
            undoManager.undo()
            #expect(model.index == 0)

            undoManager.redo()
            #expect(model.index == 42)
        }
    }

    @Test func replaceWithSwapLeavesOriginalInRegisterUndo() throws {
        let undoManager = UndoManager()
        let model = Model()
        model.index = 5

        withUndoTracking(undoManager) {
            model.replace(\.index, with: 10)
        }

        #expect(model.index == 10)

        // Undo should restore 5 (the pre-replace value), not some intermediate state.
        undoManager.undo()
        #expect(model.index == 5)

        undoManager.redo()
        #expect(model.index == 10)
    }

    @Test func replaceWithNilUndoManager() {
        let model = Model()

        withUndoTracking(nil) {
            model.replace(\.index, with: 99)
        }

        #expect(model.index == 99)
    }

}
