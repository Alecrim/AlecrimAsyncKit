//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private let taskOperationQueue: NSOperationQueue = {
    let oq = NSOperationQueue()
    oq.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    oq.qualityOfService = .Utility
    
    return oq
    }()

public class Task<V> {
    
    // MARK: -
    
    public private(set) var value: V!
    public private(set) var error: ErrorType?
    
    private let dispatchGroup: dispatch_group_t = dispatch_group_create()
    private var waiting = true
    private var spinlock = OS_SPINLOCK_INIT
    
    private let conditions: [TaskCondition]?
    private let observers: [TaskObserver<V>]?
    private var blockOperation: NSBlockOperation!
    
    // MARK: -
    
    internal init(conditions: [TaskCondition]?, observers: [TaskObserver<V>]?, closure: (Task<V>) -> Void) {
        //
        self.conditions = conditions
        self.observers = observers
        
        //
        dispatch_group_enter(self.dispatchGroup)

        //
        self.blockOperation = NSBlockOperation { [unowned self] in
            closure(self)
        }
        
        self.blockOperation.queuePriority = .Normal
        
        //
        if let observers = self.observers where !observers.isEmpty {
            for observer in observers {
                observer.taskDidStart(self)
            }
        }
        
        //
        do {
            if let conditions = self.conditions where !conditions.isEmpty {
                try await(TaskCondition.asyncEvaluateConditions(conditions))
            }
            
            self.start()
        }
        catch let error {
            self.finishWithError(error)
        }
    }
    
    deinit {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        assert(!self.waiting, "Either value or error were never assigned or task was never cancelled.")
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
    }
    
    // MARK: -

    private func start() {
        if !self.blockOperation.cancelled {
            taskOperationQueue.addOperation(self.blockOperation)
        }
    }
    
    internal func wait() {
        assert(!NSThread.isMainThread(), "Cannot wait task on main thread.")
        dispatch_group_wait(self.dispatchGroup, DISPATCH_TIME_FOREVER)
    }
    
    private func setValue(value: V?, error: ErrorType?) {
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
        dispatch_group_leave(self.dispatchGroup)
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
        
        if let observers = self.observers where !observers.isEmpty {
            for observer in observers {
                observer.task(self, didFinishWithValue: self.value, error: self.error)
            }
        }
    }

    // MARK: -
    
    public func finish() {
        if V.self is Void.Type {
            self.setValue((() as! V), error: nil)
        }
        else {
            fatalError("`Self.ValueType` is not `Void`.")
        }
    }
    
    public func finishWithValue(value: V) {
        self.setValue(value, error: nil)
    }
    
    public func finishWithError(error: ErrorType) {
        self.setValue(nil, error: error)
    }
    
    public func finishWithValue(value: V?, error: ErrorType?) {
        self.setValue(value, error: error)
    }
    
    // MARK: -
    
    public var cancelled: Bool { return self.blockOperation.cancelled }
    
    public func cancel() {
        self.blockOperation.cancel()
        self.setValue(nil, error: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
    }
    
    // MARK: -
    
    public final func continueWithTask(task: Task<V>) {
        do {
            let value = try await(task)
            self.finishWithValue(value)
        }
        catch let error {
            self.finishWithError(error)
        }
    }
    
}

public class NonFailableTask<V>: Task<V> {

    internal init(observers: [TaskObserver<V>]?, closure: (NonFailableTask<V>) -> Void) {
        super.init(conditions: nil, observers: observers, closure: closure as! (Task<V> -> Void))
    }

    public override func finishWithError(error: ErrorType) {
        fatalError("A non failable task cannot be finished with an error.")
    }
    
    public override func finishWithValue(value: V?, error: ErrorType?) {
        if error != nil {
            fatalError("A non failable task cannot be finished with an error.")
        }
    }
    
    public override func cancel() {
        fatalError("A non failable task cannot be cancelled.")
    }
    
}

