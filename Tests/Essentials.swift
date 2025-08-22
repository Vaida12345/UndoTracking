//
//  Essentials.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import Testing
import UndoTracking


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
struct Essentials {
    
    @Test
    @MainActor
    func undo() {
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
    
}
