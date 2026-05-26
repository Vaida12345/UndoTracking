//
//  Helpers.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation
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


final class Item: UndoTracking, Identifiable {

    let id: Int
    var value: String

    init(id: Int, value: String) {
        self.id = id
        self.value = value
    }

}
