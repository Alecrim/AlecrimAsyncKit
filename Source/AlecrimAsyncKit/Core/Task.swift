//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

internal let taskCancelledError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)

// MARK: - protocols needed to support task observers in this version

public protocol TaskType: class {
}

public protocol FailableTaskType: TaskType {
    func cancel()
}

public protocol NonFailableTaskType: TaskType {
}

// MARK: -

public class BaseTask<V>: TaskType {
    
    public private(set) var value: V!
    public private(set) var error: ErrorType?
    
    private let dispatchGroup: dispatch_group_t = dispatch_group_create()
    private var waiting = true
    private var spinlock = OS_SPINLOCK_INIT
    
    private var deferredClosures: Array<() -> Void>?
    
    private init() {
        dispatch_group_enter(self.dispatchGroup)
    }
    
    deinit {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        assert(!self.waiting, "Either value or error were never assigned or task was never cancelled.")
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
    }
    
    private final func waitForCompletion() {
        assert(!NSThread.isMainThread(), "Cannot wait task on main thread.")
        dispatch_group_wait(self.dispatchGroup, DISPATCH_TIME_FOREVER)
    }
    
    private final func setValue(value: V?, error: ErrorType?) {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        defer {
            withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)

            //
            self.deferredClosures?.forEach { $0() }
            self.deferredClosures = nil
        }
        
        // assert(self.value == nil && self.error == nil, "value or error can be assigned only once.")
        // we do not assert anymore, but the value or error can be assigned only once anyway
        guard self.value == nil && self.error == nil else { return }
        
        assert(value != nil || error != nil, "Invalid combination of value/error.")
        
        if let error = error {
            self.value = nil
            self.error = error
        }
        else {
            self.value = value
            self.error = nil
        }
        
        self.waiting = false
        
        //
        dispatch_group_leave(self.dispatchGroup)
    }
    
    // MARK: -
    
    public final func finish() {
        if V.self is Void.Type {
            self.setValue((() as! V), error: nil)
        }
        else {
            fatalError("`Self.ValueType` is not `Void`.")
        }
    }
    
    public final func finishWithValue(value: V) {
        self.setValue(value, error: nil)
    }

    // MARK: -

    private func addDeferredClosure(deferredClosure: () -> Void) {
        if self.deferredClosures == nil {
            self.deferredClosures = [deferredClosure]
        }
        else {
            self.deferredClosures!.append(deferredClosure)
        }
    }
}


public final class Task<V>: BaseTask<V>, FailableTaskType {
    
    public var cancelled: Bool {
        var c = false
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        if let error = self.error as? NSError where error.code == NSUserCancelledError {
            c = true
        }
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)

        return c
    }
    
    internal init(queue: NSOperationQueue, observers: [TaskObserver]?, conditions: [TaskCondition]?, closure: (Task<V>) -> Void) {
        assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
        super.init()

        do {
            if let conditions = conditions where !conditions.isEmpty {
                let mutuallyExclusiveConditions = conditions.flatMap { $0 as? MutuallyExclusiveTaskCondition }
                if !mutuallyExclusiveConditions.isEmpty {
                    mutuallyExclusiveConditions.forEach { mutuallyExclusiveCondition in
                        MutuallyExclusiveTaskCondition.increment(mutuallyExclusiveCondition.categoryName)
                        
                        self.addDeferredClosure {
                            MutuallyExclusiveTaskCondition.decrement(mutuallyExclusiveCondition.categoryName)
                        }
                    }
                }
                
                //
                try await(TaskCondition.asyncEvaluateConditions(conditions))
            }
            
            if !self.cancelled {
                queue.addOperationWithBlock {
                    if !self.cancelled {
                        if let observers = observers where !observers.isEmpty {
                            observers.forEach { $0.taskDidStart(self) }
                            self.addDeferredClosure { [unowned self] in
                                observers.forEach { $0.taskDidFinish(self) }
                            }
                        }
                        
                        closure(self)
                    }
                }
            }
        }
        catch let error {
            self.finishWithError(error)
        }
    }
    
    @warn_unused_result
    internal func waitForCompletionAndReturnValue() throws -> V {
        self.waitForCompletion()
        
        if let error = self.error {
            throw error
        }
        else {
            return self.value
        }
    }
    
    public func finishWithError(error: ErrorType) {
        self.setValue(nil, error: error)
    }
    
    public func finishWithValue(value: V?, error: ErrorType?) {
        self.setValue(value, error: error)
    }
    
    
    // MARK: -
    
    public func cancel() {
        self.setValue(nil, error: taskCancelledError)
    }
    
    // MARK: -
    
    public func continueWithTask(task: Task<V>) {
        do {
            let value = try task.waitForCompletionAndReturnValue()
            self.finishWithValue(value)
        }
        catch let error {
            self.finishWithError(error)
        }
    }

}

public final class NonFailableTask<V>: BaseTask<V>, NonFailableTaskType {

    internal init(queue: NSOperationQueue, observers: [TaskObserver]?, closure: (NonFailableTask<V>) -> Void) {
        assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
        super.init()

        queue.addOperationWithBlock {
            if let observers = observers where !observers.isEmpty {
                observers.forEach { $0.taskDidStart(self) }
                self.addDeferredClosure { [unowned self] in
                    observers.forEach { $0.taskDidFinish(self) }
                }
            }

            closure(self)
        }
    }
    
    @warn_unused_result
    internal func waitForCompletionAndReturnValue() -> V {
        self.waitForCompletion()
        return self.value
    }

    // MARK: -
    
    public func continueWithTask(task: NonFailableTask<V>) {
        let value = task.waitForCompletionAndReturnValue()
        self.finishWithValue(value)
    }

}
