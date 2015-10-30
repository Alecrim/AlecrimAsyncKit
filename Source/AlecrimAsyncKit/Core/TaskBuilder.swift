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
    
    private let operation: TaskOperation<T, V>

    private init(queue: NSOperationQueue, qualityOfService: NSQualityOfService?, conditions: [TaskCondition]?, observers: [TaskObserver]?, closure: (T) -> Void) {
        assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
        
        //
        self.queue = queue
        self.qualityOfService = qualityOfService ?? queue.qualityOfService
        
        //
        let task = T(closure: closure)
        
        self.operation = TaskOperation(task: task, conditions: conditions, observers: observers)
        self.operation.qualityOfService = qualityOfService ?? queue.qualityOfService
        
        (task as? BaseTask<V>)?.cancellationHandler = { [weak self] in
            if let operation = self?.operation {
                operation.cancel()
                operation.dependencies.forEach {
                    operation.removeDependency($0)
                }
            }
        }
    }
    
    private func start() -> T {
        //
        self.operation.willEnqueue()
        self.queue.addOperation(self.operation)
        
        //
        return self.operation.task 
    }
    
}
