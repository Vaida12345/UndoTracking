//
//  Methods.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation


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
            let elements = Array(sequence)

            withAnimation {
                target[keyPath: keyPath].append(contentsOf: elements)
            }

            registerUndo {
                target.removeLast(elements.count, from: keyPath)
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
                for index in removed.map(\.0).reversed() {
                    target[keyPath: keyPath].remove(at: index)
                }
            }
            
            registerUndo {
                target.insert(inserts: removed, keyPath: keyPath, where: shouldBeRemoved)
            }
        }
    }
    
    /// Inverse of `removeAll(from:where:)` — re-inserts elements that were removed by a predicate-based removal.
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
    
    /// Removes all elements with the given id.
    ///
    /// - Warning: All elements with the id matching that of `element` will be removed.
    ///
    /// - Parameters:
    ///   - id: The if to element to be removed.
    ///   - keyPath: The key path to the array.
    public func remove<E>(_ id: E.ID, from keyPath: ReferenceWritableKeyPath<Self, Array<E>>) -> UndoComponent<Self> where E: Identifiable {
        self.removeAll(from: keyPath, where: { $0.id == id })
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
            let removed = target[keyPath: keyPath][(target[keyPath: keyPath].count - k)..<target[keyPath: keyPath].count]
            withAnimation {
                target[keyPath: keyPath].removeLast(k)
            }
            
            registerUndo {
                target.append(contentsOf: removed, to: keyPath)
            }
        }
    }
    
    /// Replace the element at the specified index.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the array.
    ///   - index: The index of the element to replace.
    ///   - newValue: The new value to set at the index.
    public func replace<T>(_ keyPath: ReferenceWritableKeyPath<Self, Array<T>>, at index: Int, with newValue: T) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let removed = target[keyPath: keyPath][index]
            withAnimation {
                target[keyPath: keyPath][index] = newValue
            }

            registerUndo {
                target.replace(keyPath, at: index, with: removed)
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


extension UndoTracking {
    
    /// Inverse of `move` — restores the original element order given the IDs in their previous sequence.
    private func reorder<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, using ids: [T.Element.ID]) -> UndoComponent<Self> where T: MutableCollection & RandomAccessCollection, T.Element: Identifiable {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let old = target[keyPath: keyPath].map(\.id)
            
            withAnimation {
                let order = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
                target[keyPath: keyPath].sort { (a, b) in
                    guard let ia = order[a.id], let ib = order[b.id] else { return false }
                    return ia < ib
                }
            }
            
            registerUndo {
                target.reorder(keyPath, using: old)
            }
        }
    }
    
    /// Moves all the elements at the specified offsets to the specified destination offset, preserving ordering.
    public func move<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, fromOffsets source: IndexSet, toOffset destination: Int) -> UndoComponent<Self> where T: MutableCollection & RandomAccessCollection, T.Element: Identifiable {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let ids = target[keyPath: keyPath].map(\.id)
            
            withAnimation {
                target[keyPath: keyPath].move(fromOffsets: source, toOffset: destination)
            }
            registerUndo {
                target.reorder(keyPath, using: ids)
            }
        }
    }
    
    
    /// Inverse of `remove(atOffsets:)` — re-inserts elements at the offsets from which they were removed.
    private func insert<T>(inserts: [(T.Index, T.Element)], keyPath: ReferenceWritableKeyPath<Self, T>) -> UndoComponent<Self> where T: MutableCollection & RangeReplaceableCollection, T.Index == Int {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                for tuple in inserts {
                    target[keyPath: keyPath].insert(tuple.1, at: tuple.0)
                }
            }
            
            registerUndo {
                target.remove(keyPath, atOffsets: IndexSet(inserts.map(\.0)))
            }
        }
    }
    
    /// Removes all the elements at the specified offsets from the collection.
    public func remove<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, atOffsets offsets: IndexSet) -> UndoComponent<Self> where T: RangeReplaceableCollection & MutableCollection, T.Index == Int {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let removes = offsets.map({ ($0, target[keyPath: keyPath][$0]) })
            withAnimation {
                target[keyPath: keyPath].remove(atOffsets: offsets)
            }
            registerUndo {
                target.insert(inserts: removes, keyPath: keyPath)
            }
        }
    }
    
}
