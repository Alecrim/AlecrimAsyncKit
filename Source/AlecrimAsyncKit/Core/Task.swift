//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: - Protocols needed to support task observers.

/// The basic task type protocol.
public protocol TaskType: class {
    var finished: Bool { get }
    
    func addDidStartClosure(didStartClosure: () -> Void)
    func addDeferredClosure(deferredClosure: () -> Void)
}

/// The failable task type protocol.
public protocol FailableTaskType: TaskType {
    var cancelled: Bool { get }
    func cancel()
}

/// The non-failable task type protocol.
public protocol NonFailableTaskType: TaskType {
}

// MARK: - Core task classes.

/// The "abstract" base class for all type of tasks. Not intended to be used directly.
public class BaseTask<V>: TaskType {
    
    /// The value associated to the successfully task completion.
    public private(set) var value: V!
    
    /// The error occurred while the task was executing, if any.
    public private(set) var error: ErrorType?
    
    /// If either `value` or `error` properties are not `nil`, this property will return `true`.
    public var finished: Bool {
        let v: Bool
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        v = self.value != nil || self.error != nil
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
        
        return v
    }
    
    //
    
    public var progress: NSProgress?
    
    //
    
    private let dispatchGroup: dispatch_group_t = dispatch_group_create()
    private var spinlock = OS_SPINLOCK_INIT
    
    private var didStartClosuresSpinlock = OS_SPINLOCK_INIT
    private var _didStartClosures: Array<() -> Void>?
    
    private var deferredClosuresSpinlock = OS_SPINLOCK_INIT
    private var _deferredClosures: Array<() -> Void>?
    
    //
    
    private init() {
        dispatch_group_enter(self.dispatchGroup)
    }
    
    deinit {
        assert(self.finished, "Either value or error were never assigned or task was never cancelled.")
    }
    
    //
    
    private final func waitForCompletion() {
        assert(!NSThread.isMainThread(), "Cannot wait task on main thread.")
        dispatch_group_wait(self.dispatchGroup, DISPATCH_TIME_FOREVER)
    }
    
    private final func setValue(value: V?, error: ErrorType?) {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        defer {
            withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
            
            //
            withUnsafeMutablePointer(&self.deferredClosuresSpinlock, OSSpinLockLock)
            if let deferredClosures = self._deferredClosures {
                deferredClosures.forEach { $0() }
                self._deferredClosures = nil
            }
            withUnsafeMutablePointer(&self.deferredClosuresSpinlock, OSSpinLockUnlock)
        }
        
        // the value or error can be assigned only once
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
        
        //
        dispatch_group_leave(self.dispatchGroup)
    }
    
    // MARK: -
    
    /// Finishes a task that has its generic type as `Void`. If the generic type of the task is not `Void` a fatal error will occurs.
    public final func finish() {
        if V.self is Void.Type {
            self.setValue((() as! V), error: nil)
        }
        else {
            fatalError("`Self.ValueType` is not `Void`.")
        }
    }
    
    /// Finished the task with an associated value.
    ///
    /// - parameter value: The associated value representing the final result of the task.
    public final func finishWithValue(value: V) {
        self.setValue(value, error: nil)
    }
    
    // MARK: -
    
    public func addDidStartClosure(didStartClosure: () -> Void) {
        withUnsafeMutablePointer(&self.didStartClosuresSpinlock, OSSpinLockLock)
        
        if self._didStartClosures == nil {
            self._didStartClosures = [didStartClosure]
        }
        else {
            self._didStartClosures!.append(didStartClosure)
        }
        
        withUnsafeMutablePointer(&self.didStartClosuresSpinlock, OSSpinLockUnlock)
    }

    
    public func addDeferredClosure(deferredClosure: () -> Void) {
        withUnsafeMutablePointer(&self.deferredClosuresSpinlock, OSSpinLockLock)
        
        if self._deferredClosures == nil {
            self._deferredClosures = [deferredClosure]
        }
        else {
            self._deferredClosures!.append(deferredClosure)
        }
        
        withUnsafeMutablePointer(&self.deferredClosuresSpinlock, OSSpinLockUnlock)
    }
}

/// An asynchronous failable task. A "failable" task in the context of this framework is a task that can returns or throws an error.
public final class Task<V>: BaseTask<V>, FailableTaskType {
    
    /// If the `error` property is not `nil` and the error code is `NSUserCancelledError`, this property will return `true`.
    public var cancelled: Bool {
        let v: Bool
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        if let error = self.error where error.userCancelled {
            v = true
        }
        else {
            v = false
        }
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
        
        return v
    }
    
    //
    
    public override var progress: NSProgress? {
        didSet {
            if let progress = self.progress {
                if let cancellationHandler = progress.cancellationHandler {
                    progress.cancellationHandler = { [unowned self] in
                        cancellationHandler()
                        self.cancel()
                    }
                }
                else {
                    progress.cancellationHandler = { [unowned self] in
                        self.cancel()
                    }
                }
            }
        }
    }
    
    //
    
    internal init(queue: NSOperationQueue, conditions: [TaskCondition]?, closure: (Task<V>) -> Void) {
        assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
        super.init()
        
        queue.addOperationWithBlock {
            do {
                //
                withUnsafeMutablePointer(&self.didStartClosuresSpinlock, OSSpinLockLock)
                if let didStartClosures = self._didStartClosures {
                    didStartClosures.forEach { $0() }
                    self._didStartClosures = nil
                }
                withUnsafeMutablePointer(&self.didStartClosuresSpinlock, OSSpinLockUnlock)
                
                //
                if let conditions = conditions where !conditions.isEmpty {
                    //
                    guard !self.cancelled else { return }
                    
                    //
                    let mutuallyExclusiveConditions = conditions.flatMap { $0 as? MutuallyExclusiveTaskCondition }
                    if !mutuallyExclusiveConditions.isEmpty {
                        mutuallyExclusiveConditions.forEach { mutuallyExclusiveCondition in
                            MutuallyExclusiveTaskCondition.increment(mutuallyExclusiveCondition.categoryName)
                        }
                        
                        self.addDeferredClosure {
                            mutuallyExclusiveConditions.forEach { mutuallyExclusiveCondition in
                                MutuallyExclusiveTaskCondition.decrement(mutuallyExclusiveCondition.categoryName)
                            }
                        }
                    }
                    
                    //
                    try await(TaskCondition.asyncEvaluateConditions(conditions))
                }
                
                //
                if !self.cancelled {
                    closure(self)
                }
            }
            catch TaskConditionError.NotSatisfied {
                self.cancel()
            }
            catch TaskConditionError.Failed(let innerError) {
                self.finishWithError(innerError)
            }
            catch let error {
                self.finishWithError(error)
            }
        }
    }
    
    //
    
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
    
    /// Finishes the task with an error.
    ///
    /// - parameter error: The error occurred while executing the task.
    public func finishWithError(error: ErrorType) {
        self.setValue(nil, error: error)
    }
    
    /// Finishes the task with a value or an error (not both and not none of them).
    ///
    /// - parameter value: The value representing the final value associated with the task. If this parameter is not nil, the `error` parameter must be nil.
    /// - parameter error: The error occurred while executing the task. If this parameter is not nil, the `value` parameter must be nil.
    public func finishWithValue(value: V?, error: ErrorType?) {
        self.setValue(value, error: error)
    }
    
    
    // MARK: -
    
    /// Cancels the execution of the current task. This is the same as finishing the task with an error with `NSUserCancelledError` code.
    ///
    /// - note: After a task is cancelled no action to stop it will be taken by the framework. You will have to check the `cancelled` property and stops any activity as soon as possible after it returns `true`.
    public func cancel() {
        self.setValue(nil, error: NSError.userCancelledError())
    }
    
    // MARK: -
    
    /// Waits for the execution of another task of the same generic type.
    ///
    /// - parameter task: The task to be executed and "awaited".
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

/// An asynchronous non-failable task. A "non-failable" task in the context of this framework is a task that cannot return or throw an error.
public final class NonFailableTask<V>: BaseTask<V>, NonFailableTaskType {
    
    //
    
    internal init(queue: NSOperationQueue, closure: (NonFailableTask<V>) -> Void) {
        assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
        super.init()
        
        queue.addOperationWithBlock {
            //
            withUnsafeMutablePointer(&self.didStartClosuresSpinlock, OSSpinLockLock)
            if let didStartClosures = self._didStartClosures {
                didStartClosures.forEach { $0() }
                self._didStartClosures = nil
            }
            withUnsafeMutablePointer(&self.didStartClosuresSpinlock, OSSpinLockUnlock)

            //
            closure(self)
        }
    }
    
    //
    
    @warn_unused_result
    internal func waitForCompletionAndReturnValue() -> V {
        self.waitForCompletion()
        return self.value
    }
    
    // MARK: -
    
    /// Waits for the execution of another task of the same generic type.
    ///
    /// - parameter task: The task to be executed and "awaited".
    public func continueWithTask(task: NonFailableTask<V>) {
        let value = task.waitForCompletionAndReturnValue()
        self.finishWithValue(value)
    }
    
}

// MARK: -

extension TaskType {

    public func didStart(closure: (Self) -> Void) -> Self {
        self.addDidStartClosure {
            closure(self)
        }
        
        return self
    }
    
    public func didFinish(callbackQueue: NSOperationQueue? = NSOperationQueue.mainQueue(), closure: (Self) -> Void) -> Self {
        self.addDeferredClosure {
            if let callbackQueue = callbackQueue {
                callbackQueue.addOperationWithBlock {
                    closure(self)
                }
            }
            else {
                closure(self)
            }
        }
        
        return self
    }

    
}

extension Task {

    public func didFinishWithValue(callbackQueue: NSOperationQueue? = NSOperationQueue.mainQueue(), closure: (V) -> Void) -> Self {
        self.addDeferredClosure {
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
            let value = self.value
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
            
            if let value = value {
                if let callbackQueue = callbackQueue {
                    callbackQueue.addOperationWithBlock {
                        closure(value)
                    }
                }
                else {
                    closure(value)
                }
            }
        }
        
        return self
    }

    public func didFinishWithError(callbackQueue: NSOperationQueue? = NSOperationQueue.mainQueue(), closure: (ErrorType) -> Void) -> Self {
        self.addDeferredClosure {
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
            let error = self.error
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)

            if let error = error where !error.userCancelled {
                if let callbackQueue = callbackQueue {
                    callbackQueue.addOperationWithBlock {
                        closure(error)
                    }
                }
                else {
                    closure(error)
                }
            }
        }
        
        return self
    }

    public func didCancel(callbackQueue: NSOperationQueue? = NSOperationQueue.mainQueue(), closure: () -> Void) -> Self {
        self.addDeferredClosure {
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
            let error = self.error
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
            
            if let error = error where error.userCancelled {
                if let callbackQueue = callbackQueue {
                    callbackQueue.addOperationWithBlock {
                        closure()
                    }
                }
                else {
                    closure()
                }
            }
        }
        
        return self
    }
    
}

extension NonFailableTask {
    
    public func didFinishWithValue(callbackQueue: NSOperationQueue? = NSOperationQueue.mainQueue(), closure: (V) -> Void) -> Self {
        self.addDeferredClosure {
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
            let value = self.value
            //withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)

            if let callbackQueue = callbackQueue {
                callbackQueue.addOperationWithBlock {
                    closure(value)
                }
            }
            else {
                closure(value)
            }
        }
        
        return self
    }
    
}
