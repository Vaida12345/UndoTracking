//
//  Methods.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//


extension UndoTracking {
    
    /// Adds a new element at the end of the array.
    ///
    /// Use this method to append a single element to the end of a mutable array, with the `UndoManager` tracking the changes.
    ///
    /// - Parameters:
    ///   - newElement: The element to append to the array.
    ///   - keyPath: The key path to the array.
    public func append<E>(_ newElement: E, to keyPath: ReferenceWritableKeyPath<Self, Array<E>>) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let index = target[keyPath: keyPath].count
            
            withAnimation {
                target[keyPath: keyPath].append(newElement)
            }
            
            registerUndo {
                target.remove(at: index, from: keyPath)
            }
        }
    }
    
    /// Adds the elements of a sequence to the end of the array.
    ///
    /// Use this method to append the elements of a sequence to the end of this array.
    ///
    /// - Parameters:
    ///   - sequence: The elements to append to the array.
    ///   - keyPath: The key path to the array.
    public func append<E>(contentsOf sequence: some Sequence<E>, to keyPath: ReferenceWritableKeyPath<Self, Array<E>>) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let index = target[keyPath: keyPath].count
            
            withAnimation {
                target[keyPath: keyPath].append(contentsOf: sequence)
            }
            
            registerUndo {
                target.remove(at: index, from: keyPath)
            }
        }
    }
    
    /// Inserts a new element at the specified position.
    ///
    /// The new element is inserted before the element currently at the specified index. If you pass the array's `endIndex` property as the `index` parameter, the new element is appended to the array.
    ///
    /// - Parameters:
    ///   - newElement: The element to append to the array.
    ///   - index: The index indicating the position where the `newElement` is inserted.
    ///   - keyPath: The key path to the array.
    public func insert<E>(_ newElement: E, at index: Int, to keyPath: ReferenceWritableKeyPath<Self, Array<E>>) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                target[keyPath: keyPath].insert(newElement, at: index)
            }
            
            registerUndo {
                target.remove(at: index, from: keyPath)
            }
        }
    }
    
    /// Removes all the elements that satisfy the given predicate.
    ///
    /// Use this method to remove every element in a collection that meets particular criteria. The order of the remaining elements is preserved.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the array.
    ///   - shouldBeRemoved: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be removed from the collection.
    public func removeAll<E>(from keyPath: ReferenceWritableKeyPath<Self, Array<E>>, where shouldBeRemoved: @escaping (E) -> Bool) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var removed: [(Int, E)] = []
            for tuple in target[keyPath: keyPath].enumerated() {
                if shouldBeRemoved(tuple.element) {
                    removed.append(tuple)
                }
            }
            
            withAnimation {
                target[keyPath: keyPath].removeAll(where: shouldBeRemoved)
            }
            
            registerUndo {
                target.insert(inserts: removed, keyPath: keyPath, where: shouldBeRemoved)
            }
        }
    }
    
    private func insert<E>(inserts: [(Int, E)], keyPath: ReferenceWritableKeyPath<Self, Array<E>>, where shouldBeRemoved: @escaping (E) -> Bool) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                for tuple in inserts {
                    target[keyPath: keyPath].insert(tuple.1, at: tuple.0)
                }
            }
            
            registerUndo {
                target.removeAll(from: keyPath, where: shouldBeRemoved)
            }
        }
    }
    
    /// Removes the element at the specified position.
    ///
    /// - Parameters:
    ///   - index: The index of the removing element.
    ///   - keyPath: The key path to the array.
    public func remove<E>(at index: Int, from keyPath: ReferenceWritableKeyPath<Self, Array<E>>) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let removed = target[keyPath: keyPath][index]
            withAnimation {
                target[keyPath: keyPath].remove(at: index)
            }
            
            registerUndo {
                target.insert(removed, at: index, to: keyPath)
            }
        }
    }
    
    /// Removes the element by matching its id.
    ///
    /// - Warning: All elements with the id matching that of `element` will be removed.
    ///
    /// - Parameters:
    ///   - element: The element to be removed.
    ///   - keyPath: The key path to the array.
    public func remove<E>(_ element: E, from keyPath: ReferenceWritableKeyPath<Self, Array<E>>) -> UndoComponent<Self> where E: Identifiable {
        self.removeAll(from: keyPath, where: { $0.id == element.id })
    }
    
    /// Removes the specified number of elements from the end of the collection.
    ///
    /// Attempting to remove more elements than exist in the collection triggers a runtime error.
    ///
    /// - Parameters:
    ///   - k: The number of elements to be removed.
    ///   - keyPath: The key path to the array.
    public func removeLast<E>(_ k: Int, from keyPath: ReferenceWritableKeyPath<Self, Array<E>>) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let removed = target[keyPath: keyPath][(target[keyPath: keyPath].count - 1 - k)..<target[keyPath: keyPath].count]
            withAnimation {
                target[keyPath: keyPath].removeLast(k)
            }
            
            registerUndo {
                target.append(contentsOf: removed, to: keyPath)
            }
        }
    }
    
    /// Replace the value indicated by the `keyPath` with the `newValue`
    ///
    /// - Precondition: You need to ensure the `T` is a `struct`.
    public func replace<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, with newValue: T) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let removed = target[keyPath: keyPath]
            withAnimation {
                target[keyPath: keyPath] = newValue
            }
            
            registerUndo {
                target.replace(keyPath, with: removed)
            }
        }
    }
    
}
