//
//  UndoGroup.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation
import SwiftUI


/// Groups execution together.
///
/// - Note: When you use an `UndoGroup`, titles of its children are always overridden.
public struct UndoGroup<T: _UndoComponentProtocol>: _UndoComponentProtocol {
    
    let title: LocalizedStringResource?
    let builder: () -> T
    let animated: Bool?
    
    public init(_ title: LocalizedStringResource? = nil, @UndoGroupBuilder builder: @escaping () -> T) {
        self.title = title
        self.builder = builder
        self.animated = nil
    }
    
    internal init(title: LocalizedStringResource? = nil, builder: @escaping () -> T, animated: Bool?) {
        self.title = title
        self.builder = builder
        self.animated = animated
    }
    
    public func _makeExecutable() -> _UndoExecutable {
        _UndoExecutable(title: self.title, contents: self.builder()._makeExecutable(), animated: self.animated)
    }
    
    public struct _UndoExecutable: _UndoExecutableProtocol {
        let title: LocalizedStringResource?
        let contents: T._UndoExecutable
        let animated: Bool?
        
        public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
            let isNestedGroup = context.insideGroup
            
            guard isNestedGroup || !self.contents._isEmpty else { return }
            
            var context = context
            if context.title == nil {
                context.title = self.title ?? "" // parent title take priority
                                                 // defaults to empty string when `self` has no title, as undo title must be the same within the same group.
            }
            
            if let animated = self.animated {
                context.animated = animated // self animation take priority.
            }
            
            if !isNestedGroup { undoManager?.beginUndoGrouping() }
            
            context.insideGroup = true
            // - Important: `context` is used both ways by the children.
            self.contents._execute(undoManager: undoManager, context: context)
            
            if !isNestedGroup { undoManager?.endUndoGrouping() }
        }
        
        public var _isEmpty: Bool {
            self.contents._isEmpty
        }
    }
}


extension UndoGroup {
    
    /// Name the component.
    ///
    /// This sets the name of the action associated with the Undo or Redo command.
    public func named(_ actionName: LocalizedStringResource) -> UndoGroup {
        UndoGroup(title: actionName, builder: self.builder, animated: self.animated)
    }
    
    /// Set the action `withAnimation` block as animated.
    ///
    /// The animated components depends on the implementation, but generally, the primary action will be animated.
    ///
    /// By default, no animation is applied.
    public func animated(_ bool: Bool = true) -> UndoGroup {
        UndoGroup(title: self.title, builder: self.builder, animated: bool)
    }
    
}
