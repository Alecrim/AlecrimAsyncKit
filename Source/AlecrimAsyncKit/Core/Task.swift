//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: - protocols

internal protocol BaseTaskDelegate: class {
    func task<V>(task: BaseTask<V>, didChangeToState state: TaskState)
}


// MARK: - classes

public class BaseTask<V>: BaseTaskType {
    
    // MARK: -
    
    public typealias ValueType = V
    
    // MARK: -
    
    private final var _state: TaskState = TaskState.Initialized
    internal final var state: TaskState {
        get {
            self.willAccessValue()
            defer { self.didAccessValue() }
            
            return self._state
        }
        set {
            self.setState(state: newValue, lock: true)
        }
    }
    
    private func setState(state newValue: TaskState, lock: Bool) {
        do {
            if lock {
                self.willAccessValue()
            }
            
            defer {
                if lock {
                    self.didAccessValue()
                }
            }

            guard newValue != self._state else { return }
            assert(self._state.canTransitionToState(newValue))
            
            self._state = newValue
            
            if self._state == .Finished {
                dispatch_group_leave(self.dispatchGroup)
            }
        }
        
        self.delegate?.task(self, didChangeToState: self._state)
    }
    
    // MARK: -
    
    public private(set) final var value: V!
    
    
    public final var finished: Bool { return self.state == .Finished }
    
    public var progress: NSProgress?
    
    // MARK: -
    
    private final let dispatchGroup: dispatch_group_t = dispatch_group_create()
    private final var spinlock = OS_SPINLOCK_INIT
    
    // MARK: -
    
    private final var closure: (() -> Void)!
    
    // MARK: -
    
    internal /* weak */ var delegate: BaseTaskDelegate?
    
    
    // MARK: -
    
    private init() {
        dispatch_group_enter(self.dispatchGroup)
    }
    
    deinit {
        print("TASK deinit")
        assert(self.finished, "Either value or error were never assigned or task was never cancelled.")
    }
    
    internal func execute() {
        self.closure()
    }
    
    internal func wait() throws {
        assert(!NSThread.isMainThread(), "Cannot wait task on main thread.")
        dispatch_group_wait(self.dispatchGroup, DISPATCH_TIME_FOREVER)
    }
    
    // MARK: -
    
    public func finishWithValue(value: V) {
        self.willAccessValue()
        defer { self.didAccessValue() }
        
        guard self.value == nil else { return }
        
        self.setState(state: .Finishing, lock: false)
        self.value = value
        self.setState(state: .Finished, lock: false)
    }
    
    // MARK: -
    
    private final func willAccessValue() {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
    }
    
    private final func didAccessValue() {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
    }
    
}

public final class NonFailableTask<V>: BaseTask<V>, NonFailableTaskType {
    
    // MARK: -
    
    public init(closure: (NonFailableTask<V>) -> Void) {
        super.init()
        
        self.closure = { [unowned self] in
            closure(self)
        }
    }
    
}

public final class Task<V>: BaseTask<V>, FailableTaskType {
    
    // MARK: -
    
    public private(set) var error: ErrorType?
    public var cancelled: Bool {
        self.willAccessValue()
        defer { self.didAccessValue() }
        
        return self.error?.userCancelled ?? false
    }
    
    // MARK: -
    
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
    
    // MARK: -
    
    public init(closure: (Task<V>) -> Void) {
        super.init()
        
        self.closure = { [unowned self] in
            closure(self)
        }
    }
    
    // MARK: -
    
    internal override func wait() throws {
        try super.wait()
        
        if let error = self.error {
            throw error
        }
    }
    
    // MARK: -
    
    public func cancel() {
        self.finishWithError(NSError.userCancelledError())
    }
    
    public override func finishWithValue(value: V) {
        self.finishWithValue(value, error: nil)
    }
    
    public func finishWithError(error: ErrorType) {
        self.finishWithValue(nil, error: error)
    }
    
    public func finishWithValue(value: V!, error: ErrorType?) {
        self.willAccessValue()
        defer { self.didAccessValue() }
        
        guard self.value == nil && self.error == nil else { return }
        assert(value != nil || error != nil, "Invalid combination of value/error.")
        
        self.setState(state: .Finishing, lock: false)
        
        if let error = error {
            self.value = nil
            self.error = error
        }
        else {
            self.value = value
            self.error = nil
        }
        
        self.setState(state: .Finished, lock: false)
    }
    
}
