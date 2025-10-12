//
//  Essentials.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import Testing
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
    
}

@Suite
@MainActor
struct Essentials {
    
    @Test func undo() {
        let undoManager = UndoManager()
        let model = Model()
        
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        
        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Increment")
        #expect(model.index == 1)
        undoManager.undo()
        #expect(!undoManager.canUndo)
        #expect(undoManager.canRedo)
        #expect(undoManager.redoMenuItemTitle == "Redo Increment")
        #expect(model.index == 0)
        undoManager.redo()
        #expect(!undoManager.canRedo)
        #expect(undoManager.canUndo)
        #expect(undoManager.undoMenuItemTitle == "Undo Increment")
        #expect(model.index == 1)
    }
    
    @Test func indexes() {
        let undoManager = UndoManager()
        let container = Container([Container(1), Container(2), Container(3), Container(4), Container(5)])
        var copy = container.content
        
        withUndoTracking(undoManager) {
            container.move(\.content, fromOffsets: [3, 4], toOffset: 0)
        }
        
        copy.move(fromOffsets: [3, 4], toOffset: 0)
        #expect(copy == container.content)
        #expect(undoManager.canUndo)
        
        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])
        
        
        withUndoTracking(undoManager) {
            container.remove(\.content, atOffsets: [1, 3])
        }
        
        #expect(container.content.map(\.content) == [1, 3, 5])
        #expect(undoManager.canUndo)
        
        undoManager.undo()
        #expect(container.content.map(\.content) == [1, 2, 3, 4, 5])
    }
    
}
