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
    
    public final func finishWithValue(value: V) {
        guard !self.finished else { return }
        
        self.willAccessValue()
        defer { self.didAccessValue() }
        
        if self.value == nil {
            self.value = value
            self.internalFinish()
        }
    }
    
    private override init(conditions: [TaskCondition]?, observers: [TaskObserver]?) {
        super.init(conditions: conditions, observers: observers)
    }

}

public final class Task<V>: BaseTask<V>, InitializableTaskType, FailableTaskType {

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

    
    public private(set) var error: ErrorType?
    
    public func finishWithError(error: ErrorType) {
        guard !self.finished else { return }
        
        self.willAccessValue()
        defer { self.didAccessValue() }

        assert(self.value == nil)
        
        if self.error == nil {
            self.error = error
            self.internalFinish()
        }
    }
    
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
