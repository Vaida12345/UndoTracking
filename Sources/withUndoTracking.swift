//
//  UndoBuilder.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import SwiftUI


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
///   - builder: The closure consists of the undoable actions.
#if swift(>=6.2)
@MainActor
public func withUndoTracking<T>(
    _ undoManager: UndoManager?,
    builder: () -> UndoComponent<T>
) {
    let undoManager = undoManager
    let component = builder()
    
    if let title = component.actionName {
        undoManager?.setActionName(title.localized())
    }
    let _withAnimation: (() -> Void) -> Void
    switch component.animate {
    case true:
        _withAnimation = { block in withAnimation(.default, { block() }) }
    case false:
        _withAnimation = { $0() }
    }
    
    let _registerUndo: (@escaping () -> UndoComponent<T>) -> Void = { builder in
        let builder = builder
        
        undoManager?.registerUndo(withTarget: component.target) { target in
            withUndoTracking(undoManager) {
                component.replacingAction(with: builder().action)
            }
        }
    }
    
    component.action(component.target, _withAnimation, _registerUndo)
}
#else
public func withUndoTracking<T>(
    _ undoManager: UndoManager?,
    builder: () -> UndoComponent<T>
) {
    nonisolated(unsafe) let undoManager = undoManager
    nonisolated(unsafe) let component = builder()
    
    if let title = component.actionName {
        undoManager?.setActionName(title.localized())
    }
    let _withAnimation: (() -> Void) -> Void
    switch component.animate {
    case true:
        _withAnimation = { block in withAnimation(.default, { block() }) }
    case false:
        _withAnimation = { $0() }
    }
    
    let _registerUndo: (@escaping () -> UndoComponent<T>) -> Void = { builder in
        nonisolated(unsafe) let builder = builder
        
        undoManager?.registerUndo(withTarget: component.target) { target in
            withUndoTracking(undoManager) {
                component.replacingAction(with: builder().action)
            }
        }
    }
    
    component.action(component.target, _withAnimation, _registerUndo)
}
#endif
