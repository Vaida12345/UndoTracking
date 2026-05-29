//
//  _UndoComponentProtocol.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation


public protocol _UndoComponentProtocol {
    
    /// Make and cache executable, see `UndoGroup` for how it is used.
    func _makeExecutable() -> _UndoExecutable
    
    associatedtype _UndoExecutable: _UndoExecutableProtocol
    
}

public protocol _UndoExecutableProtocol {
    
    /// Execute the action
    @MainActor
    func _execute(undoManager: UndoManager?, context: _UndoComponentContext)
    
    /// Returns `true` when there is nothing to execute.
    var _isEmpty: Bool { get }
    
}

public struct _UndoComponentContext: Sendable, Equatable, CustomStringConvertible {
    var animated: Bool? = nil
    var title: LocalizedStringResource? = nil
    var insideGroup = false
    
    public var description: String {
        var args: [String] = []
        if let title {
            args.append(String(localized: title))
        }
        if animated == true {
            args.append("animate")
        }
        return "Content(\(args.joined(separator: ", ")))"
    }
}
