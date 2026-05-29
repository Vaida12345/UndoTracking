//
//  ConcurrencyTests.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation
import Testing
import UndoTracking


@Suite(.disabled("Using concurrency with UndoTracking is a bad idea, see Concurrency.md"))
@MainActor
struct ConcurrencyTests {

    // MARK: - a) Async forward + await + undo

    @Test func asyncForwardThenAwaitThenUndo() async {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.asyncIncrement()
        }

        // Let the Task execute on the main actor.
        await Task.yield()

        #expect(model.index == 1)
        #expect(undoManager.canUndo)
        #expect(!undoManager.canRedo)

        undoManager.undo()
        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.canRedo)
    }

    // MARK: - b) Undo fires before async forward completes

    @Test func undoBeforeAsyncForwardCompletes() async {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.asyncIncrement(delay: .milliseconds(500))
        }

        // Undo is already registered (register-before pattern), so canUndo is true
        // even though the forward mutation hasn't happened yet.
        #expect(undoManager.canUndo)
        #expect(model.index == 0, "Task hasn't run yet")

        // Trigger undo immediately.
        // LIMITATION: the undo decrements from 0 to -1 because the forward
        // mutation (which runs in a Task) hasn't happened yet.
        undoManager.undo()
        #expect(model.index == -1, "Undo ran before forward: index went negative")

        // Wait for the original forward Task to finish.
        try? await Task.sleep(for: .milliseconds(600))

        // LIMITATION: forward catches up (bringing index from -1 to 0),
        // but a phantom redo remains from the premature undo.
        #expect(model.index == 0)
        #expect(undoManager.canRedo, "Phantom redo still registered")
    }

    // MARK: - c) Raw Task mutation without undo tracking

    @Test func rawTaskMutationHasNoUndo() async {
        let undoManager = UndoManager()
        let model = Model()

        // Mutate directly in a Task — no withUndoTracking, no undo registered.
        Task { @MainActor in
            model.index += 1
        }
        await Task.yield()

        #expect(model.index == 1)
        #expect(!undoManager.canUndo, "No undo was registered for a raw Task mutation")
    }

    // MARK: - d) registerUndo cannot be deferred into Task {}

    @Test func registerUndoBeforeMutation() async {
        let undoManager = UndoManager()
        let model = Model()

        // asyncIncrement registers undo BEFORE the Task mutates.
        // This is the only valid pattern because registerUndo is non-escaping.
        withUndoTracking(undoManager) {
            model.asyncIncrement(delay: .milliseconds(100))
        }

        // Undo is immediately available, but the forward hasn't run yet.
        #expect(undoManager.canUndo)
        #expect(model.index == 0, "Forward hasn't run yet, but undo is already registered")

        // Wait for forward to complete, then undo normally.
        try? await Task.sleep(for: .milliseconds(150))
        #expect(model.index == 1)
        undoManager.undo()
        #expect(model.index == 0)
    }

    @Test func registerUndoAfterMutation() async {
        let undoManager = UndoManager()
        let model = Model()

        // asyncIncrementRegisterAfter spawns a Task for the mutation but CANNOT
        // call registerUndo inside the Task — registerUndo is non-escaping.
        // The mutation runs but no undo is ever recorded.
        withUndoTracking(undoManager) {
            model.asyncIncrementRegisterAfter(delay: .milliseconds(100))
        }

        // No undo — the Task hasn't even run yet.
        #expect(!undoManager.canUndo)
        #expect(model.index == 0)

        // Trying to undo is a no-op.
        undoManager.undo()
        #expect(model.index == 0)

        // Wait for the Task. Mutation happened, but undo was never registered.
        try? await Task.sleep(for: .milliseconds(150))
        #expect(model.index == 1)

        // Known issue: we want undo to exist, but registerUndo is non-escaping
        // and cannot be called inside Task {}.
        withKnownIssue("registerUndo is non-escaping: cannot be deferred into Task {}") {
            #expect(undoManager.canUndo)
        }
    }

    // MARK: - e) Undo triggered from inside a Task

    @Test func undoFromInsideTask() async {
        let undoManager = UndoManager()
        let model = Model()

        // Normal sync increment.
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        #expect(model.index == 1)
        #expect(undoManager.canUndo)

        // Undo from within a Task — still on @MainActor.
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                undoManager.undo()
                continuation.resume()
            }
        }

        #expect(model.index == 0)
        #expect(!undoManager.canUndo)
        #expect(undoManager.canRedo)
    }

    // MARK: - f) Multiple @MainActor tasks modifying same model

    @Test func serializedMainActorTasks() async {
        let undoManager = UndoManager()
        let model = Model()

        // Because withUndoTracking and UndoManager are @MainActor,
        // these tasks serialize — no actual concurrency.
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { @MainActor in
                    withUndoTracking(undoManager) {
                        model.increment()
                    }
                }
            }
        }

        #expect(model.index == 5)
        #expect(undoManager.canUndo)

        // Undo reverts all 5 increments.
        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: - g) UndoGroup with mixed sync and async children

    @Test func undoGroupWithMixedSyncAndAsync() async {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            UndoGroup {
                model.increment()                                // sync
                model.asyncIncrement(delay: .milliseconds(100))  // async
            }
        }

        // Sync child already executed, async child is pending.
        #expect(model.index == 1, "Only sync increment has run so far")

        // The group has begun and ended — undo is registered for both actions.
        #expect(undoManager.canUndo)

        // Wait for async child to complete.
        try? await Task.sleep(for: .milliseconds(150))
        #expect(model.index == 2)

        // Undo the group — both actions reverted.
        undoManager.undo()
        #expect(model.index == 0)
    }

    // MARK: - h) Rapid undo/redo while async forward is in-flight

    @Test func rapidUndoRedoDuringAsync() async {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.asyncIncrement(delay: .milliseconds(300))
        }

        // Immediately undo, then redo — all while the forward Task is still sleeping.
        #expect(undoManager.canUndo)
        undoManager.undo()
        #expect(model.index == -1, "Undo ran before forward: index went negative")

        #expect(undoManager.canRedo)
        undoManager.redo()
        // Redo replays the async increment: registers undo sync, spawns a second Task.
        // The original forward Task is also still pending — two Tasks racing on index.

        // Wait for everything to settle.
        try? await Task.sleep(for: .milliseconds(400))

        // LIMITATION: rapid undo/redo during async work creates a race.
        // The final index depends on Task scheduling order.
        // We only assert the system survived.
        #expect(model.index >= 0, "System survived rapid undo/redo during async work")
    }

    // MARK: - i) Undo registered under correct UndoManager (weak capture)

    @Test func undoManagerIsolationWithAsync() async {
        let undoManagerA = UndoManager()
        let undoManagerB = UndoManager()
        let modelA = Model()
        let modelB = Model()

        // Async action on manager A.
        withUndoTracking(undoManagerA) {
            modelA.asyncIncrement()
        }
        await Task.yield()
        #expect(modelA.index == 1)
        #expect(undoManagerA.canUndo)
        #expect(!undoManagerB.canUndo)

        // Sync action on manager B.
        withUndoTracking(undoManagerB) {
            modelB.increment()
        }
        #expect(modelB.index == 1)
        #expect(undoManagerB.canUndo)

        // Undo A — only affects modelA.
        undoManagerA.undo()
        #expect(modelA.index == 0)
        #expect(modelB.index == 1, "Model B unaffected")

        // Undo B — only affects modelB.
        undoManagerB.undo()
        #expect(modelA.index == 0)
        #expect(modelB.index == 0)
    }

    // MARK: - Bonus: full async undo/redo cycle

    @Test func fullAsyncUndoRedoCycle() async {
        let undoManager = UndoManager()
        let model = Model()

        withUndoTracking(undoManager) {
            model.asyncIncrement()
                .named("Async +1")
        }
        await Task.yield()

        #expect(model.index == 1)
        #expect(undoManager.canUndo)

        undoManager.undo()
        // Undo triggers the inverse (sync decrement) immediately.
        #expect(model.index == 0)
        #expect(undoManager.canRedo)

        undoManager.redo()
        // Redo replays the forward (async increment) — Task spawned.
        await Task.yield()
        #expect(model.index == 1)
        #expect(undoManager.canUndo)
    }

}
