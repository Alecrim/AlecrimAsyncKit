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
    
    internal let group: DispatchGroup

    private let dependency: TaskDependency?
    private let condition: TaskCondition?

    private var closure: AsyncTaskFullClosure<Value>?
    
    // these 3 variables must be accessed only in `finish(with:or:)` and using the `lock()` / `unlock()` functions below

    private var isFinished = false
    internal private(set) final var value: Value?
    internal private(set) final var error: Error?
    
    private var _lock = os_unfair_lock_s()
    private func lock() { os_unfair_lock_lock(&self._lock) }
    private func unlock() { os_unfair_lock_unlock(&self._lock) }

    //
    
    internal init(dependency: TaskDependency?, condition: TaskCondition?, closure: @escaping AsyncTaskFullClosure<Value>) {
        self.group = DispatchGroup()

        self.dependency = dependency
        self.condition = condition
        self.closure = closure
        
        self.group.enter()
    }

    //

    internal final func start() {
        if let semaphore = self.dependency as? TaskSemaphoreDependency {
            semaphore.wait()
        }

        if let dependency = self.dependency {
            dependency.notify(execute: self._start)
        }
        else {
            self._start()
        }
    }

    private func _start() {
        if let condition = self.condition {
            if condition.evaluate() {
                self.__start()
            }
            else {
                (self as? CancellableTask)?.cancel()
            }
        }
        else {
            self.__start()
        }
    }

    private func __start() {
        if let closure = self.closure {
            self.closure = nil

            if !self.isCancelled {
                closure(self)
            }
        }
    }

    //

    internal final func await() throws -> Value {
        self.wait()

        do {
            self.lock(); defer { self.unlock() }

            if let error = self.error {
                self.value = nil // to be sure
                throw error
            }

            guard let value = self.value else {
                fatalError("Unexpected: value cannot be nil")
            }

            return value
        }
    }
    
    //
    
    private final func wait() {
        precondition(!Thread.isMainThread)
        self.group.wait()
    }
    
    // cancellation support
    
    public private(set) lazy var cancellation = Cancellation()

    public var isCancelled: Bool {
        return self.error?.isUserCancelled ?? false
    }
    
    //
    
    public final func finish(with value: Value) {
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

        if let semaphore = self.dependency as? TaskSemaphoreDependency {
            semaphore.signal()
        }
    }
    
    //
    
    internal final func result() -> (value: Value?, error: Error?) {
        self.lock(); defer { self.unlock() }
        
        return (self.value, self.error)
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
        return super.isCancelled
    }
    
    @available(*, unavailable, message: "Non failable tasks cannot be finished with error")
    public override func finish(with error: Error) {
        fatalError("Non failable tasks cannot be finished with error")
    }
    
    @available(*, unavailable, message: "Non failable tasks cannot be finished with error")
    public override func finish(with value: Value?, or error: Error?) {
        guard error == nil else {
            fatalError("Non failable tasks cannot be finished with error")
        }

        super.finish(with: value, or: error)
    }
    
}
