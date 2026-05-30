//
//  UndoTracking.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//


/// A protocol providing methods for dealing with undos.
///
/// This protocol does not have any requirement other than being a `class`. However, this protocol provides methods such as ``append(_:to:)``.
///
/// > Example:
/// > Start by declaring a class that conforms to this protocol
/// >
/// > ```swift
/// > final class Model: UndoTracking {
/// >     var container: [Double]
/// > }
/// > ```
/// >
/// > When making modifications, use one of the methods this protocol provide to support Undo / Redo.
/// > ```
/// > let model = Model()
/// > model.append(0, to \.container)
/// > ```
public protocol UndoTracking: AnyObject {
    
}
