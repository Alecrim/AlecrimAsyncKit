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
    // this should never be called, but just in case...
    if let parentTask = NSThread.currentThread().task as? CancellableTask, let currentTask = task as? CancellableTask where currentTask !== parentTask {
        parentTask.cancellationHandler = { [weak currentTask] in
            currentTask?.cancel()
        }
    }
    
    //
    task.waitUntilFinished()
    return task.value
}

public func await<V>(@noescape closure: () -> Task<V>) throws -> V {
    let task = closure()
    return try await(task)
}

public func await<V>(task: Task<V>) throws -> V {
    //
    if let parentTask = NSThread.currentThread().task as? CancellableTask, let currentTask = task as? CancellableTask where currentTask !== parentTask {
        parentTask.cancellationHandler = { [weak currentTask] in
            currentTask?.cancel()
        }
    }

    //
    task.waitUntilFinished()
    
    if let error = task.error {
        throw error
    }
    
    return task.value
}

// MARK: - Helper methods

@warn_unused_result
public func delay(timeInterval: NSTimeInterval) -> NonFailableTask<Void> {
    return sleep(forTimeInterval: timeInterval)
}

@warn_unused_result
public func sleep(forTimeInterval ti: NSTimeInterval) -> NonFailableTask<Void> {
    return asyncEx { t in
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(ti * Double(NSEC_PER_SEC)))
        dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            t.finish()
        }
    }
}

@warn_unused_result
public func sleep(until date: NSDate) -> NonFailableTask<Void> {
    let now = NSDate()
    if now.compare(date) == .OrderedAscending {
        let ti = date.timeIntervalSinceDate(now)
        return sleep(forTimeInterval: ti)
    }
    else {
        return async {}
    }
}

// MARK: -

private func createdTask<T: InitializableTask>(queue queue: NSOperationQueue, qualityOfService: NSQualityOfService?, taskPriority: TaskPriority?, conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (T) -> Void) -> T {
    assert(queue.maxConcurrentOperationCount == NSOperationQueueDefaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
    
    //
    func push(task: T) {
        NSThread.currentThread().task = task
    }
    
    func pop() {
        NSThread.currentThread().task = nil
    }
    
    let effectiveClosure: (T) -> Void = {
        push($0)
        closure($0)
        pop()
    }
    
    //
    let task = T(conditions: conditions, observers: observers, asynchronous: asynchronous, closure: effectiveClosure)
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

// MARK: -

extension NSThread {
    
    private var task: TaskProtocol? {
        get {
            return self.threadDictionary["___AAK_TASK"] as? TaskProtocol
        }
        set {
            self.threadDictionary["___AAK_TASK"] = newValue
        }
    }

}

