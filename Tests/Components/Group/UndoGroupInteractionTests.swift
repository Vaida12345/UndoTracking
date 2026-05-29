//
//  UndoGroupInteractionTests.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation
import Testing
@testable import UndoTracking


@Suite
@MainActor
struct UndoGroupInteractionTests {

    // MARK: Container operations inside UndoGroup

    @Test func groupWithAppendOperation() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            UndoGroup("Append") {
                container.append(4, to: \.content)
                container.append(5, to: \.content)
            }
        }

        #expect(container.content == [1, 2, 3, 4, 5])
        #expect(undoManager.undoMenuItemTitle == "Undo Append")

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [1, 2, 3, 4, 5])
    }

    @Test func groupWithInsertAndRemoveOperations() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4])

        withUndoTracking(undoManager) {
            UndoGroup("InsertRemove") {
                container.insert(99, at: 2, to: \.content)
                container.remove(at: 0, from: \.content)
            }
        }

        // Insert 99 at 2: [1, 2, 99, 3, 4]; remove at 0: [2, 99, 3, 4]
        #expect(container.content == [2, 99, 3, 4])
        #expect(undoManager.undoMenuItemTitle == "Undo InsertRemove")

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4])

        undoManager.redo()
        #expect(container.content == [2, 99, 3, 4])
    }

    @Test func groupWithReplaceOperation() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Replace") {
                model.replace(\.index, with: 42)
            }
        }

        #expect(model.index == 42)
        #expect(undoManager.undoMenuItemTitle == "Undo Replace")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 42)
    }

    @Test func groupWithRemoveAllWhere() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3, 4, 5, 6])

        withUndoTracking(undoManager) {
            UndoGroup("RemoveEven") {
                container.removeAll(from: \.content, where: { $0 % 2 == 0 })
            }
        }

        #expect(container.content == [1, 3, 5])
        #expect(undoManager.undoMenuItemTitle == "Undo RemoveEven")

        undoManager.undo()
        #expect(container.content == [1, 2, 3, 4, 5, 6])

        undoManager.redo()
        #expect(container.content == [1, 3, 5])
    }

    @Test func groupWithRemoveByID() {
        let undoManager = UndoManager()
        let container = Container([Item(id: 1, value: "a"), Item(id: 2, value: "b"), Item(id: 3, value: "c")])

        withUndoTracking(undoManager) {
            UndoGroup("RemoveID") {
                container.remove(2, from: \.content)
            }
        }

        #expect(container.content.map(\.id) == [1, 3])

        undoManager.undo()
        #expect(container.content.map(\.id) == [1, 2, 3])
    }

    // MARK: Multiple kinds of operations in one group

    @Test func groupWithMultipleKindsOfOperations() {
        let undoManager = UndoManager()
        let model = Model()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            UndoGroup("MultiKind") {
                model.increment()
                container.append(4, to: \.content)
                model.increment()
                container.remove(at: 0, from: \.content)
            }
        }

        #expect(model.index == 2)
        #expect(container.content == [2, 3, 4])
        #expect(undoManager.undoMenuItemTitle == "Undo MultiKind")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(model.index == 2)
        #expect(container.content == [2, 3, 4])
    }

    // MARK: UndoManager without manager

    @Test func groupWithNilUndoManager() {
        let model = Model()

        withUndoTracking(nil) {
            UndoGroup("NoManager") {
                model.increment()
                model.increment()
            }
        }

        // Actions execute but no undo is registered.
        #expect(model.index == 2)
    }

    @Test func groupWithNilUndoManagerUndoDoesNothing() {
        let undoManager: UndoManager? = nil
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("NoManager") {
                model.increment()
            }
        }

        #expect(model.index == 1)
    }

    // MARK: Rapid undo/redo with groups

    @Test func rapidUndoRedoCyclesWithGroup() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        for i in 1...10 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                UndoGroup("Step \(i)") {
                    model.increment()
                }
            }
            undoManager.endUndoGrouping()
        }

        #expect(model.index == 10)

        for _ in 0..<5 { undoManager.undo() }
        #expect(model.index == 5)

        for _ in 0..<3 { undoManager.redo() }
        #expect(model.index == 8)

        for _ in 0..<8 { undoManager.undo() }
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

    @Test func groupUndoAllThenRedoAll() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        for i in 1...20 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                UndoGroup("Batch \(i)") {
                    model.increment()
                    model.increment()
                }
            }
            undoManager.endUndoGrouping()
        }

        #expect(model.index == 40)

        while undoManager.canUndo { undoManager.undo() }
        #expect(model.index == 0)

        while undoManager.canRedo { undoManager.redo() }
        #expect(model.index == 40)
        #expect(!undoManager.canRedo)
    }

    // MARK: Group with large number of children

    @Test func groupWithLargeNumberOfChildren() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Large") {
                for _ in 0..<100 {
                    model.increment()
                }
            }
        }

        #expect(model.index == 100)
        #expect(undoManager.undoMenuItemTitle == "Undo Large")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 100)
    }

    // MARK: Mixed model and container in nested groups

    @Test func nestedGroupsWithModelAndContainer() {
        let undoManager = UndoManager()
        let model = Model()
        let container = Container([1, 2])

        withUndoTracking(undoManager) {
            UndoGroup("Outer") {
                UndoGroup("ModelWork") {
                    model.increment()
                    model.increment()
                }
                UndoGroup("ContainerWork") {
                    container.append(3, to: \.content)
                    container.append(4, to: \.content)
                }
            }
        }

        #expect(model.index == 2)
        #expect(container.content == [1, 2, 3, 4])
        #expect(undoManager.undoMenuItemTitle == "Undo Outer")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(container.content == [1, 2])

        undoManager.redo()
        #expect(model.index == 2)
        #expect(container.content == [1, 2, 3, 4])
    }

    // MARK: Group context propagation

    @Test func undoGroupNamedInsideNamedGroupDoesNotOverride() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Outer") {
                UndoGroup("Inner") {
                    model.increment()
                        .named("DeepChild")
                }
                model.increment()
                    .named("OuterChild")
            }
        }

        // Outer title should win even though children have names.
        #expect(undoManager.undoMenuItemTitle == "Undo Outer")
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func isInsideGroupPreventsChildOverride() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Fixed") {
                model.increment().named("Attempt1")
                model.increment().named("Attempt2")
                model.increment().named("Attempt3")
            }
        }

        // Group title "Fixed" should prevent any child from overriding.
        #expect(undoManager.undoMenuItemTitle == "Undo Fixed")
        #expect(model.index == 3)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Fixed")
    }

    // MARK: Explicit undo/redo labels persist through group undo/redo

    @Test func explicitLabelsPersistThroughGroupUndoRedo() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("A") { model.increment() }
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("B") { model.increment() }
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.undoMenuItemTitle == "Undo B")
        
        undoManager.undo()
        #expect(undoManager.undoMenuItemTitle == "Undo A")
        #expect(undoManager.redoMenuItemTitle == "Redo B")

        undoManager.redo()
        #expect(undoManager.undoMenuItemTitle == "Undo B")
        
        #expect(!undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo")
    }

}
