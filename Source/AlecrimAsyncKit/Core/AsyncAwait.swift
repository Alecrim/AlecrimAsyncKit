//
//  AsyncAwait.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public typealias TaskPriority = Operation.QueuePriority

// MARK: - async

public func async<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, qualityOfService: QualityOfService? = nil, taskPriority: TaskPriority? = nil, observers: [TaskObserver]? = nil, closure: () -> V) -> NonFailableTask<V> {
    return createdTask(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: nil, observers: observers, asynchronous: false) { task in
        let value = closure()
        task.finish(with: value)
    }
}

public func async<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, qualityOfService: QualityOfService? = nil, taskPriority: TaskPriority? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
    return async(in: queue, qualityOfService: qualityOfService, conditions: [condition], taskPriority: taskPriority, observers: observers, closure: closure)
}

public func async<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, qualityOfService: QualityOfService? = nil, taskPriority: TaskPriority? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: () throws -> V) -> Task<V> {
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

public func asyncEx<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, qualityOfService: QualityOfService? = nil, taskPriority: TaskPriority? = nil, observers: [TaskObserver]? = nil, closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return createdTask(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: nil, observers: observers, asynchronous: true, closure: closure)
}

public func asyncEx<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, qualityOfService: QualityOfService? = nil, taskPriority: TaskPriority? = nil, condition: TaskCondition, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return asyncEx(in: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: [condition], observers: observers, closure: closure)
}

public func asyncEx<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, qualityOfService: QualityOfService? = nil, taskPriority: TaskPriority? = nil, conditions: [TaskCondition]? = nil, observers: [TaskObserver]? = nil, closure: (Task<V>) -> Void) -> Task<V> {
    return createdTask(queue: queue, qualityOfService: qualityOfService, taskPriority: taskPriority, conditions: conditions, observers: observers, asynchronous: true, closure: closure)
}


// MARK: - await

@discardableResult
public func await<V>(_ closure: @noescape () -> NonFailableTask<V>) -> V {
    let task = closure()
    return await(task)
}

@discardableResult
public func await<V>(_ task: NonFailableTask<V>) -> V {
    // this should never be called, but just in case...
    if let parentTask = Thread.current().task as? CancellableTask, let currentTask = task as? CancellableTask where parentTask !== currentTask {
        currentTask.internalInheritCancellation(from: parentTask)
    }
    
    //
    task.waitUntilFinished()
    return task.value
}

@discardableResult
public func await<V>(_ closure: @noescape () -> Task<V>) throws -> V {
    let task = closure()
    return try await(task)
}

@discardableResult
public func await<V>(_ task: Task<V>) throws -> V {
    //
    if let parentTask = Thread.current().task as? CancellableTask where parentTask !== task {
        task.internalInheritCancellation(from: parentTask)
    }

    //
    task.waitUntilFinished()
    
    if let error = task.error {
        throw error
    }
    
    return task.value
}

// MARK: - Helper methods

public func asyncDelay(in queue: OperationQueue = Queue.taskDefaultOperationQueue, timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return asyncSleep(in: queue, forTimeInterval: timeInterval)
}

public func asyncSleep(in queue: OperationQueue = Queue.taskDefaultOperationQueue, forTimeInterval timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return asyncEx(in: queue) { t in
        let timer = DispatchSource.timer(flags: [], queue: Queue.delayQueue)
        
        timer.scheduleOneshot(deadline: DispatchTime.now() + timeInterval)
        timer.setEventHandler() { t.finish() }
        timer.resume()
    }
}

public func asyncSleep(in queue: OperationQueue = Queue.taskDefaultOperationQueue, until date: Date) -> NonFailableTask<Void> {
    let now = Date()
    
    if date > now {
        let timeInterval = date.timeIntervalSince(now)
        return asyncSleep(in: queue, forTimeInterval: timeInterval)
    }
    else {
        return async(in: queue) {}
    }
}

public func asyncValue<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, _ value: V) -> Task<V> {
    return async(in: queue) { return value }
}

public func asyncError<V>(in queue: OperationQueue = Queue.taskDefaultOperationQueue, _ error: ErrorProtocol) -> Task<V> {
    return async(in: queue) { throw error }
}

// MARK: -

private func createdTask<T: InitializableTask>(queue: OperationQueue, qualityOfService: QualityOfService?, taskPriority: TaskPriority?, conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (T) -> Void) -> T {
    precondition(queue.maxConcurrentOperationCount == OperationQueue.defaultMaxConcurrentOperationCount || queue.maxConcurrentOperationCount > 1, "Task `queue` cannot be the main queue nor a serial queue.")
    
    //
    let effectiveClosure: (T) -> Void = {
        Thread.current().task = $0
        defer { Thread.current().task = nil }
        
        closure($0)
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

extension Thread {
    
    private var task: TaskProtocol? {
        get {
            return self.threadDictionary["___AAK_TASK"] as? TaskProtocol
        }
        set {
            self.threadDictionary["___AAK_TASK"] = newValue
        }
    }

}

