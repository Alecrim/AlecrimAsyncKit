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
    queue.qualityOfService = .Utility
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

public class TaskOperation: NSOperation, TaskType {
    
    private enum StateKey: String {
        case executing = "isExecuting"
        case finished = "isFinished"
        case ready = "isReady"
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
                self.willChangeValueForStateKey(.executing)
                defer { self.didChangeValueForStateKey(.executing) }
                
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
            self.willChangeValueForStateKey(.finished)
            defer { self.didChangeValueForStateKey(.finished) }
            
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
            self.willChangeValueForStateKey(.ready)
            defer { self.didChangeValueForStateKey(.ready) }
            
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
            catch TaskConditionError.notSatisfied {
                self.cancel()
            }
            catch TaskConditionError.failed(let innerError) {
                if let task = self as? TaskWithErrorType {
                    task.finish(with: innerError)
                }
                else {
                    self.cancel()
                }
            }
            catch let error {
                if let task = self as? TaskWithErrorType {
                    task.finish(with: error)
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
        self.observers?.flatMap({ $0 as? TaskDidStartObserverType }).forEach({ $0.didStart(self) })
    }
    
    private var hasFinishedAlready = false
    internal final func finishOperation() {
        guard self.hasStarted else {
            self.cancel()
            return
        }

        guard !self.hasFinishedAlready else { return }
        self.hasFinishedAlready = true
        
        //
        self.observers?.flatMap({ $0 as? TaskWillFinishObserverType }).forEach({ $0.willFinish(self) })
        
        //
        self.ready = false
        self.executing = false
        self.finished = true
        
        //
        self.observers?.flatMap({ $0 as? TaskDidFinishObserverType }).forEach({ $0.didFinish(self) })
    }
    
    internal final func signalMutuallyExclusiveConditionsIfNeeded() {
        self.mutuallyExclusiveConditions?.forEach({ MutuallyExclusiveTaskCondition.signal(condition: $0, categoryName: $0.categoryName) })
    }
    
    // MARK: -
    
    private let conditions: [TaskCondition]?
    private let observers: [TaskObserverType]?
    private let __asynchronous: Bool

    internal init(conditions: [TaskCondition]?, observers: [TaskObserverType]?, asynchronous: Bool) {
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
        //
        self.observers?.flatMap({ $0 as? TaskWillStartObserverType }).forEach({ $0.willStart(self) })

        //
        if self.cancelled {
            self.finishOperation()
        }
        else {
            self.execute()
        }
    }
    
}
