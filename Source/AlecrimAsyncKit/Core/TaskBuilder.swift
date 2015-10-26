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
    
    if #available(OSXApplicationExtension 10.10, *) {
        queue.qualityOfService = .Background
    }
    
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

// MARK: - async

@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, userInitiated: Bool = false, observers: [TaskObserver<NonFailableTask<V>, V>]? = nil, closure: () -> V) -> NonFailableTask<V> {
    return asyncEx(queue, userInitiated: userInitiated, observers: observers) { task in
        let value = closure()
        task.finishWithValue(value)
    }
}

@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, userInitiated: Bool = false, condition: TaskCondition, observers: [TaskObserver<Task<V>, V>]? = nil, closure: () throws -> V) -> Task<V> {
    return async(queue, userInitiated: userInitiated, conditions: [condition], observers: observers, closure: closure)
}

@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, userInitiated: Bool = false, conditions: [TaskCondition]? = nil, observers: [TaskObserver<Task<V>, V>]? = nil, closure: () throws -> V) -> Task<V> {
    return asyncEx(queue, userInitiated: userInitiated, observers: observers) { task in
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
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, userInitiated: Bool = false, observers: [TaskObserver<NonFailableTask<V>, V>]? = nil, closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return TaskBuilder(queue: queue, userInitiated: userInitiated, conditions: nil, observers: observers, closure: closure).start()
}

@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, userInitiated: Bool = false, condition: TaskCondition, observers: [TaskObserver<Task<V>, V>]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return asyncEx(queue, userInitiated: userInitiated, conditions: [condition], observers: observers, closure: closure)
}


@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, userInitiated: Bool = false, conditions: [TaskCondition]? = nil, observers: [TaskObserver<Task<V>, V>]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return TaskBuilder(queue: queue, userInitiated: userInitiated, conditions: conditions, observers: observers, closure: closure).start()
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
    private let userInitiated: Bool
    private let conditions: [TaskCondition]?
    private let observers: [TaskObserver<T, V>]?
    private var closure: ((T) -> Void)!

    private init!(queue: NSOperationQueue, userInitiated: Bool, conditions: [TaskCondition]?, observers: [TaskObserver<T, V>]?, closure: (T) -> Void) {
        assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
        
        //
        self.queue = queue
        self.userInitiated = userInitiated
        self.conditions = conditions
        self.observers = observers
        self.closure = closure
    }
    
    deinit {
        print("TASKBUILDER deinit")
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
            else {
                task.state = .Ready
            }
            
        case .Ready:
            //
            if let observers = self.observers where !observers.isEmpty {
                observers.forEach { $0.taskWillStartClosure?(task as! T) }
            }
            
            // enqueue
            let operation = NSBlockOperation {
                guard task.state == .Ready else { return }
                
                task.state = .Executing
                task.execute()
            }
            
            if self.userInitiated {
                if #available(OSXApplicationExtension 10.10, *) {
                    operation.qualityOfService = .UserInitiated
                }
            }
            else {
                if #available(OSXApplicationExtension 10.10, *) {
                    operation.qualityOfService = self.queue.qualityOfService
                }
            }
            
            self.queue.addOperation(operation)
            
        case .Executing:
            if let observers = self.observers where !observers.isEmpty {
                observers.forEach { $0.taskDidStartClosure?(task as! T) }
            }
            
            // transition to .Finishing is handled by task class
            
        case .Finishing:
            if let observers = self.observers where !observers.isEmpty {
                observers.forEach { $0.taskWillFinishClosure?(task as! T) }
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
                if let t = task as? T, let value = t.value {
                    for observer in observers {
                        observer.taskDidFinishWithValueClosure?(task as! T, value)
                    }
                }
                
                if let ft = task as? Task<V> {
                    observers.forEach {
                        if let error = ft.error as? NSError {
                            if error.userCancelled {
                                $0.taskDidCancelClosure?(task as! T)
                            }
                            else {
                                $0.taskDidFinishWithErrorClosure?(task as! T, error)
                            }
                        }
                    }
                }
                
                observers.forEach { $0.taskDidFinishClosure?(task as! T) }
            }
            
            // to ensure
            task.delegate = nil
            
        default:
            break
        }
    }
    
}
