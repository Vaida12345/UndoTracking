//
//  UndoBuilder.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation


/// Performs the actions on the `undoManager`.
///
/// The `UndoTracking` uses a closure-based structure similar to SwiftUI declaration.
///
/// ```swift
/// withUndoTracking(undoManager) {
///     document.replace(\.selection, with: [note])
///         .named("Select \([note])")
/// }
/// ```
///
/// - Parameters:
///   - undoManager: Pass the `UndoManager` from the environment.
///   - builder: The closure consists of the undoable action.
///
/// - Tip: To group components together, use ``UndoGroup``.
@MainActor
public func withUndoTracking<T: _UndoComponentProtocol>(
    _ undoManager: UndoManager?,
    builder: @escaping () -> T?
) {
    builder()?._makeExecutable()._execute(undoManager: undoManager, context: _UndoComponentContext())
}
