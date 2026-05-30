//
//  Methods.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation


extension UndoTracking {

    /// Replace the value indicated by the `keyPath` with the `newValue`
    @MainActor
    public func replace<T>(
        _ keyPath: ReferenceWritableKeyPath<Self, T>, with newValue: T
    ) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var value = newValue
            
            withAnimation {
                swap(&value, &target[keyPath: keyPath])
            }

            registerUndo {
                target.replace(keyPath, with: value)
            }
        }
    }


    @MainActor
    public func replace<T1, T2>(
        _ keyPath1: ReferenceWritableKeyPath<Self, T1>, with newValue1: T1,
        _ keyPath2: ReferenceWritableKeyPath<Self, T2>, with newValue2: T2
    ) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var value1 = newValue1
            var value2 = newValue2
            
            withAnimation {
                swap(&value1, &target[keyPath: keyPath1])
                swap(&value2, &target[keyPath: keyPath2])
            }

            registerUndo {
                target.replace(
                    keyPath1, with: value1,
                    keyPath2, with: value2
                )
            }
        }
    }

    @MainActor
    public func replace<T1, T2, T3>(
        _ keyPath1: ReferenceWritableKeyPath<Self, T1>, with newValue1: T1,
        _ keyPath2: ReferenceWritableKeyPath<Self, T2>, with newValue2: T2,
        _ keyPath3: ReferenceWritableKeyPath<Self, T3>, with newValue3: T3
    ) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var value1 = newValue1
            var value2 = newValue2
            var value3 = newValue3
            
            withAnimation {
                swap(&value1, &target[keyPath: keyPath1])
                swap(&value2, &target[keyPath: keyPath2])
                swap(&value3, &target[keyPath: keyPath3])
            }

            registerUndo {
                target.replace(
                    keyPath1, with: value1,
                    keyPath2, with: value2,
                    keyPath3, with: value3
                )
            }
        }
    }

    @MainActor
    public func replace<T1, T2, T3, T4>(
        _ keyPath1: ReferenceWritableKeyPath<Self, T1>, with newValue1: T1,
        _ keyPath2: ReferenceWritableKeyPath<Self, T2>, with newValue2: T2,
        _ keyPath3: ReferenceWritableKeyPath<Self, T3>, with newValue3: T3,
        _ keyPath4: ReferenceWritableKeyPath<Self, T4>, with newValue4: T4
    ) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var value1 = newValue1
            var value2 = newValue2
            var value3 = newValue3
            var value4 = newValue4
            
            withAnimation {
                swap(&value1, &target[keyPath: keyPath1])
                swap(&value2, &target[keyPath: keyPath2])
                swap(&value3, &target[keyPath: keyPath3])
                swap(&value4, &target[keyPath: keyPath4])
            }

            registerUndo {
                target.replace(
                    keyPath1, with: value1,
                    keyPath2, with: value2,
                    keyPath3, with: value3,
                    keyPath4, with: value4
                )
            }
        }
    }

    @MainActor
    public func replace<T1, T2, T3, T4, T5>(
        _ keyPath1: ReferenceWritableKeyPath<Self, T1>, with newValue1: T1,
        _ keyPath2: ReferenceWritableKeyPath<Self, T2>, with newValue2: T2,
        _ keyPath3: ReferenceWritableKeyPath<Self, T3>, with newValue3: T3,
        _ keyPath4: ReferenceWritableKeyPath<Self, T4>, with newValue4: T4,
        _ keyPath5: ReferenceWritableKeyPath<Self, T5>, with newValue5: T5
    ) -> UndoComponent<Self> {
        UndoComponent(target: self) { target, withAnimation, registerUndo in
            var value1 = newValue1
            var value2 = newValue2
            var value3 = newValue3
            var value4 = newValue4
            var value5 = newValue5
            
            withAnimation {
                swap(&value1, &target[keyPath: keyPath1])
                swap(&value2, &target[keyPath: keyPath2])
                swap(&value3, &target[keyPath: keyPath3])
                swap(&value4, &target[keyPath: keyPath4])
                swap(&value5, &target[keyPath: keyPath5])
            }

            registerUndo {
                target.replace(
                    keyPath1, with: value1,
                    keyPath2, with: value2,
                    keyPath3, with: value3,
                    keyPath4, with: value4,
                    keyPath5, with: value5
                )
            }
        }
    }

}
