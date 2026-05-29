//
//  Helpers.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import UndoTracking


final class Container<T>: UndoTracking, Identifiable {

    var content: T

    init(_ content: T) {
        self.content = content
    }

}


extension Container: Equatable where T: Equatable {

    static func == (_ lhs: Container, _ rhs: Container) -> Bool {
        lhs.content == rhs.content
    }

}


@MainActor
final class Model: UndoTracking {

    var index: Int = 0


    func increment() -> UndoComponent<Model> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                target.index += 1
            }
            registerUndo {
                target.decrement()
            }
        }
    }

    func decrement() -> UndoComponent<Model> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                target.index -= 1
            }
            registerUndo {
                target.increment()
            }
        }
    }


    // MARK: - Async helpers (concurrency exploration)

    /// Async increment: registers undo synchronously, then spawns a `Task` for the mutation.
    ///
    /// Undo is registered *before* the Task mutates. If undo fires before the Task completes,
    /// the undo acts on pre-mutation state (potentially going negative).
    func asyncIncrement(delay: Duration = .zero) -> UndoComponent<Model> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            registerUndo {
                target.decrement()
            }
            Task { @MainActor in
                if delay != .zero {
                    try? await Task.sleep(for: delay)
                }
                target.index += 1
            }
        }
    }

    /// Async decrement: registers undo synchronously, then spawns a `Task` for the mutation.
    func asyncDecrement(delay: Duration = .zero) -> UndoComponent<Model> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            registerUndo {
                target.increment()
            }
            Task { @MainActor in
                if delay != .zero {
                    try? await Task.sleep(for: delay)
                }
                target.index -= 1
            }
        }
    }

    /// Attempted "register after" pattern. `registerUndo` is non-escaping, so it
    /// cannot be called inside `Task {}`. The mutation runs but no undo is ever
    /// recorded — this is the limitation.
    func asyncIncrementRegisterAfter(delay: Duration = .zero) -> UndoComponent<Model> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            // registerUndo is non-escaping — cannot be deferred into Task {}.
            // It must be called here (synchronously), before we know the
            // inverse. The mutation runs but undo is lost.
            Task { @MainActor in
                if delay != .zero {
                    try? await Task.sleep(for: delay)
                }
                target.index += 1
            }
            // registerUndo NOT called — the limitation.
        }
    }


}


final class Item: UndoTracking, Identifiable {

    let id: Int
    var value: String

    init(id: Int, value: String) {
        self.id = id
        self.value = value
    }

}
