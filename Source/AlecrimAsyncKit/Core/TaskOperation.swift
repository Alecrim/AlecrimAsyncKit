//
//  TaskOperation.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-29.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public class TaskOperation: Operation, TaskProtocol {
    
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
        self.willChangeValue(forKey: stateKey.rawValue)
        self.willAccessState()
    }
    
    private func didChangeValueForStateKey(stateKey: StateKey) {
        self.didAccessState()
        self.didChangeValue(forKey: stateKey.rawValue)
    }
    
    //
    
    private lazy var mutuallyExclusiveConditions: [MutuallyExclusiveCondition]? = {
        if let mecs = self.conditions?.flatMap({ $0 as? MutuallyExclusiveCondition }), !mecs.isEmpty {
            return mecs
        }
        
        return nil
    }()
    
    //

    public override var isConcurrent: Bool { return self.__asynchronous }
    public override var isAsynchronous: Bool { return self.__asynchronous }
    
    //
    
    private var __executing: Bool = false
    public private(set) override var isExecuting: Bool {
        get {
            self.willAccessState()
            defer { self.didAccessState() }
            
            return self.__executing
        }
        set {
            let oldValue: Bool
            
            do {
                self.willChangeValueForStateKey(stateKey: .executing)
                defer { self.didChangeValueForStateKey(stateKey: .executing) }
                
                oldValue = self.__executing
                self.__executing = newValue
            }
            
            if newValue != oldValue && newValue == false {
                self.signalMutuallyExclusiveConditionsIfNeeded()
            }
        }
    }

    private var __finished: Bool = false
    public private(set) override var isFinished: Bool {
        get {
            self.willAccessState()
            defer { self.didAccessState() }
            
            return self.__finished
        }
        set {
            self.willChangeValueForStateKey(stateKey: .finished)
            defer { self.didChangeValueForStateKey(stateKey: .finished) }
            
            self.__finished = newValue
        }
    }

    private var __ready: Bool = false
    public private(set) override var isReady: Bool {
        get {
            self.willAccessState()
            defer { self.didAccessState() }
            
            return self.__ready
        }
        set {
            self.willChangeValueForStateKey(stateKey: .ready)
            defer { self.didChangeValueForStateKey(stateKey: .ready) }
            
            self.__ready = newValue
        }
    }
    
    // MARK: -
    
    public override func cancel() {
        super.cancel()
        
        self.isExecuting = false
        self.isReady = true
    }
    
    // MARK: -
    
    internal final func willEnqueue() {
        self.evaluateConditions()
    }
    
    internal final func evaluateConditions() {
        guard !self.isCancelled, let conditions = self.conditions, !conditions.isEmpty else {
            self.isReady = true
            return
        }

        //
        let evaluateConditionsOperation = BlockOperation {
            do {
                defer {
                    self.isReady = true
                }
                
                if !self.isCancelled {
                    try await(TaskCondition.evaluateConditions(conditions))
                }
            }
            catch TaskConditionError.notSatisfied {
                self.cancel()
            }
            catch TaskConditionError.failed(let innerError) {
                if let task = self as? ErrorReportingTask {
                    task.finish(with: innerError)
                }
                else {
                    self.cancel()
                }
            }
            catch let error {
                if let task = self as? ErrorReportingTask {
                    task.finish(with: error)
                }
                else {
                    self.cancel()
                }
            }
        }
        
        //
        Queue.taskConditionEvaluationOperationQueue.addOperation(evaluateConditionsOperation)
    }
    
    // to be overrided calling super
    internal func execute() {
        //
        self.isReady = false
        self.isExecuting = true
        
        //
        self.observers?.flatMap({ $0 as? TaskDidStartObserver }).forEach({ $0.didStartTask(self) })
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
        self.observers?.flatMap({ $0 as? TaskWillFinishObserver }).forEach({ $0.willFinishTask(self) })
        
        //
        self.isReady = false
        self.isExecuting = false
        self.isFinished = true
        
        //
        self.observers?.flatMap({ $0 as? TaskDidFinishObserver }).forEach({ $0.didFinishTask(self) })
    }
    
    internal final func signalMutuallyExclusiveConditionsIfNeeded() {
        self.mutuallyExclusiveConditions?.forEach({ MutuallyExclusiveCondition.signal(condition: $0, categoryName: $0.categoryName) })
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
        
        if self.isCancelled {
            self.finishOperation()
        }
    }
    
    public override func main() {
        //
        self.observers?.flatMap({ $0 as? TaskWillStartObserver }).forEach({ $0.willStartTask(self) })

        //
        if self.isCancelled {
            self.finishOperation()
        }
        else {
            self.execute()
        }
    }
    
}
