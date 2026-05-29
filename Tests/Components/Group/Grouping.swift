//
//  Grouping.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation
import Testing
@testable import UndoTracking


// MARK: - UndoGrouping Suite

@Suite
@MainActor
struct UndoGrouping {
    
    @Test func testContextDescription() {
        #expect(_UndoComponentContext(animated: true, title: "123").description == "Content(123, animate)")
        #expect(_UndoComponentContext(title: "123").description == "Content(123)")
        #expect(_UndoComponentContext(animated: true).description == "Content(animate)")
        #expect(_UndoComponentContext().description == "Content()")
    }

    // MARK: Basic grouping

    @Test func undoGroupingBasic() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Increment Twice") {
                model.increment()
                model.increment()
            }
        }

        #expect(undoManager.canUndo)
        #expect(model.index == 2)

        #expect(undoManager.undoMenuItemTitle == "Undo Increment Twice")
        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }

    @Test func undoGroupOverrideChildTitle() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Increment Twice") {
                model.increment()
                    .named("12345")
                model.increment()
                    .named("67890")
            }
        }

        #expect(undoManager.canUndo)
        #expect(model.index == 2)

        #expect(undoManager.undoMenuItemTitle == "Undo Increment Twice")
        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }

    /// When an UndoGroup has no title, children's names should not propagate.
    @Test func emptyUndoGroupNoOverrideChildTitle() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
                    .named("12345")
                model.increment()
                    .named("67890")
            }
        }

        #expect(undoManager.canUndo)
        #expect(model.index == 2)

        // The last child's name should win when the group has no title.
        #expect(undoManager.undoMenuItemTitle == "Undo")
        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }

    // MARK: .named() modifier

    @Test func undoGroupNamedMethodChangesTitle() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Original") {
                model.increment()
            }
            .named("Changed")
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Changed")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Changed")
    }

    @Test func undoGroupNamedOverridesChildNames() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
                    .named("Child")
            }
            .named("Parent")
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Parent")
        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Parent")
    }

    @Test func undoGroupNamedWithNilTitleThenNamed() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
                model.increment()
            }
            .named("Retroactive")
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Retroactive")
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: .animated() modifier

    @Test func undoGroupAnimatedTrueExecutesActions() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
                model.increment()
            }
            .animated(true)
        }

        #expect(model.index == 2)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }

    @Test func undoGroupAnimatedFalseExecutesActions() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
                model.decrement()
            }
            .animated(false)
        }

        #expect(model.index == 0)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.index == 0) // increment then decrement, undo reverses both

        undoManager.redo()
        #expect(model.index == 0)
    }

    @Test func undoGroupAnimatedDefaultPropagates() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Default Animated") {
                model.increment()
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.canUndo)
        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Chained modifiers

    @Test func chainedNamedThenAnimated() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
            }
            .named("Test")
            .animated(true)
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Test")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Test")
    }

    @Test func chainedAnimatedThenNamed() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
            }
            .animated(false)
            .named("Explicit")
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Explicit")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Single child

    @Test func undoGroupWithSingleChild() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Solo") {
                model.increment()
                    .named("Child")
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Solo")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

    @Test func undoTitledGroupWithSingleUntitledChild() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Outer") {
                model.increment()
            }
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Outer")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Many children

    @Test func undoGroupWithManyChildren() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Many") {
                for _ in 0..<10 {
                    model.increment()
                }
            }
        }

        #expect(model.index == 10)
        #expect(undoManager.undoMenuItemTitle == "Undo Many")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 10)
    }

    // MARK: Nested UndoGroups

    @Test func nestedUndoGroupOuterTitleWins() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Outer") {
                UndoGroup("Inner") {
                    model.increment()
                        .named("Child")
                }
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Outer")

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func nestedUndoGroupOuterUntitledInnerTitleShines() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                UndoGroup("Inner") {
                    model.increment()
                }
            }
        }

        // The outer group has no title, so the inner group's title should be used.
        #expect(undoManager.undoMenuItemTitle == "Undo")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func nestedUndoGroupInnerUntitledChildNamePropagates() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                UndoGroup {
                    model.increment()
                        .named("DeepChild")
                }
            }
        }

        // Both groups are untitled, the child's name should propagate all the way up.
        #expect(undoManager.undoMenuItemTitle == "Undo")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func deeplyNestedUndoGroups() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Level1") {
                UndoGroup("Level2") {
                    UndoGroup("Level3") {
                        UndoGroup("Level4") {
                            model.increment()
                                .named("Bottom")
                        }
                    }
                }
            }
        }

        // Outermost title wins.
        #expect(undoManager.undoMenuItemTitle == "Undo Level1")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

    // MARK: Interaction with UndoManager groups

    @Test func undoGroupInsideUndoManagerGroup() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("Inner") {
                model.increment()
            }
        }
        withUndoTracking(undoManager) {
            model.increment()
                .named("OuterChild")
        }
        undoManager.endUndoGrouping()

        // Outer UndoManager group should use the title of its last named action.
        #expect(undoManager.undoMenuItemTitle == "Undo OuterChild")
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func undoGroupInsideUntitledUndoManagerGroup() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("Inner") {
                model.increment()
            }
        }
        undoManager.endUndoGrouping()

        // The UndoManager group has no title; UndoGroup's title should be used.
        #expect(undoManager.undoMenuItemTitle == "Undo Inner")
        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Multiple sequential UndoGroups

    @Test func multipleSequentialUndoGroups() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("First") {
                model.increment()
            }
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("Second") {
                model.increment()
            }
        }
        undoManager.endUndoGrouping()

        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Second")

        undoManager.undo()
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo First")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

    @Test func multipleSequentialUndoGroupsRedoOrder() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        for i in 1...3 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                UndoGroup("Step \(i)") {
                    model.increment()
                }
            }
            undoManager.endUndoGrouping()
        }

        #expect(model.index == 3)

        // Undo all.
        for _ in 1...3 { undoManager.undo() }
        #expect(model.index == 0)

        // Redo in order.
        for i in 1...3 {
            #expect(undoManager.redoMenuItemTitle == "Redo Step \(i)")
            undoManager.redo()
        }
        #expect(model.index == 3)
        #expect(!undoManager.canRedo)
    }

    // MARK: Undo/Redo cycle with UndoGroup

    @Test func undoGroupUndoRedoTitleCycle() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Cycle") {
                model.increment()
                model.increment()
            }
        }

        for _ in 0..<3 {
            #expect(undoManager.undoMenuItemTitle == "Undo Cycle")
            #expect(model.index == 2)

            undoManager.undo()
            #expect(undoManager.canRedo)
            #expect(undoManager.redoMenuItemTitle == "Redo Cycle")
            #expect(model.index == 0)

            undoManager.redo()
            #expect(undoManager.undoMenuItemTitle == "Undo Cycle")
            #expect(model.index == 2)
        }
    }

    @Test func undoGroupClearsRedoOnNewAction() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("First") { model.increment() }
        }
        undoManager.endUndoGrouping()

        #expect(model.index == 1)
        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.canRedo)

        // New action clears redo stack.
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("Second") { model.increment() }
        }
        undoManager.endUndoGrouping()

        #expect(model.index == 1)
        #expect(!undoManager.canRedo)
        #expect(undoManager.undoMenuItemTitle == "Undo Second")
    }

    // MARK: Nil children handling

    @Test func undoGroupWithNilChildDoesNotAffectState() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Mixed") {
                model.increment()
                    .named("Real")

                if false {
                    model.increment()
                }

                model.increment()
            }
        }

        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Mixed")

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Mixed named/unnamed children

    @Test func undoGroupWithAllUnnamedChildren() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
                model.increment()
                model.increment()
            }
        }

        // No title set by group or children, defaults to "Undo".
        #expect(undoManager.undoMenuItemTitle == "Undo")
        #expect(model.index == 3)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo")
    }

    // MARK: withUndoTracking nil builder

    @Test func withUndoTrackingNilBuilderDoesNothing() {
        let undoManager = UndoManager()

        withUndoTracking(undoManager) {
            nil as UndoComponent<Model>?
        }

        #expect(!undoManager.canUndo)
    }

    @Test func withUndoTrackingNilBuilderDoesNotAffectExistingStack() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment().named("Real")
        }

        withUndoTracking(undoManager) {
            nil as UndoComponent<Model>?
        }

        #expect(undoManager.undoMenuItemTitle == "Undo Real")
        #expect(model.index == 1)
    }

    // MARK: Increment/decrement mix in UndoGroup

    @Test func undoGroupWithIncrementAndDecrement() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Mix") {
                model.increment()
                model.increment()
                model.decrement()
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Mix")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

    @Test func undoGroupWithDecrementOnly() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Down") {
                model.decrement()
                model.decrement()
            }
        }

        #expect(model.index == -2)
        #expect(undoManager.undoMenuItemTitle == "Undo Down")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.redoMenuItemTitle == "Redo Down")

        undoManager.redo()
        #expect(model.index == -2)
    }

    // MARK: groupsByEvent interaction

    @Test func undoGroupWithGroupsByEventFalse() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            UndoGroup("Explicit") {
                model.increment()
                model.increment()
            }
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.groupingLevel == 0)
        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Explicit")

        undoManager.undo()
        #expect(model.index == 0)
    }

}
