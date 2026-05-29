//
//  ArrayOperationsTests.swift
//  UndoTracking
//

import Foundation
import Testing
import UndoTracking


@Suite
@MainActor
struct ArrayOperationsTests {

    // MARK: Append

    @Test func appendSingleElement() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.append(4, to: \.content)
        }

        #expect(container.content == [1, 2, 3, 4])
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [1, 2, 3, 4])
    }

    @Test func appendToEmptyArray() {
        let undoManager = UndoManager()
        let container = Container([Int]())

        withUndoTracking(undoManager) {
            container.append(1, to: \.content)
        }

        #expect(container.content == [1])

        undoManager.undo()
        #expect(container.content == [])
    }

    // MARK: Append Contents Of

    @Test func appendContentsOf() {
        let undoManager = UndoManager()
        let container = Container([1, 2])

        withUndoTracking(undoManager) {
            container.append(contentsOf: [3, 4, 5], to: \.content)
        }

        #expect(container.content == [1, 2, 3, 4, 5])
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(container.content == [1, 2])

        undoManager.redo()
        #expect(container.content == [1, 2, 3, 4, 5])
    }

    @Test func appendContentsOfEmptySequence() {
        let undoManager = UndoManager()
        let container = Container([1, 2])

        withUndoTracking(undoManager) {
            container.append(contentsOf: [Int](), to: \.content)
        }

        #expect(container.content == [1, 2])

        undoManager.undo()
        #expect(container.content == [1, 2])
    }

    // MARK: Insert

    @Test func insertAtBeginning() {
        let undoManager = UndoManager()
        let container = Container([2, 3, 4])

        withUndoTracking(undoManager) {
            container.insert(1, at: 0, to: \.content)
        }

        #expect(container.content == [1, 2, 3, 4])

        undoManager.undo()
        #expect(container.content == [2, 3, 4])

        undoManager.redo()
        #expect(container.content == [1, 2, 3, 4])
    }

    @Test func insertAtMiddle() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 4, 5])

        withUndoTracking(undoManager) {
            container.insert(3, at: 2, to: \.content)
        }

        #expect(container.content == [1, 2, 3, 4, 5])

        undoManager.undo()
        #expect(container.content == [1, 2, 4, 5])
    }

    @Test func insertAtEnd() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.insert(4, at: container.content.endIndex, to: \.content)
        }

        #expect(container.content == [1, 2, 3, 4])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    // MARK: Remove at Index

    @Test func removeAtIndex() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4, 5])

        withUndoTracking(undoManager) {
            container.remove(at: 2, from: \.content)
        }

        #expect(container.content == [1, 2, 4, 5])

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4, 5])

        undoManager.redo()
        #expect(container.content == [1, 2, 4, 5])
    }

    @Test func removeAtFirstIndex() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.remove(at: 0, from: \.content)
        }

        #expect(container.content == [2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    @Test func removeAtLastIndex() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.remove(at: 2, from: \.content)
        }

        #expect(container.content == [1, 2])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    // MARK: Remove by ID

    @Test func removeByID() {
        let undoManager = UndoManager()
        let container = Container([Item(id: 1, value: "a"), Item(id: 2, value: "b"), Item(id: 3, value: "c")])

        withUndoTracking(undoManager) {
            container.remove(2, from: \.content)
        }

        #expect(container.content.map(\.id) == [1, 3])

        undoManager.undo()
        #expect(container.content.map(\.id) == [1, 2, 3])

        undoManager.redo()
        #expect(container.content.map(\.id) == [1, 3])
    }

    @Test func removeByElement() {
        let undoManager = UndoManager()
        let container = Container([Item(id: 1, value: "a"), Item(id: 2, value: "b")])
        let itemToRemove = container.content[0]

        withUndoTracking(undoManager) {
            container.remove(itemToRemove, from: \.content)
        }

        #expect(container.content.map(\.id) == [2])

        undoManager.undo()
        #expect(container.content.map(\.id) == [1, 2])
    }

    // MARK: Remove All Where

    @Test func removeAllWhere() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4, 5, 6])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { $0 % 2 == 0 })
        }

        #expect(container.content == [1, 3, 5])

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4, 5, 6])

        undoManager.redo()
        #expect(container.content == [1, 3, 5])
    }

    @Test func removeAllWhereNoneMatch() {
        let undoManager = UndoManager()
        let container = Container([1, 3, 5])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { $0 % 2 == 0 })
        }

        #expect(container.content == [1, 3, 5])

        undoManager.undo()
        #expect(container.content == [1, 3, 5])
    }

    @Test func removeAllWhereAllMatch() {
        let undoManager = UndoManager()
        let container = Container([2, 4, 6])

        withUndoTracking(undoManager) {
            container.removeAll(from: \.content, where: { $0 % 2 == 0 })
        }

        #expect(container.content == [])

        undoManager.undo()
        #expect(container.content == [2, 4, 6])
    }

    // MARK: Remove Last

    @Test func removeLast() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4, 5])

        withUndoTracking(undoManager) {
            container.removeLast(2, from: \.content)
        }

        #expect(container.content == [1, 2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4, 5])

        undoManager.redo()
        #expect(container.content == [1, 2, 3])
    }

    @Test func removeLastOne() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.removeLast(1, from: \.content)
        }

        #expect(container.content == [1, 2])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    // MARK: Replace at Index

    @Test func replaceAtIndex() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.replace(\.content, at: 1, with: 99)
        }

        #expect(container.content == [1, 99, 3])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [1, 99, 3])
    }

    @Test func replaceAtFirstIndex() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.replace(\.content, at: 0, with: 99)
        }

        #expect(container.content == [99, 2, 3])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    @Test func replaceAtLastIndex() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            container.replace(\.content, at: 2, with: 99)
        }

        #expect(container.content == [1, 2, 99])

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
    }

    // MARK: Move

    @Test func moveElements() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [3, 4], toOffset: 0)
        }

        #expect(container.content.map(\.content) == [4, 5, 1, 2, 3])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])

        undoManager.redo()
        #expect(container.content.map(\.content) == [4, 5, 1, 2, 3])
    }

    @Test func moveElementsToEnd() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [0, 1], toOffset: 5)
        }

        #expect(container.content.map(\.content) == [3, 4, 5, 1, 2])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])
    }

    @Test func moveSingleElement() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3)])

        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [0], toOffset: 3)
        }

        #expect(container.content.map(\.content) == [2, 3, 1])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3])
    }

    // MARK: Remove at Offsets

    @Test func removeAtOffsets() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])

        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [1, 3])
        }

        #expect(container.content.map(\.content) == [1, 3, 5])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])

        undoManager.redo()
        #expect(container.content.map(\.content) == [1, 3, 5])
    }

    @Test func removeAtOffsetsEmpty() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2)])

        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [])
        }

        #expect(container.content.map(\.content) == [1, 2])

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2])
    }

    @Test func removeAtAllOffsets() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3)])

        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [0, 1, 2])
        }

        #expect(container.content.isEmpty)

        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3])
    }

    // MARK: Chained Operations

    @Test func chainedArrayOperations() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            container.append(4, to: \.content)
        }
        withUndoTracking(undoManager) {
            container.remove(at: 1, from: \.content)
        }
        withUndoTracking(undoManager) {
            container.insert(99, at: 0, to: \.content)
        }
        undoManager.endUndoGrouping()

        #expect(container.content == [99, 1, 3, 4])
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(container.content == [1, 2, 3])
        #expect(!undoManager.canUndo)
        #expect(undoManager.canRedo)

        undoManager.redo()
        #expect(container.content == [99, 1, 3, 4])
    }

}
