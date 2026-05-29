//
//  UndoGroupBuilderTests.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation
import Testing
@testable import UndoTracking


@Suite
@MainActor
struct UndoGroupBuilderTests {

    // MARK: Single component (buildBlock)

    @Test func singleComponent() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
                    .named("Single")
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

    @Test func singleComponentWithoutTitle() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.canUndo)
        // No title set by the group itself (no .named on the child either).
        #expect(undoManager.undoMenuItemTitle == "Undo")

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Multiple components (variadic buildBlock)

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func multipleComponents() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Triple") {
                model.increment()
                model.increment()
                model.increment()
            }
        }

        #expect(model.index == 3)
        #expect(undoManager.undoMenuItemTitle == "Undo Triple")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 3)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func multipleComponentsWithDifferentTypes() {
        let undoManager = UndoManager()
        let container = Container([1, 2, 3])

        withUndoTracking(undoManager) {
            UndoGroup("Mixed") {
                container.append(4, to: \.content)
                container.remove(at: 0, from: \.content)
            }
        }

        // append 4 → [1,2,3,4]; remove at 0 → [2,3,4]
        #expect(container.content == [2, 3, 4])
        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Mixed")

        undoManager.undo()
        #expect(container.content == [1, 2, 3])

        undoManager.redo()
        #expect(container.content == [2, 3, 4])
    }
    
    @Test func testGroundTruth() throws {
        let undoManager = UndoManager()
        undoManager.beginUndoGrouping()
        undoManager.endUndoGrouping()
        try #require(undoManager.canUndo)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func emptyBuilder() {
        let undoManager = UndoManager()

        withUndoTracking(undoManager) {
            UndoGroup("Empty") {
                // No statements — valid with variadic buildBlock.
            }
        }

        // An empty group registers no actions, so there's nothing to undo.
        #expect(!undoManager.canUndo)
    }

    // MARK: if/else (buildEither)

    @Test func ifTrueBranch() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Conditional") {
                if true {
                    model.increment()
                        .named("TrueBranch")
                } else {
                    model.decrement()
                        .named("FalseBranch")
                }
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Conditional")

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func ifFalseBranch() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Conditional") {
                if false {
                    model.increment()
                        .named("TrueBranch")
                } else {
                    model.decrement()
                        .named("FalseBranch")
                }
            }
        }

        #expect(model.index == -1)
        #expect(undoManager.undoMenuItemTitle == "Undo Conditional")

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func ifElseWithVariableCondition() {
        for flag in [true, false] {
            let um = UndoManager()
            let m = Model()

            withUndoTracking(um) {
                UndoGroup {
                    if flag {
                        m.increment()
                    } else {
                        m.decrement()
                    }
                }
            }

            if flag {
                #expect(m.index == 1)
            } else {
                #expect(m.index == -1)
            }

            um.undo()
            #expect(m.index == 0)
        }
    }

    // MARK: Optional binding (buildOptional)

    @Test func optionalBindingWithValue() {
        let undoManager = UndoManager()
        let model = Model()
        let optionalValue: Int? = 42

        withUndoTracking(undoManager) {
            UndoGroup("Optional") {
                if let _ = optionalValue {
                    model.increment()
                        .named("HasValue")
                }
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Optional")

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func optionalBindingWithNil() {
        let undoManager = UndoManager()
        let model = Model()
        let optionalValue: Int? = nil

        withUndoTracking(undoManager) {
            UndoGroup("Optional") {
                if let _ = optionalValue {
                    model.increment()
                        .named("HasValue")
                }
                // No else branch — the builder produces nil for this branch.
                model.increment()
                    .named("Always")
            }
        }

        // The optional branch produced nothing; only "Always" executed.
        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Optional")

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func optionalBindingNilWithElseBranch() {
        let undoManager = UndoManager()
        let model = Model()
        let optionalValue: Int? = nil

        withUndoTracking(undoManager) {
            UndoGroup {
                if let _ = optionalValue {
                    model.increment().named("HasValue")
                }
            }
        }

        // No statements executed, group is empty.
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

    @Test func ifWithoutElseWhenFalse() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                if false {
                    model.increment()
                        .named("Skipped")
                }
                model.increment()
                    .named("Always")
            }
        }

        // Only "Always" executed.
        #expect(model.index == 1)
        // Untitled group, child name no propagate.
        #expect(undoManager.undoMenuItemTitle == "Undo")

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: ForEach / loops (buildArray)

    @Test func forEachLoop() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("ForEach") {
                for _ in 0..<5 {
                    model.increment()
                }
            }
        }

        #expect(model.index == 5)
        #expect(undoManager.undoMenuItemTitle == "Undo ForEach")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 5)
    }

    @Test func forEachEmptyCollection() {
        let undoManager = UndoManager()
        let model = Model()
        let empty: [Int] = []

        withUndoTracking(undoManager) {
            UndoGroup("EmptyLoop") {
                for _ in empty {
                    model.increment()
                }
            }
        }

        // No iterations, nothing executed.
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

    @Test func forEachWithSingleElement() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                for _ in 0..<1 {
                    model.increment().named("Solo")
                }
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo")

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func forEachWithConditionalInside() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("ForEachIf") {
                for i in 0..<4 {
                    if i % 2 == 0 {
                        model.increment()
                    } else {
                        model.decrement()
                    }
                }
            }
        }

        // i=0: inc → 1; i=1: dec → 0; i=2: inc → 1; i=3: dec → 0.
        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo ForEachIf")

        undoManager.undo()
        #expect(model.index == 0) // Undo reverses each operation, net still 0.

        undoManager.redo()
        #expect(model.index == 0)
    }

    // MARK: Nested conditionals

    @Test func nestedIfElse() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Nested") {
                if true {
                    if true {
                        model.increment()
                    } else {
                        model.decrement()
                    }
                } else {
                    model.decrement()
                }
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.undoMenuItemTitle == "Undo Nested")

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func ifElseWithIfLetInside() {
        let undoManager = UndoManager()
        let model = Model()
        let value: Int? = 99

        withUndoTracking(undoManager) {
            UndoGroup {
                if let v = value {
                    if v > 50 {
                        model.increment()
                    } else {
                        model.decrement()
                    }
                } else {
                    model.decrement()
                }
            }
        }

        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func ifElseChain() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Chain") {
                if false {
                    model.increment()
                } else if true {
                    model.increment()
                    model.increment()
                } else {
                    model.decrement()
                }
            }
        }

        #expect(model.index == 2)
        #expect(undoManager.undoMenuItemTitle == "Undo Chain")

        undoManager.undo()
        #expect(model.index == 0)
    }
    
    @Test func empty() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Empty") {
                
            }
        }

        #expect(model.index == 0)
        #expect(undoManager.undoMenuItemTitle == "Undo")

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: Complex compositions

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func complexComposition() {
        let undoManager = UndoManager()
        let model = Model()
        let shouldIncrement = true

        withUndoTracking(undoManager) {
            UndoGroup("Complex") {
                model.increment()
                    .named("First")

                if shouldIncrement {
                    model.increment()
                    model.increment()
                } else {
                    model.decrement()
                }

                for _ in 0..<2 {
                    model.increment()
                }

                if let _ = Optional(1) {
                    model.decrement()
                }
            }
        }

        // First: +1; if true: +2; loop: +2; if let: -1; total: 4
        #expect(model.index == 4)
        #expect(undoManager.undoMenuItemTitle == "Undo Complex")

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 4)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func complexCompositionWithMixedTypes() {
        let undoManager = UndoManager()
        let model = Model()
        let container = Container([10, 20, 30])

        withUndoTracking(undoManager) {
            UndoGroup("AllTypes") {
                model.increment()
                container.append(40, to: \.content)
                container.remove(at: 0, from: \.content)
                model.decrement()
            }
        }

        // model: inc → 1, dec → 0
        // container: append 40 → [10,20,30,40]; remove at 0 → [20,30,40]
        #expect(model.index == 0)
        #expect(container.content == [20, 30, 40])
        #expect(undoManager.undoMenuItemTitle == "Undo AllTypes")

        undoManager.undo()
        #expect(model.index == 0)
        #expect(container.content == [10, 20, 30])

        undoManager.redo()
        #expect(model.index == 0)
        #expect(container.content == [20, 30, 40])
    }

    // MARK: buildArray with array variable

    @Test func buildArrayWithPrebuiltArray() {
        let undoManager = UndoManager()
        let model = Model()

        let components = [
            model.increment().named("One"),
            model.increment().named("Two"),
            model.increment().named("Three"),
        ]

        withUndoTracking(undoManager) {
            UndoGroup("FromArray") {
                for component in components {
                    component
                }
            }
        }

        #expect(model.index == 3)
        #expect(undoManager.undoMenuItemTitle == "Undo FromArray")

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: buildOptional returning nil for the entire builder

    @Test func buildOptionalAllBranchesNil() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                if false {
                    model.increment()
                }
            }
        }

        // No statements executed, no actions registered.
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

}
