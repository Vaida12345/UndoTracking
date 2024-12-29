//
//  UndoComponent.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation


/// An undo component.
public struct UndoComponent<Target> where Target: AnyObject {
    
    let target: Target
    
    /// An action to be executed when the component is called.
    let action: (
        _ target: Target,
        _ withAnimation: (() -> Void) -> Void,
        _ registerUndo: (@escaping () -> UndoComponent<Target>) -> Void
    ) -> Void
    
    let actionName: LocalizedStringResource?
    
    let animate: Bool
    
    
    func replacingAction(
        with action: @escaping (
            _ target: Target,
            _ withAnimation: (() -> Void) -> Void,
            _ registerUndo: (@escaping () -> UndoComponent<Target>) -> Void
        ) -> Void
    ) -> UndoComponent<Target> {
        UndoComponent(target: self.target, action: action, actionName: self.actionName, animate: self.animate)
    }
    
    
    fileprivate init(
        target: Target,
        action: @escaping (
            _ target: Target,
            _ withAnimation: (() -> Void) -> Void,
            _ registerUndo: (@escaping () -> UndoComponent<Target>) -> Void
        ) -> Void,
        actionName: LocalizedStringResource?,
        animate: Bool
    ) {
        self.target = target
        self.action = action
        self.actionName = actionName
        self.animate = animate
    }
    
    
    /// Creates the component with its associated action.
    ///
    /// - Parameters:
    ///   - target: The target document.
    ///   - action: A closure for building the action.
    ///
    /// ## Action Parameters
    /// - term target: The target document, as passed from `target` to avoid capture.
    /// - term withAnimation: The `withAnimation` block.
    /// - term registerUndo: The block for registering undo. The closure will be executed in `UndoManager.registerUndo(withTarget:handler:)`. The return component will inherit any attributes set to `self`.
    public init(
        target: Target,
        action: @escaping (
            _ target: Target,
            _ withAnimation: (() -> Void) -> Void,
            _ registerUndo: (@escaping () -> UndoComponent<Target>) -> Void
        ) -> Void
    ) {
        self.init(target: target, action: action, actionName: nil, animate: false)
    }
    
}


extension UndoComponent {
    
    /// Name the component.
    ///
    /// This sets the name of the action associated with the Undo or Redo command.
    public func named(_ actionName: LocalizedStringResource) -> UndoComponent {
        UndoComponent(target: self.target, action: self.action, actionName: actionName, animate: self.animate)
    }
    
    /// Set the action `withAnimation` block as animated.
    public func animated() -> UndoComponent {
        UndoComponent(target: self.target, action: self.action, actionName: self.actionName, animate: true)
    }
    
}
