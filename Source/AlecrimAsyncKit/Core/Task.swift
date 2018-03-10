//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: - Task

public class BaseTask<Value> {
    
    //
    
    private let group: DispatchGroup
    private var closure: AsyncTaskFullClosure<Value>?
    
    // these 3 variables must be accessed only in `finish(with:or:)` and using the `lock()` / `unlock()` functions below

    private var isFinished = false
    internal private(set) var value: Value?
    internal private(set) var error: Error?
    
    private var _lock = os_unfair_lock_s()
    private func lock() { os_unfair_lock_lock(&self._lock) }
    private func unlock() { os_unfair_lock_unlock(&self._lock) }

    //
    
    internal init(closure: @escaping AsyncTaskFullClosure<Value>) {
        self.group = DispatchGroup()
        self.closure = closure
        
        self.group.enter()
    }

    internal func start() {
        if let closure = self.closure {
            self.closure = nil
            closure(self)
        }
    }
    
    internal func await() throws -> Value {
        self.wait()
        
        guard let value = self.value else {
            guard let error = self.error else {
                fatalError("Unexpected: error cannot be nil")
            }
            
            throw error
        }
        
        return value
    }
    
    //
    
    public func wait() {
        precondition(!Thread.isMainThread)
        self.group.wait()
    }
    
    // cancellation support
    
    public private(set) lazy var cancellation = Cancellation()

    public var isCancelled: Bool {
        return self.error?.isUserCancelled ?? false
    }
    
    //
    
    public func finish(with value: Value) {
        self.finish(with: value, or: nil)
    }
    
    public func finish(with error: Error) {
        self.finish(with: nil, or: error)
    }
    
    public func finish(with value: Value?, or error: Error?) {
        self.lock(); defer { self.unlock() }

        guard !self.isFinished else {
            return
        }
        
        self.value = value
        self.error = error

        self.isFinished = true

        self.group.leave()
    }
    
}

extension BaseTask where Value == Void {
    
    public func finish() {
        self.finish(with: (), or: nil)
    }
    
}

// MARK: - Task

public final class Task<Value>: BaseTask<Value>, CancellableTask {
    
}

// MARK: - NonFailableTask

public final class NonFailableTask<Value>: BaseTask<Value> {
    
    @available(*, unavailable, message: "Non failable tasks cannot be cancelled")
    public override var cancellation: Cancellation {
        fatalError("Non failable tasks cannot be cancelled")
    }
    
    @available(*, unavailable, message: "Non failable tasks cannot be cancelled")
    public override var isCancelled: Bool {
        fatalError("Non failable tasks cannot be cancelled")
    }
    
    @available(*, unavailable, message: "Non failable tasks cannot be finished with error")
    public override func finish(with error: Error) {
        fatalError("Non failable tasks cannot be finished with error")
    }
    
    @available(*, unavailable, message: "Non failable tasks cannot be finished with error")
    public override func finish(with value: Value?, or error: Error?) {
        fatalError("Non failable tasks cannot be finished with error")
    }
    
}
