//
//  UndoGroupBuilder.swift
//  UndoTracking
//
//  Created by Vaida on 2026-05-29.
//


@resultBuilder
public enum UndoGroupBuilder {
    
    public static func buildBlock<T: _UndoComponentProtocol>(_ content: T) -> T where T: _UndoComponentProtocol {
        content
    }
    
    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
    public static func buildBlock<each T>(_ content: repeat each T) -> _TupleComponent<repeat each T> where repeat each T: _UndoComponentProtocol {
        _TupleComponent(content: (repeat each content))
    }
    
    public static func buildOptional<T: _UndoComponentProtocol>(_ component: T?) -> _ConditionalComponent<T> {
        _ConditionalComponent(content: component)
    }
    
    public static func buildArray<T: _UndoComponentProtocol>(_ components: [T]) -> _ArrayComponent<T> {
        _ArrayComponent(content: components)
    }

    public static func buildEither<First: _UndoComponentProtocol, Second: _UndoComponentProtocol>(first component: First) -> _EitherComponent<First, Second> {
        _EitherComponent(.first(component))
    }

    public static func buildEither<First: _UndoComponentProtocol, Second: _UndoComponentProtocol>(second component: Second) -> _EitherComponent<First, Second> {
        _EitherComponent(.second(component))
    }

}
