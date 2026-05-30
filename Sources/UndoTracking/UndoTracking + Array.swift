//
//  UndoTracking + Array.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-30.
//

import Foundation


// MARK: - Insert / Remove
extension UndoTracking {
    
    /// Removes the element at the specified position.
    ///
    /// - Parameters:
    ///   - index: The index of the removing element.
    ///   - keyPath: The key path to the array.
    @MainActor
    public func remove<C>(
        at index: C.Index,
        from keyPath: ReferenceWritableKeyPath<Self, C>
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection {
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
    
    /// Inserts a new element at the specified position.
    ///
    /// The new element is inserted before the element currently at the specified index. If you pass the array's `endIndex` property as the `index` parameter, the new element is appended to the array.
    ///
    /// - Parameters:
    ///   - newElement: The element to append to the array.
    ///   - index: The index indicating the position where the `newElement` is inserted.
    ///   - keyPath: The key path to the array.
    @MainActor
    public func insert<C>(
        _ newElement: C.Element,
        at index: C.Index,
        to keyPath: ReferenceWritableKeyPath<Self, C>
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                target[keyPath: keyPath].insert(newElement, at: index)
            }
            
            registerUndo {
                target.remove(at: index, from: keyPath)
            }
        }
    }
    
    /// Adds a new element at the end of the array.
    ///
    /// Use this method to append a single element to the end of a mutable array, with the `UndoManager` tracking the changes.
    ///
    /// - Parameters:
    ///   - newElement: The element to append to the array.
    ///   - keyPath: The key path to the array.
    @MainActor
    public func append<C>(
        _ newElement: sending C.Element,
        to keyPath: sending ReferenceWritableKeyPath<Self, C>
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            let index = target[keyPath: keyPath].endIndex
            
            withAnimation {
                target[keyPath: keyPath].append(newElement)
            }
            
            registerUndo {
                target.remove(at: index, from: keyPath)
            }
        }
    }
    
}


// MARK: - append / remove sequence
extension UndoTracking {
    
    /// Adds the elements of a sequence to the end of the array.
    ///
    /// Use this method to append the elements of a sequence to the end of this array.
    ///
    /// - Parameters:
    ///   - sequence: The elements to append to the array.
    ///   - keyPath: The key path to the array.
    @MainActor
    public func append<C>(
        contentsOf sequence: some Collection<C.Element>,
        to keyPath: ReferenceWritableKeyPath<Self, C>
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection & BidirectionalCollection {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            withAnimation {
                target[keyPath: keyPath].append(contentsOf: sequence)
            }
            
            registerUndo {
                target.removeLast(sequence.count, from: keyPath)
            }
        }
    }
    
    /// Removes the specified number of elements from the end of the collection.
    ///
    /// Attempting to remove more elements than exist in the collection triggers a runtime error.
    ///
    /// - Parameters:
    ///   - k: The number of elements to be removed.
    ///   - keyPath: The key path to the array.
    @MainActor
    public func removeLast<C>(
        _ k: Int,
        from keyPath: ReferenceWritableKeyPath<Self, C>
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection & BidirectionalCollection {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var startIndex = target[keyPath: keyPath].endIndex
            target[keyPath: keyPath].formIndex(&startIndex, offsetBy: -k) // this requires BidirectionalCollection
            let removed = target[keyPath: keyPath][startIndex..<target[keyPath: keyPath].endIndex]
            withAnimation {
                target[keyPath: keyPath].removeLast(k)
            }
            
            registerUndo {
                target.append(contentsOf: removed, to: keyPath)
            }
        }
    }
    
}

// MARK: - replace

extension UndoTracking {
    
    /// Replace the element at the specified index.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the array.
    ///   - index: The index of the element to replace.
    ///   - newValue: The new value to set at the index.
    @MainActor
    public func replace<T>(
        _ keyPath: ReferenceWritableKeyPath<Self, Array<T>>,
        at index: Int,
        with newValue: T
    ) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var value = newValue
            withAnimation {
                swap(&value, &target[keyPath: keyPath][index])
            }
            
            registerUndo {
                target.replace(keyPath, at: index, with: value)
            }
        }
    }
    
}


extension UndoTracking {
    
    /// Inverse of `move` — restores the original element order given the IDs in their previous sequence.
    @MainActor
    private func reorder<T>(
        _ keyPath: ReferenceWritableKeyPath<Self, T>,
        using ids: [T.Element.ID]
    ) -> UndoComponent<Self> where T: MutableCollection & RandomAccessCollection, T.Element: Identifiable {
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
    @MainActor
    public func move<T>(
        _ keyPath: ReferenceWritableKeyPath<Self, T>,
        fromOffsets source: IndexSet,
        toOffset destination: Int
    ) -> UndoComponent<Self> where T: MutableCollection & RandomAccessCollection, T.Element: Identifiable {
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
    @MainActor
    private func insert<T>(
        inserts: [(T.Index, T.Element)],
        keyPath: ReferenceWritableKeyPath<Self, T>
    ) -> UndoComponent<Self> where T: MutableCollection & RangeReplaceableCollection, T.Index == Int {
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
    @MainActor
    public func remove<T>(
        _ keyPath: ReferenceWritableKeyPath<Self, T>,
        atOffsets offsets: IndexSet
    ) -> UndoComponent<Self> where T: RangeReplaceableCollection & MutableCollection, T.Index == Int {
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


// MARK: - remove All
extension UndoTracking {
    
    /// Inverse of `removeAll(from:where:)` — re-inserts elements that were removed by a predicate-based removal.
    @MainActor
    private func insert<C>(
        inserts: [(C.Index, C.Element)],
        keyPath: ReferenceWritableKeyPath<Self, C>,
        where shouldBeRemoved: @escaping (C.Element) -> Bool
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection {
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
    
    /// Removes all the elements that satisfy the given predicate.
    ///
    /// Use this method to remove every element in a collection that meets particular criteria. The order of the remaining elements is preserved.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the array.
    ///   - shouldBeRemoved: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be removed from the collection.
    ///
    /// - Complexity: O(m\*n)
    @MainActor
    public func removeAll<C>(
        from keyPath: ReferenceWritableKeyPath<Self, C>,
        where shouldBeRemoved: @escaping (C.Element) -> Bool
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var removed: [(C.Index, C.Element)] = []
            let collection = target[keyPath: keyPath]
            var index = collection.startIndex
            let endIndex = collection.endIndex
            while index < endIndex {
                let value = collection[index]
                defer { collection.formIndex(after: &index) }
                guard shouldBeRemoved(value) else { continue }
                removed.append((index, value))
            }
            
            withAnimation {
                for (index, _) in removed.reversed() {
                    target[keyPath: keyPath].remove(at: index)
                }
            }
            
            registerUndo {
                target.insert(inserts: removed, keyPath: keyPath, where: shouldBeRemoved)
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
    @inlinable
    @MainActor
    public func remove<C>(
        _ id: C.Element.ID,
        from keyPath: ReferenceWritableKeyPath<Self, C>
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection, C.Element: Identifiable {
        self.removeAll(from: keyPath, where: { $0.id == id })
    }
    
    /// Removes the element by matching its id.
    ///
    /// - Warning: All elements with the id matching that of `element` will be removed.
    ///
    /// - Parameters:
    ///   - element: The element to be removed.
    ///   - keyPath: The key path to the array.
    @inlinable
    @MainActor
    public func remove<C>(
        _ element: C.Element,
        from keyPath: ReferenceWritableKeyPath<Self, C>
    ) -> UndoComponent<Self> where C: RangeReplaceableCollection, C.Element: Identifiable {
        self.remove(element.id, from: keyPath)
    }
    
}
