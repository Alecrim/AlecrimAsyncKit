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
    
    if #available(OSXApplicationExtension 10.10, *) {
        queue.qualityOfService = .Background
    }
    
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
    }()

private let _defaultRunTaskQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.RunTask"
    
    if #available(OSXApplicationExtension 10.10, *) {
        queue.qualityOfService = .Background
    }
    
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
    }()

private let _defaultRunTaskCompletionQueue: NSOperationQueue = NSOperationQueue.mainQueue()

// MARK: - async - failable task

/// Creates and returns a `Task<V>` instance with the specified parameters.
///
/// - parameter queue:      The queue where the task will run.
/// - parameter conditions: The conditions that determine if the task will be started or not.
/// - parameter closure:    The closure that will be executed and that will return the tasks's associated value or throw errors.
///
/// - returns: A `Task<V>` instance with the specified parameters.
@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, conditions: [TaskCondition]? = nil, closure: () throws -> V) -> Task<V> {
    return Task<V>(queue: queue, conditions: conditions) { (task: Task<V>) -> Void  in
        do {
            let value = try closure()
            task.finishWithValue(value)
        }
        catch let error {
            task.finishWithError(error)
        }
    }
}

/// Creates and returns a `Task<V>` instance with the specified parameters.
///
/// - parameter queue:      The queue where the task will run.
/// - parameter condition:  The condition that determine if the task will be started or not.
/// - parameter closure:    The closure that will be executed and that will return the tasks's associated value or throw errors.
///
/// - returns: A `Task<V>` instance with the specified parameters.
@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, condition: TaskCondition, closure: () throws -> V) -> Task<V> {
    return Task<V>(queue: queue, conditions: [condition]) { (task: Task<V>) -> Void  in
        do {
            let value = try closure()
            task.finishWithValue(value)
        }
        catch let error {
            task.finishWithError(error)
        }
    }
}

/// Creates and returns a `Task<V>` instance that can be finished or cancelled in any thread with the specified parameters.
///
/// - parameter queue:      The queue where the task will run.
/// - parameter conditions: The conditions that determine if the task will be started or not.
/// - parameter closure:    The closure that will be executed and that, at some thread or context, will finish the task with a value or an error.
///
/// - returns: A `Task<V>` instance that can be finished or cancelled in any thread with the specified parameters.
@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, conditions: [TaskCondition]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(queue: queue, conditions: conditions, closure: closure)
}

/// Creates and returns a `Task<V>` instance that can be finished or cancelled in any thread with the specified parameters.
///
/// - parameter queue:      The queue where the task will run.
/// - parameter condition:  The condition that determine if the task will be started or not.
/// - parameter closure:    The closure that will be executed and that, at some thread or context, will finish the task with a value or an error.
///
/// - returns: A `Task<V>` instance that can be finished or cancelled in any thread with the specified parameters.
@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, condition: TaskCondition, closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(queue: queue, conditions: [condition], closure: closure)
}

// MARK: - async - non failable task

/// Creates and returns a `NonFailableTask<V>` instance with the specified parameters.
///
/// - parameter queue:     The queue where the task will run.
/// - parameter closure:   The closure that will be executed and that will return the tasks's associated value.
///
/// - returns: A `NonFailableTask<V>` instance with the specified parameters.
@warn_unused_result
public func async<V>(queue: NSOperationQueue = _defaultTaskQueue, closure: () -> V) -> NonFailableTask<V> {
    return NonFailableTask<V>(queue: queue) { (task: NonFailableTask<V>) -> Void in
        let value = closure()
        task.finishWithValue(value)
    }
}

/// Creates and returns a `Task<V>` instance that can be finished in any thread with the specified parameters.
///
/// - parameter queue:     The queue where the task will run.
/// - parameter closure:   The closure that will be executed and that, at some thread or context, will finish the task with a value.
///
/// - returns: A `Task<V>` instance that can be finished in any thread with the specified parameters.
@warn_unused_result
public func asyncEx<V>(queue: NSOperationQueue = _defaultTaskQueue, closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return NonFailableTask<V>(queue: queue, closure: closure)
}

// MARK: - await

/// Waits for the completion of a task and then returns its value.
///
/// - parameter closure: The closure that returns an initialized task.
///
/// - throws: Any error occurred while task was executing.
///
/// - returns: The task's associated value.
public func await<V>(@noescape closure: () -> Task<V>) throws -> V {
    return try closure().waitForCompletionAndReturnValue()
}

/// Waits for the completion of a task and then returns its value.
///
/// - parameter task: An initialized task.
///
/// - throws: Any error occurred while task was executing.
///
/// - returns: The task's associated value.
public func await<V>(task: Task<V>) throws -> V {
    return try task.waitForCompletionAndReturnValue()
}

/// Runs a task in a background queue and the call the completion handler with its associated value or error if occurred.
///
/// - parameter task:              The task to run.
/// - parameter queue:             The queue where the task will be "awaited".
/// - parameter completionQueue:   The queue where the completion handler will be called.
/// - parameter completionHandler: The optional completion handler.
@available(*, deprecated, message="Use `difFinish` or `didCancel` Task methods instead.")
public func runTask<V>(task: Task<V>, queue: NSOperationQueue = _defaultRunTaskQueue, completionQueue: NSOperationQueue = _defaultRunTaskCompletionQueue, completion completionHandler: ((V!, ErrorType?) -> Void)? = nil) {
    queue.addOperationWithBlock {
        do {
            let value = try task.waitForCompletionAndReturnValue()
            
            if let completionHandler = completionHandler {
                completionQueue.addOperationWithBlock {
                    completionHandler(value, nil)
                }
            }
        }
        catch let error {
            if let completionHandler = completionHandler {
                completionQueue.addOperationWithBlock {
                    completionHandler(nil, error)
                }
            }
        }
    }
}


// MARK: - await - non failable task

/// Waits for the completion of a non-failable task and then returns its value.
///
/// - parameter closure: The closure that returns an initialized non-failable task.
///
/// - returns: The non-failable task's associated value.
public func await<V>(@noescape closure: () -> NonFailableTask<V>) -> V {
    return closure().waitForCompletionAndReturnValue()
}

/// Waits for the completion of a non-failable task and then returns its value.
///
/// - parameter task: An initialized non-failable task.
///
/// - returns: The non-failable task's associated value.
public func await<V>(task: NonFailableTask<V>) -> V {
    return task.waitForCompletionAndReturnValue()
}

/// Runs a non-failable task in a background queue and then calls the completion handler with its associated value.
///
/// - parameter task:              The non-failable task to run.
/// - parameter queue:             The queue where the task will be "awaited".
/// - parameter completionQueue:   The queue where the completion handler will be called.
/// - parameter completionHandler: The optional completion handler.
@available(*, deprecated, message="Use `difFinish` NonFailableTask method instead.")
public func runTask<V>(task: NonFailableTask<V>, queue: NSOperationQueue = _defaultRunTaskQueue, completionQueue: NSOperationQueue = _defaultRunTaskCompletionQueue, completion completionHandler: ((V) -> Void)? = nil) {
    queue.addOperationWithBlock {
        let value = task.waitForCompletionAndReturnValue()
        
        if let completionHandler = completionHandler {
            completionQueue.addOperationWithBlock {
                completionHandler(value)
            }
        }
    }
}

