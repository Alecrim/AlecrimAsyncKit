//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: - classes

public class BaseTask<V>: BaseTaskType {
    
    // MARK: -
    
    public typealias ValueType = V
    
    // MARK: -
    
    public private(set) final var value: V!
    
    
    public private(set) final var finished: Bool = false {
        didSet {
            guard self.finished != oldValue && self.finished == true else { return }
            dispatch_group_leave(self.dispatchGroup)
        }
    }

    // MARK: -

    internal private(set) final var progressAssigned = false
    
    public lazy final var progress: NSProgress = {
        let p = NSProgress()
        p.totalUnitCount = 1
        p.completedUnitCount = 0
        
        self.progressAssigned = true
        
        return p
    }()

    public var cancellationHandler: (() -> Void)? {
        get { return self.progress.cancellationHandler }
        set {
            if let oldValue = self.cancellationHandler {
                if let newValue = newValue {
                    self.progress.cancellationHandler = {
                        oldValue()
                        newValue()
                    }
                }
                else {
                    self.progress.cancellationHandler = oldValue
                }
            }
            else {
                self.progress.cancellationHandler = newValue
            }
        }
    }

    // MARK: -
    
    private final let dispatchGroup: dispatch_group_t = dispatch_group_create()
    private final var spinlock = OS_SPINLOCK_INIT
    
    // MARK: -
    
    private final var closure: (() -> Void)!
    
    // MARK: -
    
    private init() {
        dispatch_group_enter(self.dispatchGroup)
    }
    
    deinit {
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
        
        self.value = value
        self.finished = true
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
        defer {
            if self.progressAssigned {
                if self.value != nil {
                    self.progress.completedUnitCount = self.progress.totalUnitCount
                }
                else if let error = self.error as? NSError where error.userCancelled, let cancellationHandler = self.cancellationHandler {
                    cancellationHandler()
                }
            }
        }
        
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
        
        self.finished = true
    }
    
}
