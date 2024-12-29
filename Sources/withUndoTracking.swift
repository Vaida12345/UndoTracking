//
//  UndoBuilder.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import SwiftUI


/// Performs the actions on the `undoManager`.
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
