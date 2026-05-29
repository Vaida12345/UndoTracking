//
//  UndoBlocks.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//

import Foundation


@available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
public struct _TupleComponent<each T>: _UndoComponentProtocol where repeat each T: _UndoComponentProtocol {
    let content: (repeat each T)
    
    public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
        for item in repeat each content {
            guard !item._isEmpty else { continue }
            item._execute(undoManager: undoManager, context: context)
        }
    }
    
    public var _isEmpty: Bool {
        var count = 0
        for item in repeat each content {
            if item._isEmpty { continue }
            count += 1
        }
        return count == 0
    }
}


public struct _ConditionalComponent<T: _UndoComponentProtocol>: _UndoComponentProtocol {
    let content: T?
    
    public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
        content?._execute(undoManager: undoManager, context: context)
    }
    
    public var _isEmpty: Bool {
        content?._isEmpty ?? true
    }
}


public struct _ArrayComponent<T: _UndoComponentProtocol>: _UndoComponentProtocol {
    let content: [T]

    public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
        for item in content {
            item._execute(undoManager: undoManager, context: context)
        }
    }
    
    public var _isEmpty: Bool {
        content.allSatisfy({ $0._isEmpty })
    }
}


public struct _EitherComponent<First: _UndoComponentProtocol, Second: _UndoComponentProtocol>: _UndoComponentProtocol {
    enum Storage {
        case first(First)
        case second(Second)
    }
    let storage: Storage

    init(_ storage: Storage) { self.storage = storage }

    public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
        switch storage {
        case .first(let component): component._execute(undoManager: undoManager, context: context)
        case .second(let component): component._execute(undoManager: undoManager, context: context)
        }
    }
    
    public var _isEmpty: Bool {
        switch storage {
        case .first(let first):
            first._isEmpty
        case .second(let second):
            second._isEmpty
        }
    }
}
