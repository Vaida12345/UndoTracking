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
    
    public func _makeExecutable() -> _TupleComponentExecutable<repeat each T> {
        _TupleComponentExecutable(content: (repeat (each content)._makeExecutable()))
    }
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
public struct _TupleComponentExecutable<each T>: _UndoExecutableProtocol where repeat each T: _UndoComponentProtocol {
    let content: (repeat (each T)._UndoExecutable)
    
    public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
        for item in repeat each content {
            // Each child's own _execute handles emptiness internally,
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
    
    public func _makeExecutable() -> _UndoExecutable {
        _UndoExecutable(content: content?._makeExecutable())
    }
    
    public struct _UndoExecutable: _UndoExecutableProtocol {
        let content: T._UndoExecutable?
        
        public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
            content?._execute(undoManager: undoManager, context: context)
        }
        
        public var _isEmpty: Bool {
            content?._isEmpty ?? true
        }
    }
}


public struct _ArrayComponent<T: _UndoComponentProtocol>: _UndoComponentProtocol {
    let content: [T]
    
    public func _makeExecutable() -> _UndoExecutable {
        _UndoExecutable(content: self.content.map({ $0._makeExecutable() }))
    }

    public struct _UndoExecutable: _UndoExecutableProtocol {
        let content: [T._UndoExecutable]
        
        public func _execute(undoManager: UndoManager?, context: _UndoComponentContext) {
            for item in content {
                // Each child's own _execute handles emptiness internally,
                item._execute(undoManager: undoManager, context: context)
            }
        }
        
        public var _isEmpty: Bool {
            content.allSatisfy({ $0._isEmpty })
        }
    }
}


public struct _EitherComponent<First: _UndoComponentProtocol, Second: _UndoComponentProtocol>: _UndoComponentProtocol {
    
    public func _makeExecutable() -> _UndoExecutable {
        _UndoExecutable(storage: storage._makeExecutable())
    }
    
    let storage: Storage
    enum Storage {
        case first(First)
        case second(Second)
        
        func _makeExecutable() -> _UndoExecutable.Storage {
            switch self {
            case .first(let first):
                return .first(first._makeExecutable())
            case .second(let second):
                return .second(second._makeExecutable())
            }
        }
    }

    init(_ storage: Storage) {
        self.storage = storage
    }
    
    
    public struct _UndoExecutable: _UndoExecutableProtocol {
        let storage: Storage
        enum Storage {
            case first(First._UndoExecutable)
            case second(Second._UndoExecutable)
        }
        
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
}
