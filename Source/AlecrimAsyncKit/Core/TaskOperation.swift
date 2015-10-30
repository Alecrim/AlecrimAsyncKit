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


public class TaskOperation: NSOperation {

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
    
    public override final var ready: Bool {
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


    public override final var executing: Bool {
        return self.state == .Executing
    }
    
    public override final var finished: Bool {
        return self.state == .Finished
    }

    // MARK: -
    
    private let conditions: [TaskCondition]?
    private let observers: [TaskObserver]?
    
    internal final var closure: (() -> Void)!

    internal init(conditions: [TaskCondition]?, observers: [TaskObserver]?) {
        self.conditions = conditions
        self.observers = observers
        
        super.init()
    }
    
    // MARK: -

    public override final func start() {
        super.start()
        
        if self.cancelled {
            self.internalFinish()
        }
    }

    public override final func main() {
        assert(self.state == .Ready)
        
        if let observers = self.observers where !observers.isEmpty, let task = self as? TaskType {
            observers.forEach { $0.taskWillStartClosure?(task) }
        }
        
        if !self.cancelled {
            self.execute()
        }
        else {
            self.internalFinish()
        }
    }
    
    public override final func cancel() {
        guard !self.cancelled else { return }
        
        super.cancel()
        
        if let task = self as? CancellableTaskType, let cancellationHandler = task.cancellationHandler {
            cancellationHandler()
        }
        
        if let task = self as? TaskWithErrorType {
            task.finishWithError(NSError.userCancelledError())
        }
    }
    
    public override final func waitUntilFinished() {
        assert(!NSThread.isMainThread(), "Cannot wait on main thread.")
        super.waitUntilFinished()
    }
    
    // MARK: -
    
    internal final func willEnqueue() {
        self.state = .Pending
    }
    
    private func evaluateConditions() {
        assert(self.state == .Pending && !self.cancelled)
        
        guard let conditions = self.conditions where !conditions.isEmpty else {
            self.state = .Ready
            return
        }
        
        //
        self.state = .EvaluatingConditions
        
        //
        let evaluateConditionsOperation = NSBlockOperation { [unowned self] in
            guard !self.cancelled else { return }
            
            do {
                defer {
                    self.state = .Ready
                }

                let evaluateConditionsTask = TaskCondition.asyncEvaluateConditions(conditions)
                
                if let task = self as? CancellableTaskType {
                    task.cancellationHandler = { [weak evaluateConditionsTask] in
                        evaluateConditionsTask?.cancel()
                    }
                }
                
                try await(evaluateConditionsTask)
            }
            catch TaskConditionError.NotSatisfied {
                self.cancel()
            }
            catch TaskConditionError.Failed(let innerError) {
                if let task = self as? TaskWithErrorType {
                    task.finishWithError(innerError)
                }
                else {
                    self.cancel()
                }
            }
            catch let error {
                if let task = self as? TaskWithErrorType {
                    task.finishWithError(error)
                }
                else {
                    self.cancel()
                }
            }
        }
        
        //
        _conditionEvaluationQueue.addOperation(evaluateConditionsOperation)
    }
    
    private func execute() {
        self.state = .Executing
        
        if let observers = self.observers where !observers.isEmpty, let task = self as? TaskType {
            observers.forEach { $0.taskDidStartClosure?(task) }
        }

        if let mutuallyExclusiveConditions = self.conditions?.flatMap({ $0 as? MutuallyExclusiveTaskCondition }) where !mutuallyExclusiveConditions.isEmpty {
            self.incrementMutuallyExclusiveConditions(mutuallyExclusiveConditions)
            self.completionBlock = { [unowned self] in
                self.decrementMutuallyExclusiveConditions(mutuallyExclusiveConditions)
            }
        }

        self.closure()
    }
    
    private var _hasFinishedAlready = false
    internal final func internalFinish() {
        guard !self._hasFinishedAlready else { return }
        self._hasFinishedAlready = true
        
        self.state = .Finishing
        
        if let observers = self.observers where !observers.isEmpty, let task = self as? TaskType {
            observers.forEach { $0.taskWillFinishClosure?(task) }
        }
        
        self.state = .Finished

        if let observers = self.observers where !observers.isEmpty, let task = self as? TaskType {
            observers.forEach { $0.taskDidFinishClosure?(task) }
        }
    }
    
    
    // MARK: -
    
    private func incrementMutuallyExclusiveConditions(mutuallyExclusiveConditions: [MutuallyExclusiveTaskCondition]) {
        mutuallyExclusiveConditions.forEach {
            MutuallyExclusiveTaskCondition.increment($0.categoryName)
        }
    }
    
    private func decrementMutuallyExclusiveConditions(mutuallyExclusiveConditions: [MutuallyExclusiveTaskCondition]) {
        mutuallyExclusiveConditions.forEach {
            MutuallyExclusiveTaskCondition.decrement($0.categoryName)
        }
    }

}
