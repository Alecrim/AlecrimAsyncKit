//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public class AbstractTask<V>: TaskOperation, ValueReportingTask {

    // MARK: -
    
    public typealias ValueType = V
    
    // MARK: -
    
    private final var valueSpinlock = OS_SPINLOCK_INIT
    
    fileprivate final func willAccessValue() {
        withUnsafeMutablePointer(to: &self.valueSpinlock, OSSpinLockLock)
    }
    
    fileprivate final func didAccessValue() {
        withUnsafeMutablePointer(to: &self.valueSpinlock, OSSpinLockUnlock)
    }

    
    // MARK: -
    
    public fileprivate(set) final var value: V!
    
    public func finish(with value: V) {
        self.willAccessValue()
        defer {
            self.didAccessValue()
            
            self.finishOperation()
            
            if let progress = self._progress {
                progress.completedUnitCount = progress.totalUnitCount
            }
        }
        
        guard self.value == nil else { return }
        
        self.value = value
    }

    // MARK: -
    
    public override final func waitUntilFinished() {
        precondition(!Thread.isMainThread, "Cannot wait task on main thread.")
        super.waitUntilFinished()
    }
    
    // MARK: -
    fileprivate var _progress: Progress?
    public final var progress: Progress {
        if self._progress == nil {
            self._progress = TaskProgress(task: self)
        }
        
        return self._progress!
    }

    // MARK: -
    
    fileprivate final var closure: (() -> Void)?
    
    fileprivate override init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool) {
        super.init(conditions: conditions, observers: observers, asynchronous: asynchronous)
    }
    
    // MARK: -
    
    internal override final func execute() {
        super.execute()
        
        if !self.isCancelled, let closure = self.closure {
            closure()
        }
        else {
            self.finishOperation()
        }
    }

}

public final class Task<V>: AbstractTask<V>, InitializableTask, FailableTaskProtocol {
    
    // MARK: -

    private var _cancellationHandler: (() -> Void)?
    public var cancellationHandler: (() -> Void)? {
        get {
            return self._cancellationHandler
        }
        set {
            if let oldValue = self._cancellationHandler {
                if let newValue = newValue {
                    self._cancellationHandler = {
                        oldValue()
                        newValue()
                    }
                }
                else {
                    self._cancellationHandler = newValue
                }
            }
            else {
                self._cancellationHandler = newValue
            }
        }
    }
    
    public override func cancel() {
        //
        if let cancellationHandler = self.cancellationHandler {
            self.cancellationHandler = nil
            cancellationHandler()
        }

        //
        do {
            self.willAccessValue()
            defer {
                self.didAccessValue()
            }
            
            guard self.value == nil && self.error == nil else { return }
            
            self.error = NSError.userCancelledError(domain: AlecrimAsyncKitErrorDomain)
        }
        
        //
        let hasStarted = self.hasStarted
        super.cancel()
        
        if hasStarted {
            self.finishOperation()
        }
        else {
            self.signalMutuallyExclusiveConditionsIfNeeded()
        }
    }
    
    // MARK: -
    
    public private(set) var error: Error?
    
    public override func finish(with value: V) {
        self.willAccessValue()
        defer {
            self.didAccessValue()
            
            self.finishOperation()
            
            if let progress = self._progress {
                progress.completedUnitCount = progress.totalUnitCount
            }
        }
        
        guard self.value == nil && self.error == nil else { return }
        
        self.value = value
    }
    
    public func finish(with error: Error) {
        self.willAccessValue()
        defer {
            self.didAccessValue()
            self.finishOperation()
        }
        
        guard self.value == nil && self.error == nil else { return }
        
        self.error = error
    }
    
    // MARK: -
    
    internal init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: @escaping (Task<V>) -> Void) {
        super.init(conditions: conditions, observers: observers, asynchronous: asynchronous)
        
        self.closure = { [unowned self] in
            closure(self)
        }
    }

}

public final class NonFailableTask<V>: AbstractTask<V>, InitializableTask, NonFailableTaskProtocol {

    internal init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: @escaping (NonFailableTask<V>) -> Void) {
        super.init(conditions: conditions, observers: observers, asynchronous: asynchronous)
        
        self.closure = { [unowned self] in
            closure(self)
        }
    }
    
    @available(*, unavailable)
    public override func cancel() {
        super.cancel()
    }

}


// MARK: -

private final class TaskProgress: Progress {
    
    private unowned let task: TaskProtocol
    
    fileprivate init(task: TaskProtocol) {
        self.task = task
        super.init(parent: nil, userInfo: nil)
        
        self.totalUnitCount = 1
        self.isCancellable = self.task is CancellableTask
    }
    
    //
    fileprivate override var cancellationHandler: (() -> Void)? {
        get {
            if let cancellableTask = self.task as? CancellableTask {
                return cancellableTask.cancellationHandler
            }
            else {
                return super.cancellationHandler
            }
        }
        set {
            if let cancellableTask = self.task as? CancellableTask {
                cancellableTask.cancellationHandler = newValue
            }
            else {
                super.cancellationHandler = newValue
            }
        }
    }
    
    fileprivate override func cancel() {
        super.cancel()
        
        if let cancellableTask = self.task as? CancellableTask {
            cancellableTask.cancel()
        }
    }
    
}

