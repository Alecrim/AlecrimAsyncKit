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


private enum TaskOperationState {
    case Initialized
    case Pending
    case EvaluatingConditions
    case Ready
    case Executing
    case Finishing
    case Finished
    
    private func canTransitionToState(target: TaskOperationState) -> Bool {
        switch (self, target) {
        case (.Initialized, .Pending):
            return true
            
        case (.Pending, .EvaluatingConditions):
            return true

        case (.Pending, .Ready):
            return true

        case (.EvaluatingConditions, .Ready):
            return true
            
        case (.Ready, .Executing):
            return true
            
        case (.Ready, .Finishing):
            return true
            
        case (.Executing, .Finishing):
            return true
            
        case (.Finishing, .Finished):
            return true
            
        default:
            return false
        }
    }
}


internal final class TaskOperation<T: TaskType, V where T.ValueType == V>: NSOperation {

    // MARK: -
    
    @objc private class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state"]
    }
    
    @objc private class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state"]
    }
    
    @objc private class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state"]
    }
    
    // MARK: -
    
    private var stateSpinlock = OS_SPINLOCK_INIT
    
    private func willAccessState() {
        withUnsafeMutablePointer(&self.stateSpinlock, OSSpinLockLock)
    }
    
    private func didAccessState() {
        withUnsafeMutablePointer(&self.stateSpinlock, OSSpinLockUnlock)
    }
    
    private func willChangeState() {
        self.willChangeValueForKey("state")
        self.willAccessState()
    }
    
    private func didChangeState() {
        self.didAccessState()
        self.didChangeValueForKey("state")
    }
    
    // MARK: -
    
    private var _state: TaskOperationState = .Initialized
    private var state: TaskOperationState {
        get {
            self.willAccessState()
            defer { self.didAccessState() }
            
            return self._state
        }
        set {
            self.willChangeState()
            defer { self.didChangeState() }
            
            guard self._state != .Finished else { return }
            
            assert(self._state.canTransitionToState(newValue))
            self._state = newValue
        }
    }
    
    // MARK: -
    
    let u = NSUUID().UUIDString
    
    internal override var ready: Bool {
        switch self.state {
        case .Initialized:
            return self.cancelled
            
        case .Pending:
            guard !self.cancelled else {
                return true
            }
            
            if super.ready {
                self.evaluateConditions()
            }
            
            return false
            
        case .Ready:
            return super.ready || self.cancelled
            
        default:
            return false
        }
    }


    internal override var executing: Bool {
        return self.state == .Executing
    }
    
    internal override var finished: Bool {
        return self.state == .Finished
    }

    // MARK: -
    
    internal let task: T
    private let conditions: [TaskCondition]?
    private let observers: [TaskObserver]?
    
    private var baseTask: BaseTask<V> { return self.task as! BaseTask<V> }
    
    internal init(task: T, conditions: [TaskCondition]?, observers: [TaskObserver]?) {
        self.task = task
        self.conditions = conditions
        self.observers = observers
        
        super.init()
    }
    
    // MARK: -
    
    override final func main() {
        assert(self.state == .Ready)
        
        if !self.cancelled {
            self.execute()
        }
        else {
            self.finish()
        }
    }

    
    internal override func start() {
        super.start()

        if self.cancelled {
            self.finish()
        }
    }
    
    // MARK: -
    
    internal func willEnqueue() {
        self.state = .Pending
    }
    
    private func evaluateConditions() {
        assert(self.state == .Pending && !self.cancelled)
        
        guard let failableTask = self.task as? Task<V> where !failableTask.cancelled, let conditions = self.conditions else {
            self.state = .Ready
            return
        }
        
        //
        self.state = .EvaluatingConditions
        
        //
        let incrementMutuallyExclusiveConditionsOperation = NSBlockOperation { [unowned self] in
            self.incrementMutuallyExclusiveConditions()
        }
        
        //
        let evaluateConditionsOperation = NSBlockOperation { [unowned self] in
            do {
                try await(TaskCondition.asyncEvaluateConditions(conditions))
            }
            catch TaskConditionError.NotSatisfied {
                failableTask.cancel()
                self.cancel()
            }
            catch TaskConditionError.Failed(let innerError) {
                failableTask.finishWithError(innerError)
                self.cancel()
            }
            catch let error {
                failableTask.finishWithError(error)
                self.cancel()
            }
        }
        
        evaluateConditionsOperation.completionBlock = { [unowned self] in
            self.state = .Ready
        }
        
        //
        let decrementMutuallyExclusiveConditionsOperation = NSBlockOperation { [unowned self] in
            self.decrementMutuallyExclusiveConditions()
        }
        
        //
        evaluateConditionsOperation.addDependency(incrementMutuallyExclusiveConditionsOperation)
        self.addDependency(evaluateConditionsOperation)
        decrementMutuallyExclusiveConditionsOperation.addDependency(self)
        
        //
        _conditionEvaluationQueue.addOperation(incrementMutuallyExclusiveConditionsOperation)
        _conditionEvaluationQueue.addOperation(evaluateConditionsOperation)
        _conditionEvaluationQueue.addOperation(decrementMutuallyExclusiveConditionsOperation)
    }
    
    private func execute() {
        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskWillStartClosure?(self.task) }
        }

        self.state = .Executing
        
        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskDidStartClosure?(self.task) }
        }

        self.baseTask.execute()
        
        defer {
            self.finish()
        }
        
        do {
            try self.baseTask.wait()
        }
        catch {
            self.cancel()
        }
    }
    
    private func finish() {
        guard self.state != .Finished else { return }
        
        self.state = .Finishing
        
        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskWillFinishClosure?(self.task) }
        }
        
        self.state = .Finished

        if let observers = self.observers where !observers.isEmpty {
            observers.forEach { $0.taskDidFinishClosure?(self.task) }
        }
    }
    
    override func cancel() {
        print(u, "CANCELLED")
        super.cancel()
    }
    
    // MARK: -
    
    private func incrementMutuallyExclusiveConditions() {
        if let mutuallyExclusiveConditions = self.conditions?.flatMap({ $0 as? MutuallyExclusiveTaskCondition }) where !mutuallyExclusiveConditions.isEmpty {
            mutuallyExclusiveConditions.forEach {
                MutuallyExclusiveTaskCondition.increment($0.categoryName)
                print(u, "INCREMENT", $0.categoryName)
            }
        }
    }
    
    private func decrementMutuallyExclusiveConditions() {
        if let mutuallyExclusiveConditions = self.conditions?.flatMap({ $0 as? MutuallyExclusiveTaskCondition }) where !mutuallyExclusiveConditions.isEmpty {
            mutuallyExclusiveConditions.forEach {
                MutuallyExclusiveTaskCondition.decrement($0.categoryName)
                print(u, "DECREMENT", $0.categoryName)
            }
        }
    }

}
