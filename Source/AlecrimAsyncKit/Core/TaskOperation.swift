//
//  TaskOperation.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-29.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

private let _conditionEvaluationQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.ConditionEvaluation"
    queue.qualityOfService = .Default
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

public class TaskOperation: NSOperation, TaskType {
    
    private enum StateKey: String {
        case Executing = "isExecuting"
        case Finished = "isFinished"
        case Ready = "isReady"
    }

    // MARK: -
    
    private var stateSpinlock = OS_SPINLOCK_INIT
    
    private func willAccessState() {
        withUnsafeMutablePointer(&self.stateSpinlock, OSSpinLockLock)
    }
    
    private func didAccessState() {
        withUnsafeMutablePointer(&self.stateSpinlock, OSSpinLockUnlock)
    }
    
    private func willChangeValueForStateKey(stateKey: StateKey) {
        self.willChangeValueForKey(stateKey.rawValue)
        self.willAccessState()
    }
    
    private func didChangeValueForStateKey(stateKey: StateKey) {
        self.didAccessState()
        self.didChangeValueForKey(stateKey.rawValue)
    }
    
    //
    
    private lazy var mutuallyExclusiveConditions: [MutuallyExclusiveTaskCondition]? = {
        if let mecs = self.conditions?.flatMap({ $0 as? MutuallyExclusiveTaskCondition }) where !mecs.isEmpty {
            return mecs
        }
        
        return nil
    }()
    
    //

    public override var concurrent: Bool { return self.__asynchronous }
    public override var asynchronous: Bool { return self.__asynchronous }
    
    //
    
    private var __executing: Bool = false
    public private(set) override var executing: Bool {
        get {
            self.willAccessState()
            defer { self.didAccessState() }
            
            return self.__executing
        }
        set {
            let oldValue: Bool
            
            do {
                self.willChangeValueForStateKey(.Executing)
                defer { self.didChangeValueForStateKey(.Executing) }
                
                oldValue = self.__executing
                self.__executing = newValue
            }
            
            if newValue != oldValue && newValue == false {
                self.signalMutuallyExclusiveConditionsIfNeeded()
            }
        }
    }

    private var __finished: Bool = false
    public private(set) override var finished: Bool {
        get {
            self.willAccessState()
            defer { self.didAccessState() }
            
            return self.__finished
        }
        set {
            self.willChangeValueForStateKey(.Finished)
            defer { self.didChangeValueForStateKey(.Finished) }
            
            self.__finished = newValue
        }
    }

    private var __ready: Bool = false
    public private(set) override var ready: Bool {
        get {
            self.willAccessState()
            defer { self.didAccessState() }
            
            return self.__ready
        }
        set {
            self.willChangeValueForStateKey(.Ready)
            defer { self.didChangeValueForStateKey(.Ready) }
            
            self.__ready = newValue
        }
    }
    
    // MARK: -
    
    public override func cancel() {
        super.cancel()
        
        self.executing = false
        self.ready = true
    }
    
    // MARK: -
    
    internal final func willEnqueue() {
        self.evaluateConditions()
    }
    
    internal final func evaluateConditions() {
        guard !self.cancelled, let conditions = self.conditions where !conditions.isEmpty else {
            self.ready = true
            return
        }

        //
        let evaluateConditionsOperation = NSBlockOperation {
            do {
                defer {
                    self.ready = true
                }
                
                if !self.cancelled {
                    try await(TaskCondition.asyncEvaluateConditions(conditions))
                }
            }
            catch TaskConditionError.NotSatisfied {
                self.cancel()
            }
            catch TaskConditionError.Failed(let innerError) {
                if let task = self as? TaskWithErrorType {
                    task.finishWith(error: innerError)
                }
                else {
                    self.cancel()
                }
            }
            catch let error {
                if let task = self as? TaskWithErrorType {
                    task.finishWith(error: error)
                }
                else {
                    self.cancel()
                }
            }
        }
        
        //
        _conditionEvaluationQueue.addOperation(evaluateConditionsOperation)
    }
    
    // to be overrided calling super
    internal func execute() {
        //
        self.ready = false
        self.executing = true
        
        //
        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskDidStartClosure?(self) }
        }
    }
    
    private var hasFinishedAlready = false
    internal final func finishOperation() {
        guard self.hasStarted else {
            self.cancel()
            return
        }

        guard !self.hasFinishedAlready else { return }
        self.hasFinishedAlready = true
        
        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskWillFinishClosure?(self) }
        }
        
        self.ready = false
        self.executing = false
        self.finished = true
        
        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskDidFinishClosure?(self) }
        }
    }
    
    internal final func signalMutuallyExclusiveConditionsIfNeeded() {
        if let mutuallyExclusiveConditions = self.mutuallyExclusiveConditions  {
            mutuallyExclusiveConditions.forEach {
                MutuallyExclusiveTaskCondition.signal($0.categoryName)
            }
        }
    }
    
    // MARK: -
    
    private let conditions: [TaskCondition]?
    private let observers: [TaskObserver]?
    private let __asynchronous: Bool

    internal init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool) {
        self.conditions = conditions
        self.observers = observers
        self.__asynchronous = asynchronous
        
        super.init()
    }
    
    // MARK : -
    
    internal private(set) var hasStarted = false
    public override final func start() {
        self.hasStarted = true
        
        super.start()
        
        if self.cancelled {
            self.finishOperation()
        }
    }
    
    public override func main() {
        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskWillStartClosure?(self) }
        }

        if self.cancelled {
            self.finishOperation()
        }
        else {
            self.execute()
        }
    }
    
}
