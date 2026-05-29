//
//  Essentials.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
import Testing
import UndoTracking


@Suite
@MainActor
struct Essentials {

    @Test func undoRedoRoundTrip() {
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

    @Test func undoGroupingBasic() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.canUndo)
        #expect(undoManager.groupingLevel == 1)
        #expect(model.index == 2)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 2)
    }
    
    @Test func undoTwiceNoGroup() {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let model = Model()

        // undoManager groups events together in the same run loop by default, so needs explicit grouping.
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        undoManager.endUndoGrouping()
        
        undoManager.beginUndoGrouping()
        withUndoTracking(undoManager) {
            model.increment()
                .named("Increment")
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.canUndo)
        if #available(macOS 14.4, *) {
            #expect(undoManager.undoCount == 2)
        }
        #expect(undoManager.groupingLevel == 0)
        #expect(model.index == 2)

        #expect(undoManager.canUndo)
        undoManager.undo()
        if #available(macOS 14.4, *) {
            #expect(undoManager.undoCount == 1)
        }
        #expect(model.index == 1)
        
        #expect(undoManager.canUndo)
        undoManager.undo()
        if #available(macOS 14.4, *) {
            #expect(undoManager.undoCount == 0)
        }
        #expect(model.index == 0)
    }

    @Test func undoNestedGroupingBasic() {
        let undoManager = UndoManager()
        let model = Model()

        undoManager.beginUndoGrouping()
        for _ in 0..<2 {
            undoManager.beginUndoGrouping()
            withUndoTracking(undoManager) {
                model.increment()
                    .named("Increment")
            }
            withUndoTracking(undoManager) {
                model.increment()
                    .named("Increment")
            }
            undoManager.endUndoGrouping()
        }
        undoManager.endUndoGrouping()

        #expect(undoManager.canUndo)
        #expect(model.index == 4)

        undoManager.undo()
        #expect(model.index == 0)

        undoManager.redo()
        #expect(model.index == 4)
    }

    @Test func moveAndRemoveByOffsets() {
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
