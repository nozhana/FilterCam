//
//  KVOAsyncObserver.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

@propertyWrapper
class KVOAsyncObserver<Parent: NSObject, Child>: NSObject {
    private let keyPath: KeyPath<Parent, Child>
    
    typealias ChildStream = AsyncStream<Child?>
    let changes: ChildStream
    private let continuation: ChildStream.Continuation
    
    var wrappedValue: Child?
    
    init(_ parent: Parent, child keyPath: KeyPath<Parent, Child>) {
        self.keyPath = keyPath
        (changes, continuation) = AsyncStream.makeStream()
        
        super.init()
        
        parent.addObserver(self, forKeyPath: "\(keyPath)", options: [.new], context: nil)
    }
    
    deinit {
        continuation.finish()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "\(self.keyPath)":
            let newValue = change?[.newKey] as? Child
            continuation.yield(newValue)
            wrappedValue = newValue
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
