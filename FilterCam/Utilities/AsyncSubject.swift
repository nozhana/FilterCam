//
//  AsyncSubject.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import Foundation

struct AsyncSubject<T>: AsyncSequence {
    typealias SourceStream = AsyncStream<T>
    
    let stream: SourceStream
    private let continuation: SourceStream.Continuation
    
    fileprivate init(stream: SourceStream, continuation: SourceStream.Continuation) {
        self.stream = stream
        self.continuation = continuation
    }
    
    init(bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .bufferingNewest(10)) {
        let (stream, continuation) = AsyncStream.makeStream(of: T.self, bufferingPolicy: bufferingPolicy)
        self.init(stream: stream, continuation: continuation)
    }
    
    func send(_ value: T) {
        continuation.yield(value)
    }
    
    func makeAsyncIterator() -> SourceStream.AsyncIterator {
        stream.makeAsyncIterator()
    }
}

extension AsyncSubject {
    static func of(_ type: T.Type, bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .bufferingNewest(10)) -> Self {
        .init(bufferingPolicy: bufferingPolicy)
    }
    
    static func currentValue(_ value: T, bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .bufferingNewest(10)) -> Self {
        let subject = AsyncSubject(bufferingPolicy: bufferingPolicy)
        subject.send(value)
        return subject
    }
}
