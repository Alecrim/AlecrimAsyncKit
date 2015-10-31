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
    
    public func finishWithValue(value: V) {
        self.willAccessValue()
        defer {
            self.didAccessValue()
            self.finishOperation()
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
    
    private final var closure: (() -> Void)?
    
    private override init(conditions: [TaskCondition]?, observers: [TaskObserver]?) {
        super.init(conditions: conditions, observers: observers)
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
        if let cancellationHandler = self.cancellationHandler {
            self.cancellationHandler = nil
            cancellationHandler()
        }
        
        self.willAccessValue()
        defer {
            self.didAccessValue()
            super.cancel()
            self.finishOperation()
        }
        
        guard self.value == nil && self.error == nil else { return }
        
        self.error = NSError.userCancelledError()
    }
    
    // MARK: -
    
    public private(set) var error: ErrorType?
    
    public override func finishWithValue(value: V) {
        self.willAccessValue()
        defer {
            self.didAccessValue()
            self.finishOperation()
        }
        
        guard self.value == nil && self.error == nil else { return }
        
        self.value = value
    }
    
    public func finishWithError(error: ErrorType) {
        self.willAccessValue()
        defer {
            self.didAccessValue()
            self.finishOperation()
        }
        
        guard self.value == nil && self.error == nil else { return }
        
        self.error = error
    }
    
    // MARK: -
    
    public required init(conditions: [TaskCondition]?, observers: [TaskObserver]?, closure: (Task<V>) -> Void) {
        super.init(conditions: conditions, observers: observers)
        
        self.closure = { [unowned self] in
            closure(self)
        }
    }
    
}

public final class NonFailableTask<V>: BaseTask<V>, InitializableTaskType, NonFailableTaskType {

    public required init(conditions: [TaskCondition]?, observers: [TaskObserver]?, closure: (NonFailableTask<V>) -> Void) {
        super.init(conditions: conditions, observers: observers)
        
        self.closure = { [unowned self] in
            closure(self)
        }
    }

}
