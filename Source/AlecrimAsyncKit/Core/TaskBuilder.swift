//
//  TaskBuilder.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private let _defaultTaskQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.Task"
    queue.qualityOfService = .Default
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

private let _defaultConditionEvaluationQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.ConditionEvaluation"
    queue.qualityOfService = .Default
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

// MARK: - async

@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, observers: [TaskObserver]? = nil, closure: () -> V) -> NonFailableTask<V> {
    return asyncEx(queue, qualityOfService: qualityOfService, observers: observers) { task in
        let value = closure()
        task.finishWithValue(value)
    }
}

@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
    return async(queue, qualityOfService: qualityOfService, conditions: [condition], observers: observers, closure: closure)
}

@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
    return asyncEx(queue, qualityOfService: qualityOfService, observers: observers) { task in
        do {
            let value = try closure()
            task.finishWithValue(value)
        }
        catch let error {
            task.finishWithError(error)
        }
    }
}

// MARK: - asyncEx

@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, observers: [TaskObserver]? = nil, closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return TaskBuilder(queue: queue, qualityOfService: qualityOfService, conditions: nil, observers: observers, closure: closure).start()
}

@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return asyncEx(queue, qualityOfService: qualityOfService, conditions: [condition], observers: observers, closure: closure)
}


@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return TaskBuilder(queue: queue, qualityOfService: qualityOfService, conditions: conditions, observers: observers, closure: closure).start()
}


// MARK: - await

public func await<V>(@noescape closure: () -> NonFailableTask<V>) -> V {
    let task = closure()
    return await(task)
}

public func await<V>(task: NonFailableTask<V>) -> V {
    try! task.wait()
    return task.value
}

public func await<V>(@noescape closure: () -> Task<V>) throws -> V {
    let task = closure()
    return try await(task)
}

public func await<V>(task: Task<V>) throws -> V {
    try task.wait()
    return task.value
}


// MARK: - TaskBuilder

private final class TaskBuilder<T: TaskType, V where T.ValueType == V> {
    
    private let queue: NSOperationQueue
    private let qualityOfService: NSQualityOfService
    private let conditions: [TaskCondition]?
    private let observers: [TaskObserver]?
    private var closure: ((T) -> Void)!

    private init!(queue: NSOperationQueue, qualityOfService: NSQualityOfService?, conditions: [TaskCondition]?, observers: [TaskObserver]?, closure: (T) -> Void) {
        assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
        
        //
        self.queue = queue
        self.qualityOfService = qualityOfService ?? queue.qualityOfService
        self.conditions = conditions
        self.observers = observers
        self.closure = closure
    }
    
    private func start() -> T {
        //
        let task = T(closure: self.closure) as! BaseTask<V>
        self.closure = nil
        task.delegate = self
        
        //
        task.state = .Pending
        
        //
        return task as! T
    }
    
}

extension TaskBuilder: BaseTaskDelegate {
    
    private func task<V>(task: BaseTask<V>, didChangeToState state: TaskState) {
        switch state {
        case .Pending:
            if let conditions = self.conditions where !conditions.isEmpty {
                task.state = .EvaluatingConditions
            }
            else {
                task.state = .Ready
            }
            
        case .EvaluatingConditions:
            if let conditions = self.conditions where !conditions.isEmpty, let ft = task as? Task<V> {
                let conditionEvaluationOperation = NSBlockOperation {
                    //
                    let mutuallyExclusiveConditions = conditions.flatMap { $0 as? MutuallyExclusiveTaskCondition }
                    if !mutuallyExclusiveConditions.isEmpty {
                        mutuallyExclusiveConditions.forEach { mutuallyExclusiveCondition in
                            MutuallyExclusiveTaskCondition.increment(mutuallyExclusiveCondition.categoryName)
                        }
                    }
                    
                    //
                    do {
                        try await(TaskCondition.asyncEvaluateConditions(conditions))
                        ft.state = .Ready
                    }
                    catch TaskConditionError.NotSatisfied {
                        ft.cancel()
                    }
                    catch TaskConditionError.Failed(let innerError) {
                        ft.finishWithError(innerError)
                    }
                    catch let error {
                        ft.finishWithError(error)
                    }
                }
                
                conditionEvaluationOperation.qualityOfService = self.qualityOfService
                _defaultConditionEvaluationQueue.addOperation(conditionEvaluationOperation)
            }
            else {
                task.state = .Ready
            }
            
        case .Ready:
            //
            if let observers = self.observers where !observers.isEmpty {
                observers.forEach { $0.taskWillStartClosure?(task) }
            }
            
            // enqueue
            let operation = NSBlockOperation {
                guard task.state == .Ready else { return }
                
                task.state = .Executing
                task.execute()
            }
            
            operation.qualityOfService = self.qualityOfService
            self.queue.addOperation(operation)
            
        case .Executing:
            if let observers = self.observers where !observers.isEmpty {
                observers.forEach { $0.taskDidStartClosure?(task) }
            }
            
            // transition to .Finishing is handled by task class
            
        case .Finishing:
            if let observers = self.observers where !observers.isEmpty {
                observers.forEach { $0.taskWillFinishClosure?(task) }
            }
            
            // transition to .Finished is handled by task class
            
        case .Finished:
            //
            if let conditions = self.conditions where !conditions.isEmpty, let _ = task as? Task<V> {
                let mutuallyExclusiveConditions = conditions.flatMap { $0 as? MutuallyExclusiveTaskCondition }
                if !mutuallyExclusiveConditions.isEmpty {
                    mutuallyExclusiveConditions.forEach { mutuallyExclusiveCondition in
                        MutuallyExclusiveTaskCondition.decrement(mutuallyExclusiveCondition.categoryName)
                    }
                }
            }
            
            //
            if let observers = self.observers where !observers.isEmpty {
                observers.forEach { $0.taskDidFinishClosure?(task) }
            }
            
            //
            if task.progressAssigned {
                if task.value != nil {
                    task.progress.completedUnitCount = task.progress.totalUnitCount
                }
                else if let ft = task as? Task<V>, let error = ft.error as? NSError where error.userCancelled {
                    task.progress.cancellationHandler?()
                }
            }
            
            // to ensure
            task.delegate = nil
            
        default:
            break
        }
    }
    
}
