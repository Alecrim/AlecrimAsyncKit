//
//  AsyncAwait.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private let _defaultTaskQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.Task"
    queue.qualityOfService = .Utility
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

// MARK: -

public typealias TaskPriority = NSOperationQueuePriority

// MARK: - async

@warn_unused_result
public func async<V>(queue queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, observers: [TaskObserver]? = nil, closure: () -> V) -> NonFailableTask<V> {
    return createdTaskWith(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: nil, observers: observers, asynchronous: false) { task in
        let value = closure()
        task.finishWith(value: value)
    }
}

@warn_unused_result
public func async<V>(queue queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
    return async(queue: queue, qualityOfService: qualityOfService, conditions: [condition], taskPriority: taskPriority, observers: observers, closure: closure)
}

@warn_unused_result
public func async<V>(queue queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
    return createdTaskWith(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: conditions, observers: observers, asynchronous: false) { task in
        do {
            let value = try closure()
            task.finishWith(value: value)
        }
        catch let error {
            task.finishWith(error: error)
        }
    }
}

// MARK: - asyncEx

@warn_unused_result
public func asyncEx<V>(queue queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, observers: [TaskObserver]? = nil, closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return createdTaskWith(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: nil, observers: observers, asynchronous: true, closure: closure)
}

@warn_unused_result
public func asyncEx<V>(queue queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return asyncEx(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: [condition], observers: observers, closure: closure)
}


@warn_unused_result
public func asyncEx<V>(queue queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return createdTaskWith(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: conditions, observers: observers, asynchronous: true, closure: closure)
}


// MARK: - await

public func await<V>(@noescape closure: () -> NonFailableTask<V>) -> V {
    let task = closure()
    return await(task)
}

public func await<V>(task: NonFailableTask<V>) -> V {
    task.waitUntilFinished()
    return task.value
}

public func await<V>(@noescape closure: () -> Task<V>) throws -> V {
    let task = closure()
    return try await(task)
}

public func await<V>(task: Task<V>) throws -> V {
    task.waitUntilFinished()
    
    if let error = task.error {
        throw error
    }
    
    return task.value
}


// MARK: - 

private func createdTaskWith<T: InitializableTaskType>(queue queue: NSOperationQueue, qualityOfService: NSQualityOfService?, taskPriority: TaskPriority?, conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (T) -> Void) -> T {
    assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
    
    //
    let task = T(conditions: conditions, observers: observers, asynchronous: asynchronous, closure: closure)
    let operation = task as! TaskOperation
    
    //
    if let qualityOfService = qualityOfService {
        operation.qualityOfService = qualityOfService
    }
    
    if let taskPriority = taskPriority {
        operation.queuePriority = taskPriority
    }
    
    //
    operation.willEnqueue()
    queue.addOperation(operation)
    
    //
    return task
}

