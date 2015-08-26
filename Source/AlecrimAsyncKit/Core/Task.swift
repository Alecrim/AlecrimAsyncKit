//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public class BaseTask<V> {
    
    private var value: V!
    private var error: ErrorType?
    
    private let dispatchGroup: dispatch_group_t = dispatch_group_create()
    private var waiting = true
    private var spinlock = OS_SPINLOCK_INIT
    
    private let observers: [TaskObserver<V>]?
    
    private init(observers: [TaskObserver<V>]?) {
        //
        self.observers = observers
        
        //
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
        //
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        
        assert(self.value == nil && self.error == nil, "value or error can be assigned only once.")
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
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
        
        //
        dispatch_group_leave(self.dispatchGroup)
        
        //
        self.observers?.forEach { $0.taskDidFinish(self) }
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

}


public final class Task<V>: BaseTask<V> {
    
    public var cancelled: Bool {
        var c = false
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        if let error = self.error as? NSError where error.code == NSUserCancelledError {
            c = true
        }
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)

        return c
    }
    
    internal init(queue: NSOperationQueue, observers: [TaskObserver<V>]?, conditions: [TaskCondition]?, closure: (Task<V>) -> Void) {
        super.init(observers: observers)

        do {
            if let conditions = conditions where !conditions.isEmpty {
                try await(TaskCondition.asyncEvaluateConditions(conditions))
            }
            
            if !self.cancelled {
                queue.addOperationWithBlock {
                    if !self.cancelled {
                        self.observers?.forEach { $0.taskDidStart(self) }
                        closure(self)
                    }
                }
            }
        }
        catch {
            
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
        self.setValue(nil, error: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
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

public final class NonFailableTask<V>: BaseTask<V> {

    internal init(queue: NSOperationQueue, observers: [TaskObserver<V>]?, closure: (NonFailableTask<V>) -> Void) {
        super.init(observers: observers)

        queue.addOperationWithBlock {
            self.observers?.forEach { $0.taskDidStart(self) }
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
