//
//  UndoComponent.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import SwiftUI


/// An undo component.
///
/// To construct ``UndoComponent``, please refer [here](<doc:BuildUndoComponent>).
public struct UndoComponent<Target> where Target: AnyObject {
    
    let target: Target
    
    /// An action to be executed when the component is called.
    let action: (
        _ target: Target,
        _ withAnimation: (() -> Void) -> Void,
        _ registerUndo: (@escaping () -> UndoComponent<Target>) -> Void
    ) -> Void
    
    let actionName: LocalizedStringResource?
    
    let animate: Bool?
    
    
    fileprivate init(
        target: Target,
        action: @escaping (
            _ target: Target,
            _ withAnimation: (() -> Void) -> Void,
            _ registerUndo: (@escaping () -> UndoComponent<Target>) -> Void
        ) -> Void,
        actionName: LocalizedStringResource?,
        animate: Bool?
    ) {
        self.target = target
        self.action = action
        self.actionName = actionName
        self.animate = animate
    }
    
    
    /// Creates the component with its associated action.
    ///
    /// To construct ``UndoComponent``, please refer [here](<doc:BuildUndoComponent>).
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
        self.init(target: target, action: action, actionName: nil, animate: nil)
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
    ///
    /// The animated components depends on the implementation, but generally, the primary action will be animated.
    ///
    /// By default, no animation is applied.
    public func animated(_ bool: Bool = true) -> UndoComponent {
        UndoComponent(target: self.target, action: self.action, actionName: self.actionName, animate: bool)
    }
    
}


extension UndoComponent: _UndoComponentProtocol {
    
    public var _isEmpty: Bool {
        false
    }
    
    public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
        // Set the undo/redo menu item name if the component carries one.
        if let title = context.title ?? self.actionName, !title.key.isEmpty {
            undoManager?.setActionName(title)
        }
        
        // Choose animation strategy based on the component's `animate` flag.
        let _withAnimation: (() -> Void) -> Void
        if self.animate ?? context.animated ?? false {
            _withAnimation = { block in withAnimation(.default, { block() }) }
        } else {
            _withAnimation = { $0() }
        }
        
        // The closure that `component.action` will call during its execution to register
        // the inverse operation with UndoManager. When undo fires, it calls
        // `withUndoTracking` again with the inverse component — so the forward action
        // gets re-registered as the "redo" half.
        let _registerUndo: (@escaping () -> UndoComponent<Target>) -> Void = { [weak undoManager, weak target] builder in
            // `[weak undoManager]` prevents a retain cycle: the UndoManager holds a
            // reference to us (via registerUndo), and we hold a reference back.
            guard let target else { return }
            let action = builder().action // capture values here
            
            undoManager?.registerUndo(withTarget: target) { [weak undoManager] target in
                // the inverse action carries the same presentation metadata.
                let component = UndoComponent(target: target, action: action, actionName: self.actionName, animate: self.animate)
                component._execute(undoManager: undoManager, context: context)
            }
        }
        
        // Execute the primary action now.
        self.action(self.target, _withAnimation, _registerUndo)
    }
    
}
