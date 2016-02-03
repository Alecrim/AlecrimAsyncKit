//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public class BaseTask<V>: TaskOperation, TaskWithValueType {

    // MARK: -
    
    public typealias ValueType = V
    
    // MARK: -
    
    private final var valueSpinlock = OS_SPINLOCK_INIT
    
    private final func willAccessValue() {
        withUnsafeMutablePointer(&self.valueSpinlock, OSSpinLockLock)
    }
    
    private final func didAccessValue() {
        withUnsafeMutablePointer(&self.valueSpinlock, OSSpinLockUnlock)
    }

    
    // MARK: -
    
    public private(set) final var value: V!
    
    public func finishWith(value value: V) {
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
        assert(!NSThread.isMainThread(), "Cannot wait task on main thread.")
        super.waitUntilFinished()
    }
    
    // MARK: -
    private var _progress: NSProgress?
    public final var progress: NSProgress {
        if self._progress == nil {
            self._progress = TaskProgress(task: self)
        }
        
        return self._progress!
    }

    // MARK: -
    
    private final var closure: (() -> Void)?
    
    private override init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool) {
        super.init(conditions: conditions, observers: observers, asynchronous: asynchronous)
    }
    
    // MARK: -
    
    internal override final func execute() {
        super.execute()
        
        if !self.cancelled, let closure = self.closure {
            closure()
        }
        else {
            self.finishOperation()
        }
    }

}

public final class Task<V>: BaseTask<V>, InitializableTaskType, FailableTaskType {
    
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
            
            self.error = NSError.userCancelledError()
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
    
    public private(set) var error: ErrorType?
    
    public override func finishWith(value value: V) {
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
    
    public func finishWith(error error: ErrorType) {
        self.willAccessValue()
        defer {
            self.didAccessValue()
            self.finishOperation()
        }
        
        guard self.value == nil && self.error == nil else { return }
        
        self.error = error
    }
    
    // MARK: -
    
    internal init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (Task<V>) -> Void) {
        super.init(conditions: conditions, observers: observers, asynchronous: asynchronous)
        
        self.closure = { [unowned self] in
            closure(self)
        }
    }
    
}

public final class NonFailableTask<V>: BaseTask<V>, InitializableTaskType, NonFailableTaskType {

    internal init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (NonFailableTask<V>) -> Void) {
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

private final class TaskProgress: NSProgress {
    
    private unowned let task: TaskType
    
    private init(task: TaskType) {
        self.task = task
        super.init(parent: nil, userInfo: nil)
        
        self.totalUnitCount = 1
        self.cancellable = self.task is CancellableTaskType
    }
    
    //
    private override var cancellationHandler: (() -> Void)? {
        get {
            if let cancellableTask = self.task as? CancellableTaskType {
                return cancellableTask.cancellationHandler
            }
            else {
                return super.cancellationHandler
            }
        }
        set {
            if let cancellableTask = self.task as? CancellableTaskType {
                cancellableTask.cancellationHandler = newValue
            }
            else {
                super.cancellationHandler = newValue
            }
        }
    }
    
    private override func cancel() {
        super.cancel()
        
        if let cancellableTask = self.task as? CancellableTaskType {
            cancellableTask.cancel()
        }
    }
    
}

