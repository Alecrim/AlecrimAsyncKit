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
public func async<V>(in queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, observers: [TaskObserver]? = nil, closure: () -> V) -> NonFailableTask<V> {
    return createdTask(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: nil, observers: observers, asynchronous: false) { task in
        let value = closure()
        task.finish(with: value)
    }
}

@warn_unused_result
public func async<V>(in queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
    return async(in: queue, qualityOfService: qualityOfService, conditions: [condition], taskPriority: taskPriority, observers: observers, closure: closure)
}

@warn_unused_result
public func async<V>(in queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
    return createdTask(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: conditions, observers: observers, asynchronous: false) { task in
        do {
            let value = try closure()
            task.finish(with: value)
        }
        catch let error {
            task.finish(with: error)
        }
    }
}

// MARK: - asyncEx

@warn_unused_result
public func asyncEx<V>(in queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, observers: [TaskObserver]? = nil, closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return createdTask(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: nil, observers: observers, asynchronous: true, closure: closure)
}

@warn_unused_result
public func asyncEx<V>(in queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return asyncEx(in: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: [condition], observers: observers, closure: closure)
}


@warn_unused_result
public func asyncEx<V>(in queue: NSOperationQueue = _defaultTaskQueue, qualityOfService: NSQualityOfService? = nil, taskPriority: TaskPriority? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return createdTask(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: conditions, observers: observers, asynchronous: true, closure: closure)
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

// MARK: - Helper methods

private final class ThreadWithClosure: NSThread {
    
    private let closure: () -> Void
    
    private init(closure: () -> Void) {
        self.closure = closure
        super.init()
    }
    
    private override func main() {
        self.closure()
    }
    
}

@warn_unused_result
public func delay(timeInterval: NSTimeInterval) -> NonFailableTask<Void> {
    return sleep(forTimeInterval: timeInterval)
}

@warn_unused_result
public func sleep(forTimeInterval ti: NSTimeInterval) -> NonFailableTask<Void> {
    return asyncEx { t in
        let thread = ThreadWithClosure {
            NSThread.sleepForTimeInterval(ti)
            t.finish()
        }
        
        thread.start()
    }
}

@warn_unused_result
public func sleep(until date: NSDate) -> NonFailableTask<Void> {
    return asyncEx { t in
        let thread = ThreadWithClosure {
            NSThread.sleepUntilDate(date)
            t.finish()
        }
        
        thread.start()
    }
}

@warn_unused_result
public func whenAll(tasks: [TaskProtocol]) -> Task<Void> {
    return async {
        for task in tasks {
            task.waitUntilFinished()
            
            if let errorReportingTask = task as? ErrorReportingTask, let error = errorReportingTask.error {
                throw error
            }
        }
    }
}

@warn_unused_result
public func whenAny(tasks: [TaskProtocol]) -> Task<TaskProtocol> {
    return asyncEx { t in
        func observeTask(task: TaskProtocol) throws -> Task<Void> {
            return async {
                task.waitUntilFinished()
                
                if let errorReportingTask = task as? ErrorReportingTask, let error = errorReportingTask.error {
                    throw error
                }
                
                t.finish(with: task)
            }
        }
        
        do {
            for task in tasks {
                if t.finished {
                    break
                }
                
                try observeTask(task)
            }
        }
        catch let error {
            t.finish(with: error)
        }
    }
}

// MARK: -

private func createdTask<T: InitializableTask>(queue queue: NSOperationQueue, qualityOfService: NSQualityOfService?, taskPriority: TaskPriority?, conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (T) -> Void) -> T {
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

