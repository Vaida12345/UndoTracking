//
//  MultiPropertyReplaceTests.swift
//  UndoTracking
//

import Foundation
import Testing
import UndoTracking


final class MultiPropModel: UndoTracking {

    var intValue: Int = 0
    var stringValue: String = "initial"
    var doubleValue: Double = 1.0
    var boolValue: Bool = false
    var arrayValue: [Int] = [1, 2, 3]

}


// MARK: - Two-property replace

@Suite
@MainActor
struct TwoPropertyReplaceTests {

    @Test func basicUndoRedo() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 42,
                \.stringValue, with: "updated"
            )
        }

        #expect(model.intValue == 42)
        #expect(model.stringValue == "updated")

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")

        undoManager.redo()
        #expect(model.intValue == 42)
        #expect(model.stringValue == "updated")
    }

    @Test func namedAction() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.doubleValue, with: 3.14,
                \.boolValue, with: true
            )
            .named("Update Two")
        }

        try #require(undoManager.undoMenuItemTitle == "Undo Update Two")
        #expect(model.doubleValue == 3.14)
        #expect(model.boolValue == true)

        undoManager.undo()
        #expect(model.doubleValue == 1.0)
        #expect(model.boolValue == false)
        try #require(undoManager.redoMenuItemTitle == "Redo Update Two")

        undoManager.redo()
        #expect(model.doubleValue == 3.14)
        #expect(model.boolValue == true)
    }

    @Test func undoRedoCycle() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 100,
                \.stringValue, with: "cycle"
            )
        }

        for _ in 0..<3 {
            #expect(model.intValue == 100)
            #expect(model.stringValue == "cycle")

            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")

            undoManager.redo()
            #expect(model.intValue == 100)
            #expect(model.stringValue == "cycle")
        }
    }

    @Test func replaceWithSameValues() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()
        model.intValue = 5
        model.stringValue = "same"

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 5,
                \.stringValue, with: "same"
            )
        }

        #expect(model.intValue == 5)
        #expect(model.stringValue == "same")

        undoManager.undo()
        #expect(model.intValue == 5)
        #expect(model.stringValue == "same")
    }

    @Test func insideUndoGroup() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            UndoGroup("Grouped Replace") {
                model.replace(
                    \.intValue, with: 10,
                    \.arrayValue, with: [4, 5]
                )
            }
        }

        #expect(model.intValue == 10)
        #expect(model.arrayValue == [4, 5])
        try #require(undoManager.undoMenuItemTitle == "Undo Grouped Replace")

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.arrayValue == [1, 2, 3])

        undoManager.redo()
        #expect(model.intValue == 10)
        #expect(model.arrayValue == [4, 5])
    }

    @Test func multipleSequentialReplaces() throws {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = MultiPropModel()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 1,
                \.stringValue, with: "first"
            )
            .named("First")
        }
        undoManager.endUndoGrouping()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 2,
                \.stringValue, with: "second"
            )
            .named("Second")
        }
        undoManager.endUndoGrouping()

        #expect(model.intValue == 2)
        #expect(model.stringValue == "second")
        try #require(undoManager.undoMenuItemTitle == "Undo Second")

        undoManager.undo()
        #expect(model.intValue == 1)
        #expect(model.stringValue == "first")
        try #require(undoManager.undoMenuItemTitle == "Undo First")

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")

        undoManager.redo()
        #expect(model.intValue == 1)
        #expect(model.stringValue == "first")

        undoManager.redo()
        #expect(model.intValue == 2)
        #expect(model.stringValue == "second")
    }

    @Test func atomicUndoRestoresBothPropertiesTogether() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 99,
                \.boolValue, with: true
            )
        }

        // A single undo must restore both — if there were 2 separate undo
        // entries, the first undo would restore only one property.
        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.boolValue == false)

        // After a single undo, nothing left to undo.
        try #require(!undoManager.canUndo)
    }

    @Test func animatedModifier() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 50,
                \.doubleValue, with: 2.5
            )
            .animated()
        }

        #expect(model.intValue == 50)
        #expect(model.doubleValue == 2.5)

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.doubleValue == 1.0)

        undoManager.redo()
        #expect(model.intValue == 50)
        #expect(model.doubleValue == 2.5)
    }

}


// MARK: - Three-property replace

@Suite
@MainActor
struct ThreePropertyReplaceTests {

    @Test func basicUndoRedo() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 10,
                \.stringValue, with: "triple",
                \.boolValue, with: true
            )
        }

        #expect(model.intValue == 10)
        #expect(model.stringValue == "triple")
        #expect(model.boolValue == true)

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        #expect(model.boolValue == false)

        undoManager.redo()
        #expect(model.intValue == 10)
        #expect(model.stringValue == "triple")
        #expect(model.boolValue == true)
    }

    @Test func undoRedoCycle() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 7,
                \.doubleValue, with: 7.7,
                \.arrayValue, with: [7]
            )
            .named("Triple 7")
        }

        for _ in 0..<2 {
            #expect(model.intValue == 7)
            #expect(model.doubleValue == 7.7)
            #expect(model.arrayValue == [7])
            try #require(undoManager.undoMenuItemTitle == "Undo Triple 7")

            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.doubleValue == 1.0)
            #expect(model.arrayValue == [1, 2, 3])
            try #require(undoManager.redoMenuItemTitle == "Redo Triple 7")

            undoManager.redo()
        }
    }

    @Test func insideUndoGroup() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            UndoGroup("Triple") {
                model.replace(
                    \.intValue, with: 3,
                    \.stringValue, with: "three",
                    \.boolValue, with: true
                )
            }
        }

        #expect(model.intValue == 3)
        #expect(model.stringValue == "three")
        #expect(model.boolValue == true)
        try #require(undoManager.undoMenuItemTitle == "Undo Triple")

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        #expect(model.boolValue == false)
    }

    @Test func atomicUndoRestoresAllThreeProperties() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 100,
                \.doubleValue, with: 100.0,
                \.stringValue, with: "hundred"
            )
        }

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.doubleValue == 1.0)
        #expect(model.stringValue == "initial")
        try #require(!undoManager.canUndo)
    }

}


// MARK: - Four-property replace

@Suite
@MainActor
struct FourPropertyReplaceTests {

    @Test func basicUndoRedo() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 1,
                \.stringValue, with: "one",
                \.doubleValue, with: 1.1,
                \.boolValue, with: true
            )
        }

        #expect(model.intValue == 1)
        #expect(model.stringValue == "one")
        #expect(model.doubleValue == 1.1)
        #expect(model.boolValue == true)

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        #expect(model.doubleValue == 1.0)
        #expect(model.boolValue == false)

        undoManager.redo()
        #expect(model.intValue == 1)
        #expect(model.stringValue == "one")
        #expect(model.doubleValue == 1.1)
        #expect(model.boolValue == true)
    }

    @Test func undoRedoCycle() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 4,
                \.stringValue, with: "four",
                \.doubleValue, with: 4.4,
                \.arrayValue, with: [4, 4, 4, 4]
            )
            .named("Four")
        }

        for _ in 0..<2 {
            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")
            #expect(model.doubleValue == 1.0)
            #expect(model.arrayValue == [1, 2, 3])

            undoManager.redo()
            #expect(model.intValue == 4)
            #expect(model.stringValue == "four")
            #expect(model.doubleValue == 4.4)
            #expect(model.arrayValue == [4, 4, 4, 4])
        }
    }

    @Test func atomicUndoRestoresAllFourProperties() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 99,
                \.stringValue, with: "x",
                \.doubleValue, with: 9.9,
                \.boolValue, with: true
            )
        }

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        #expect(model.doubleValue == 1.0)
        #expect(model.boolValue == false)
        try #require(!undoManager.canUndo)
    }

}


// MARK: - Five-property replace

@Suite
@MainActor
struct FivePropertyReplaceTests {

    @Test func basicUndoRedo() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 5,
                \.stringValue, with: "five",
                \.doubleValue, with: 5.5,
                \.boolValue, with: true,
                \.arrayValue, with: [5]
            )
        }

        #expect(model.intValue == 5)
        #expect(model.stringValue == "five")
        #expect(model.doubleValue == 5.5)
        #expect(model.boolValue == true)
        #expect(model.arrayValue == [5])

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        #expect(model.doubleValue == 1.0)
        #expect(model.boolValue == false)
        #expect(model.arrayValue == [1, 2, 3])

        undoManager.redo()
        #expect(model.intValue == 5)
        #expect(model.stringValue == "five")
        #expect(model.doubleValue == 5.5)
        #expect(model.boolValue == true)
        #expect(model.arrayValue == [5])
    }

    @Test func undoRedoCycle() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 8,
                \.stringValue, with: "eight",
                \.doubleValue, with: 8.8,
                \.boolValue, with: true,
                \.arrayValue, with: [8, 8]
            )
            .named("All Eight")
        }

        for _ in 0..<2 {
            try #require(undoManager.undoMenuItemTitle == "Undo All Eight")

            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")
            #expect(model.doubleValue == 1.0)
            #expect(model.boolValue == false)
            #expect(model.arrayValue == [1, 2, 3])

            undoManager.redo()
            #expect(model.intValue == 8)
            #expect(model.stringValue == "eight")
            #expect(model.doubleValue == 8.8)
            #expect(model.boolValue == true)
            #expect(model.arrayValue == [8, 8])
        }
    }

    @Test func insideUndoGroup() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            UndoGroup("All Five") {
                model.replace(
                    \.intValue, with: 99,
                    \.stringValue, with: "grouped",
                    \.doubleValue, with: 99.9,
                    \.boolValue, with: true,
                    \.arrayValue, with: [99]
                )
            }
        }

        try #require(undoManager.undoMenuItemTitle == "Undo All Five")
        #expect(model.intValue == 99)
        #expect(model.stringValue == "grouped")

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        #expect(model.doubleValue == 1.0)
        #expect(model.boolValue == false)
        #expect(model.arrayValue == [1, 2, 3])
    }

    @Test func atomicUndoRestoresAllFiveProperties() throws {
        let undoManager = UndoManager()
        let model = MultiPropModel()

        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: -1,
                \.stringValue, with: "minus",
                \.doubleValue, with: -1.0,
                \.boolValue, with: true,
                \.arrayValue, with: [-1]
            )
        }

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        #expect(model.doubleValue == 1.0)
        #expect(model.boolValue == false)
        #expect(model.arrayValue == [1, 2, 3])
        try #require(!undoManager.canUndo)
    }

}


// MARK: - Cross-arity combinations

@Suite
@MainActor
struct MultiPropertyCrossArityTests {

    @Test func sequentialReplacementsOfDifferentArities() throws {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = MultiPropModel()

        // Step 1: replace 2 props
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 1,
                \.stringValue, with: "step1"
            ).named("Step 1")
        }
        undoManager.endUndoGrouping()

        // Step 2: replace 3 props
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 2,
                \.stringValue, with: "step2",
                \.boolValue, with: true
            ).named("Step 2")
        }
        undoManager.endUndoGrouping()

        // Step 3: replace 4 props
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.replace(
                \.intValue, with: 3,
                \.stringValue, with: "step3",
                \.doubleValue, with: 3.0,
                \.arrayValue, with: [3]
            ).named("Step 3")
        }
        undoManager.endUndoGrouping()

        #expect(model.intValue == 3)
        try #require(undoManager.undoMenuItemTitle == "Undo Step 3")

        undoManager.undo()
        #expect(model.intValue == 2)
        #expect(model.stringValue == "step2")
        try #require(undoManager.undoMenuItemTitle == "Undo Step 2")

        undoManager.undo()
        #expect(model.intValue == 1)
        #expect(model.stringValue == "step1")
        try #require(undoManager.undoMenuItemTitle == "Undo Step 1")

        undoManager.undo()
        #expect(model.intValue == 0)
        #expect(model.stringValue == "initial")
        try #require(!undoManager.canUndo)

        // Redo all
        undoManager.redo()
        #expect(model.intValue == 1)
        undoManager.redo()
        #expect(model.intValue == 2)
        undoManager.redo()
        #expect(model.intValue == 3)
        try #require(!undoManager.canRedo)
    }

}


// MARK: - Equivalence: UndoGroup { replace; replace } vs replace(kp1, v1, kp2, v2)

/// Verifies that `UndoGroup { replace(kp1, with: v1); replace(kp2, with: v2) }`
/// behaves identically to `replace(kp1, with: v1, kp2, with: v2)`.
///
/// Both forms must produce a single undo entry and restore all properties atomically.
@Suite
@MainActor
struct ReplaceGroupEquivalenceTests {

    // MARK: - Two properties

    @Test func twoPropertyEquivalence() throws {
        for useMultiKeypath in [true, false] {
            let undoManager = UndoManager()
            let model = MultiPropModel()

            if useMultiKeypath {
                withUndoTracking(undoManager) {
                    model.replace(
                        \.intValue, with: 42,
                        \.stringValue, with: "multi"
                    )
                }
            } else {
                withUndoTracking(undoManager) {
                    UndoGroup {
                        model.replace(\.intValue, with: 42)
                        model.replace(\.stringValue, with: "multi")
                    }
                }
            }

            // Forward state identical.
            #expect(model.intValue == 42)
            #expect(model.stringValue == "multi")
            try #require(undoManager.canUndo)

            // Single undo restores both — atomic in both forms.
            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")
            try #require(!undoManager.canUndo)
            try #require(undoManager.canRedo)

            // Redo restores both.
            undoManager.redo()
            #expect(model.intValue == 42)
            #expect(model.stringValue == "multi")
        }
    }

    // MARK: - Three properties

    @Test func threePropertyEquivalence() throws {
        for useMultiKeypath in [true, false] {
            let undoManager = UndoManager()
            let model = MultiPropModel()

            if useMultiKeypath {
                withUndoTracking(undoManager) {
                    model.replace(
                        \.intValue, with: 10,
                        \.stringValue, with: "three",
                        \.boolValue, with: true
                    )
                }
            } else {
                withUndoTracking(undoManager) {
                    UndoGroup {
                        model.replace(\.intValue, with: 10)
                        model.replace(\.stringValue, with: "three")
                        model.replace(\.boolValue, with: true)
                    }
                }
            }

            #expect(model.intValue == 10)
            #expect(model.stringValue == "three")
            #expect(model.boolValue == true)
            try #require(undoManager.canUndo)

            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")
            #expect(model.boolValue == false)
            try #require(!undoManager.canUndo)

            undoManager.redo()
            #expect(model.intValue == 10)
            #expect(model.stringValue == "three")
            #expect(model.boolValue == true)
        }
    }

    // MARK: - Four properties

    @Test func fourPropertyEquivalence() throws {
        for useMultiKeypath in [true, false] {
            let undoManager = UndoManager()
            let model = MultiPropModel()

            if useMultiKeypath {
                withUndoTracking(undoManager) {
                    model.replace(
                        \.intValue, with: 5,
                        \.stringValue, with: "four",
                        \.doubleValue, with: 5.5,
                        \.boolValue, with: true
                    )
                }
            } else {
                withUndoTracking(undoManager) {
                    UndoGroup {
                        model.replace(\.intValue, with: 5)
                        model.replace(\.stringValue, with: "four")
                        model.replace(\.doubleValue, with: 5.5)
                        model.replace(\.boolValue, with: true)
                    }
                }
            }

            #expect(model.intValue == 5)
            #expect(model.stringValue == "four")
            #expect(model.doubleValue == 5.5)
            #expect(model.boolValue == true)
            try #require(undoManager.canUndo)

            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")
            #expect(model.doubleValue == 1.0)
            #expect(model.boolValue == false)
            try #require(!undoManager.canUndo)

            undoManager.redo()
            #expect(model.intValue == 5)
            #expect(model.stringValue == "four")
            #expect(model.doubleValue == 5.5)
            #expect(model.boolValue == true)
        }
    }

    // MARK: - Five properties

    @Test func fivePropertyEquivalence() throws {
        for useMultiKeypath in [true, false] {
            let undoManager = UndoManager()
            let model = MultiPropModel()

            if useMultiKeypath {
                withUndoTracking(undoManager) {
                    model.replace(
                        \.intValue, with: 99,
                        \.stringValue, with: "five",
                        \.doubleValue, with: 9.9,
                        \.boolValue, with: true,
                        \.arrayValue, with: [99]
                    )
                }
            } else {
                withUndoTracking(undoManager) {
                    UndoGroup {
                        model.replace(\.intValue, with: 99)
                        model.replace(\.stringValue, with: "five")
                        model.replace(\.doubleValue, with: 9.9)
                        model.replace(\.boolValue, with: true)
                        model.replace(\.arrayValue, with: [99])
                    }
                }
            }

            #expect(model.intValue == 99)
            #expect(model.stringValue == "five")
            #expect(model.doubleValue == 9.9)
            #expect(model.boolValue == true)
            #expect(model.arrayValue == [99])
            try #require(undoManager.canUndo)

            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")
            #expect(model.doubleValue == 1.0)
            #expect(model.boolValue == false)
            #expect(model.arrayValue == [1, 2, 3])
            try #require(!undoManager.canUndo)

            undoManager.redo()
            #expect(model.intValue == 99)
            #expect(model.stringValue == "five")
            #expect(model.doubleValue == 9.9)
            #expect(model.boolValue == true)
            #expect(model.arrayValue == [99])
        }
    }

    // MARK: - Undo/redo cycle equivalence

    @Test func twoPropertyCycleEquivalence() throws {
        for useMultiKeypath in [true, false] {
            let undoManager = UndoManager()
            let model = MultiPropModel()

            if useMultiKeypath {
                withUndoTracking(undoManager) {
                    model.replace(
                        \.intValue, with: 7,
                        \.stringValue, with: "cycle"
                    ).named("Test")
                }
            } else {
                withUndoTracking(undoManager) {
                    UndoGroup("Test") {
                        model.replace(\.intValue, with: 7)
                        model.replace(\.stringValue, with: "cycle")
                    }
                }
            }

            for _ in 0..<3 {
                try #require(undoManager.undoMenuItemTitle == "Undo Test")

                undoManager.undo()
                #expect(model.intValue == 0)
                #expect(model.stringValue == "initial")

                undoManager.redo()
                #expect(model.intValue == 7)
                #expect(model.stringValue == "cycle")
            }
        }
    }

    // MARK: - Single undo depth equivalence

    /// Both forms must consume exactly one undo level.
    @Test func singleUndoDepthEquivalence() throws {
        for useMultiKeypath in [true, false] {
            let undoManager = UndoManager()
            undoManager.groupsByEvent = false
            let model = MultiPropModel()

            // Step 1: prior action (explicit group).
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                model.replace(\.intValue, with: 1).named("Prior")
            }
            undoManager.endUndoGrouping()

            // Step 2: the replace-under-test (also in an explicit group).
            undoManager.beginUndoGrouping()
            if useMultiKeypath {
                withUndoTracking(undoManager) {
                    model.replace(
                        \.intValue, with: 2,
                        \.stringValue, with: "test"
                    ).named("Test")
                }
            } else {
                withUndoTracking(undoManager) {
                    UndoGroup("Test") {
                        model.replace(\.intValue, with: 2)
                        model.replace(\.stringValue, with: "test")
                    }
                }
            }
            undoManager.endUndoGrouping()

            #expect(model.intValue == 2)
            #expect(model.stringValue == "test")

            // First undo: reverses "Test" → back to intValue=1, stringValue="initial"
            undoManager.undo()
            #expect(model.intValue == 1)
            #expect(model.stringValue == "initial")
            try #require(undoManager.undoMenuItemTitle == "Undo Prior")

            // Second undo: reverses "Prior"
            undoManager.undo()
            #expect(model.intValue == 0)
            #expect(model.stringValue == "initial")
            try #require(!undoManager.canUndo)

            // Both forms consumed exactly 2 undos (Prior + Test).
        }
    }

}
