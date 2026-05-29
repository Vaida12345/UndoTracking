//
//  UndoComponentTests.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-30.
//

import Foundation
import Testing
@testable import UndoTracking


@Suite
@MainActor
struct UndoComponentTests {

    // MARK: - _isEmpty

    @Test func normalComponentIsNotEmpty() {
        let model = Model()
        let component = model.increment()
        #expect(!component._isEmpty)
    }

    @Test func emptyComponentIsEmpty() {
        let model = Model()
        let component = UndoComponent<Model>.empty(target: model)
        #expect(component._isEmpty)
    }

    // MARK: - empty(target:) executes without side effects

    @Test func emptyComponentExecutesWithoutSideEffects() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoComponent<Model>.empty(target: model)
        }

        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
    }

    // MARK: - named(_:) preserves _isEmpty

    @Test func namedPreservesIsEmptyOnEmptyComponent() {
        let model = Model()
        let component = UndoComponent<Model>.empty(target: model)
            .named("Test")
        #expect(component._isEmpty)
    }

    @Test func namedPreservesIsEmptyOnNormalComponent() {
        let model = Model()
        let component = model.increment()
            .named("Inc")
        #expect(!component._isEmpty)
    }

    // MARK: - animated(_:) preserves _isEmpty

    @Test func animatedPreservesIsEmptyOnEmptyComponent() {
        let model = Model()
        let component = UndoComponent<Model>.empty(target: model)
            .animated()
        #expect(component._isEmpty)
    }

    @Test func animatedPreservesIsEmptyOnNormalComponent() {
        let model = Model()
        let component = model.increment()
            .animated()
        #expect(!component._isEmpty)
    }

    // MARK: - Chained modifiers on empty component

    @Test func emptyComponentChainedModifiersStillEmpty() {
        let model = Model()
        let component = UndoComponent<Model>.empty(target: model)
            .named("Whatever")
            .animated(true)

        #expect(component._isEmpty)
    }

    // MARK: - Empty component in UndoGroup

    @Test func emptyComponentInGroupDoesNotCreatePhantomUndoAction() {
        let undoManager = UndoManager()

        withUndoTracking(undoManager) {
            UndoGroup("Phantom") {
                UndoComponent<Model>.empty(target: Model())
            }
        }

        #expect(!undoManager.canUndo)
    }

    @Test func emptyComponentAlongsideRealComponentInGroup() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup("Mixed") {
                UndoComponent<Model>.empty(target: model)
                model.increment()
            }
        }

        #expect(model.index == 1)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: - Empty component as registerUndo fallback

    @Test func emptyComponentAsRegisterUndoFallback() {
        let undoManager = UndoManager()
        let model = Model()

        // Simulates the pattern: registerUndo requires a non-nil return,
        // but the inverse action may have nothing to do.
        let component = UndoComponent(target: model) { target, withAnimation, registerUndo in
            target.index = 42
            registerUndo {
                // No inverse needed — use empty as fallback.
                UndoComponent<Model>.empty(target: target)
            }
        }.named("Set")

        withUndoTracking(undoManager) {
            component
        }

        #expect(model.index == 42)
        #expect(undoManager.canUndo)

        // Undo fires the empty component — state unchanged.
        undoManager.undo()
        #expect(model.index == 42)
    }

    // MARK: - UndoComponent executes primary action

    @Test func componentExecutesPrimaryAction() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoComponent(target: model) { target, withAnimation, registerUndo in
                target.index = 99
            }
        }

        #expect(model.index == 99)
    }

    // MARK: - UndoComponent registers undo and redo

    @Test func componentRegistersUndoAndRedo() {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.increment().named("Inc")
        }

        #expect(model.index == 1)
        #expect(undoManager.canUndo)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(undoManager.canRedo)

        undoManager.redo()
        #expect(model.index == 1)
    }

}
