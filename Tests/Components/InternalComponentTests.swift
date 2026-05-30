//
//  InternalComponentTests.swift
//  UndoTracking
//

import Foundation
import Testing
@testable import UndoTracking


// MARK: - _ConditionalComponent

@Suite
@MainActor
struct ConditionalComponentTests {

    @Test func isEmptyReturnsTrueForNilContent() {
        let conditional = _ConditionalComponent<UndoComponent<Model>>(content: nil)
        let executable = conditional._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func isEmptyReturnsFalseForNonNilContent() {
        let model = Model()
        let conditional = _ConditionalComponent(content: model.increment())
        let executable = conditional._makeExecutable()
        #expect(!executable._isEmpty)
    }

    @Test func isEmptyDelegatesToEmptyContent() {
        let model = Model()
        let conditional = _ConditionalComponent(content: UndoComponent<Model>.empty(model))
        let executable = conditional._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func executeWithNilContentDoesNothing() throws {
        let undoManager = UndoManager()

        let conditional = _ConditionalComponent<UndoComponent<Model>>(content: nil)
        conditional._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        try #require(!undoManager.canUndo)
    }

    @Test func executeWithNonNilContentExecutes() throws {
        let undoManager = UndoManager()
        let model = Model()

        let conditional = _ConditionalComponent(content: model.increment())
        conditional._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 1)
        try #require(undoManager.canUndo)
    }

    @Test func executeWithEmptyContentDoesNotRegisterUndo() throws {
        let undoManager = UndoManager()

        let conditional = _ConditionalComponent(content: UndoComponent<Model>.empty(Model()))
        conditional._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        try #require(!undoManager.canUndo)
    }

}


// MARK: - _EitherComponent

@Suite
@MainActor
struct EitherComponentTests {

    @Test func isEmptyForFirstBranch() {
        let model = Model()
        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .first(model.increment())
        )
        let executable = either._makeExecutable()
        #expect(!executable._isEmpty)
    }

    @Test func isEmptyForSecondBranch() {
        let model = Model()
        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .second(model.increment())
        )
        let executable = either._makeExecutable()
        #expect(!executable._isEmpty)
    }

    @Test func isEmptyForFirstBranchEmpty() {
        let model = Model()
        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .first(UndoComponent<Model>.empty(model))
        )
        let executable = either._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func isEmptyForSecondBranchEmpty() {
        let model = Model()
        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .second(UndoComponent<Model>.empty(model))
        )
        let executable = either._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func executeFirstBranch() throws {
        let undoManager = UndoManager()
        let model = Model()

        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .first(model.increment().named("First"))
        )
        either._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 1)
        try #require(undoManager.canUndo)
    }

    @Test func executeSecondBranch() throws {
        let undoManager = UndoManager()
        let model = Model()

        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .second(model.decrement().named("Second"))
        )
        either._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == -1)
        try #require(undoManager.canUndo)
    }

    @Test func eitherFirstBranchUndoRedo() throws {
        let undoManager = UndoManager()
        let model = Model()

        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .first(model.increment().named("Branch"))
        )
        either._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

    @Test func eitherSecondBranchUndoRedo() throws {
        let undoManager = UndoManager()
        let model = Model()

        let either = _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
            .second(model.decrement().named("Branch"))
        )
        either._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == -1)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == -1)
    }

}


// MARK: - _ArrayComponent

@Suite
@MainActor
struct ArrayComponentTests {

    @Test func isEmptyReturnsTrueForEmptyArray() {
        let array = _ArrayComponent<UndoComponent<Model>>(content: [])
        let executable = array._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func isEmptyReturnsTrueWhenAllChildrenEmpty() {
        let model = Model()
        let array = _ArrayComponent(content: [
            UndoComponent<Model>.empty(model),
            UndoComponent<Model>.empty(model),
        ])
        let executable = array._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func isEmptyReturnsFalseWhenSomeChildrenNonEmpty() {
        let model = Model()
        let array = _ArrayComponent(content: [
            UndoComponent<Model>.empty(model),
            model.increment(),
        ])
        let executable = array._makeExecutable()
        #expect(!executable._isEmpty)
    }

    @Test func isEmptyReturnsFalseWhenAllChildrenNonEmpty() {
        let model = Model()
        let array = _ArrayComponent(content: [
            model.increment(),
            model.increment(),
        ])
        let executable = array._makeExecutable()
        #expect(!executable._isEmpty)
    }

    @Test func executeExecutesAllChildren() throws {
        let undoManager = UndoManager()
        let model = Model()

        let array = _ArrayComponent(content: [
            model.increment(),
            model.increment(),
            model.increment(),
        ])
        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 3)
        try #require(undoManager.canUndo)
    }

    @Test func executeWithEmptyArrayDoesNothing() throws {
        let undoManager = UndoManager()

        let array = _ArrayComponent<UndoComponent<Model>>(content: [])
        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        try #require(!undoManager.canUndo)
    }

    @Test func executeWithSomeEmptyChildren() throws {
        let undoManager = UndoManager()
        let model = Model()

        let array = _ArrayComponent(content: [
            UndoComponent<Model>.empty(model),
            model.increment().named("Real"),
            UndoComponent<Model>.empty(model),
        ])
        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 1)
    }

    @Test func undoRedoForArrayOfComponents() throws {
        let undoManager = UndoManager()
        let model = Model()

        let array = _ArrayComponent(content: [
            model.increment().named("First"),
            model.increment().named("Second"),
        ])
        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }

    @Test func singleElementArray() throws {
        let undoManager = UndoManager()
        let model = Model()

        let array = _ArrayComponent(content: [model.increment().named("Solo")])
        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

}


// MARK: - _TupleComponent

@Suite
@MainActor
struct TupleComponentTests {

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func isEmptyReturnsTrueWhenAllChildrenEmpty() {
        let model = Model()
        let tuple = _TupleComponent(content: (
            UndoComponent<Model>.empty(model),
            UndoComponent<Model>.empty(model)
        ))
        let executable = tuple._makeExecutable()
        #expect(executable._isEmpty)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func isEmptyReturnsFalseWhenSomeChildrenNonEmpty() {
        let model = Model()
        let tuple = _TupleComponent(content: (
            UndoComponent<Model>.empty(model),
            model.increment()
        ))
        let executable = tuple._makeExecutable()
        #expect(!executable._isEmpty)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func isEmptyReturnsFalseWhenAllChildrenNonEmpty() {
        let model = Model()
        let tuple = _TupleComponent(content: (
            model.increment(),
            model.increment()
        ))
        let executable = tuple._makeExecutable()
        #expect(!executable._isEmpty)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func executeExecutesAllChildren() throws {
        let undoManager = UndoManager()
        let model = Model()

        let tuple = _TupleComponent(content: (
            model.increment(),
            model.increment(),
            model.increment()
        ))
        tuple._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 3)
        try #require(undoManager.canUndo)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func executeWithAllEmptyChildren() throws {
        let undoManager = UndoManager()
        let model = Model()

        let tuple = _TupleComponent(content: (
            UndoComponent<Model>.empty(model),
            UndoComponent<Model>.empty(model)
        ))
        tuple._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 0)
        try #require(!undoManager.canUndo)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func undoRedoForTupleOfComponents() throws {
        let undoManager = UndoManager()
        let model = Model()

        let tuple = _TupleComponent(content: (
            model.increment().named("A"),
            model.increment().named("B")
        ))
        tuple._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func singleElementTuple() throws {
        let undoManager = UndoManager()
        let model = Model()

        let tuple = _TupleComponent(content: (model.increment().named("Only"),))
        tuple._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 1)
    }

    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    @Test func threeDifferentComponents() throws {
        let undoManager = UndoManager()
        let model = Model()

        let tuple = _TupleComponent(content: (
            model.increment() as UndoComponent<Model>,
            model.increment() as UndoComponent<Model>,
            UndoComponent<Model>.empty(model)
        ))
        tuple._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
    }

}


// MARK: - Cross-component composition

@Suite
@MainActor
struct CrossComponentTests {

    @Test func conditionalWrappingNonNilInsideArray() throws {
        let undoManager = UndoManager()
        let model = Model()

        let array = _ArrayComponent(content: [
            _ConditionalComponent(content: model.increment()),
            _ConditionalComponent(content: nil as UndoComponent<Model>?),
            _ConditionalComponent(content: model.increment()),
        ])
        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func eitherInsideConditionalFirstBranch() throws {
        let undoManager = UndoManager()
        let model = Model()

        let conditional = _ConditionalComponent(
            content: _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
                .first(model.increment().named("EitherFirst"))
            )
        )
        conditional._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == 1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func eitherInsideConditionalSecondBranch() throws {
        let undoManager = UndoManager()
        let model = Model()

        let conditional = _ConditionalComponent(
            content: _EitherComponent<UndoComponent<Model>, UndoComponent<Model>>(
                .second(model.decrement().named("EitherSecond"))
            )
        )
        conditional._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        #expect(model.index == -1)

        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func nestedConditionalBothNil() {
        let bothNil = _ConditionalComponent<_ConditionalComponent<UndoComponent<Model>>>(
            content: nil
        )
        let executable = bothNil._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func nestedConditionalInnerNil() {
        let innerNil = _ConditionalComponent(
            content: _ConditionalComponent<UndoComponent<Model>>(content: nil)
        )
        let executable = innerNil._makeExecutable()
        #expect(executable._isEmpty)
    }

    @Test func arrayOfConditionalsAllNil() {
        let allNil = _ArrayComponent<_ConditionalComponent<UndoComponent<Model>>>(content: [
            _ConditionalComponent(content: nil),
            _ConditionalComponent(content: nil),
        ])
        let executable = allNil._makeExecutable()
        #expect(executable._isEmpty)
    }

}


// MARK: - _isEmpty consistency with _execute

@Suite
@MainActor
struct IsEmptyExecuteConsistencyTests {

    @Test func conditionalEmptyDoesNotRegisterUndo() throws {
        let undoManager = UndoManager()

        let conditional = _ConditionalComponent<UndoComponent<Model>>(content: nil)
        #expect(conditional._makeExecutable()._isEmpty)

        conditional._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        try #require(!undoManager.canUndo)
    }

    @Test func arrayEmptyDoesNotRegisterUndo() throws {
        let undoManager = UndoManager()

        let array = _ArrayComponent<UndoComponent<Model>>(content: [])
        #expect(array._makeExecutable()._isEmpty)

        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        try #require(!undoManager.canUndo)
    }

    @Test func nonEmptyConditionalRegistersUndo() throws {
        let undoManager = UndoManager()
        let model = Model()

        let conditional = _ConditionalComponent(content: model.increment())
        #expect(!conditional._makeExecutable()._isEmpty)

        conditional._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        try #require(undoManager.canUndo)
        #expect(model.index == 1)
    }

    @Test func nonEmptyArrayRegistersUndo() throws {
        let undoManager = UndoManager()
        let model = Model()

        let array = _ArrayComponent(content: [model.increment()])
        #expect(!array._makeExecutable()._isEmpty)

        array._makeExecutable()._execute(
            undoManager: undoManager,
            context: _UndoComponentContext()
        )

        try #require(undoManager.canUndo)
        #expect(model.index == 1)
    }

}
