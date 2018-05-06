//
//  Async.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public typealias AsyncTaskClosure<Value> = () throws -> Value
public typealias AsyncNonFailableTaskClosure<Value> = () -> Value

public typealias AsyncTaskFullClosure<Value> = (BaseTask<Value>) -> Void

// MARK: -

public func async<Value>(in queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, execute closure: @escaping AsyncTaskClosure<Value>) -> Task<Value> {
    return enqueue(in: queue, dependency: dependency, condition: condition, closure: closure)
}

public func async<Value>(in queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, execute closure: @escaping AsyncNonFailableTaskClosure<Value>) -> NonFailableTask<Value> {
    return enqueue(in: queue, dependency: dependency, condition: condition, closure: closure)
}

fileprivate func enqueue<Value>(in queue: OperationQueue?, dependency: TaskDependency?, condition: TaskCondition?, closure: @escaping AsyncTaskClosure<Value>) -> Task<Value> {
    //
    let taskClosure: AsyncTaskFullClosure<Value> = {
        do {
            let value = try closure()
            $0.finish(with: value)
        }
        catch {
            $0.finish(with: error)
        }
    }
    
    //
    return enqueue(in: queue, dependency: dependency, condition: condition, closure: taskClosure)
}

fileprivate func enqueue<Value>(in queue: OperationQueue?, dependency: TaskDependency?, condition: TaskCondition?, closure: @escaping AsyncNonFailableTaskClosure<Value>) -> NonFailableTask<Value> {
    //
    let taskClosure: AsyncTaskFullClosure<Value> = {
        $0.finish(with: closure())
    }
    
    //
    return enqueue(in: queue, dependency: dependency, condition: condition, closure: taskClosure)
}

//

public func async<Value>(in queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, execute taskClosure: @escaping AsyncTaskFullClosure<Value>) -> Task<Value> {
    return enqueue(in: queue, dependency: dependency, condition: condition, closure: taskClosure)
}

public func async<Value>(in queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, execute taskClosure: @escaping AsyncTaskFullClosure<Value>) -> NonFailableTask<Value> {
    return enqueue(in: queue, dependency: dependency, condition: condition, closure: taskClosure)
}


fileprivate func enqueue<Value>(in queue: OperationQueue?, dependency: TaskDependency?, condition: TaskCondition?, closure taskClosure: @escaping AsyncTaskFullClosure<Value>) -> Task<Value> {
    //
    let queue = queue ?? Queue.defaultOperationQueue
    precondition(queue.maxConcurrentOperationCount > 1 || queue.maxConcurrentOperationCount == OperationQueue.defaultMaxConcurrentOperationCount)
    
    //
    let effectiveTaskClosure: AsyncTaskFullClosure<Value> = {
        Thread.current.cancellableTask = $0 as? CancellableTask; defer { Thread.current.cancellableTask = nil }
        taskClosure($0)
    }
    
    //
    let task = Task<Value>(dependency: dependency, condition: condition, closure: effectiveTaskClosure)
    let operation = BlockOperation(block: task.start)
    
    //
    let parentCancellableTask = Thread.current.cancellableTask
    parentCancellableTask?.cancellation += { [weak task] in
        task?.cancel()
    }
    
    task.cancellation += { [weak operation] in
        operation?.cancel()
    }
    
    //
    queue.addOperation(operation)
    
    //
    return task
}

fileprivate func enqueue<Value>(in queue: OperationQueue?, dependency: TaskDependency?, condition: TaskCondition?, closure taskClosure: @escaping AsyncTaskFullClosure<Value>) -> NonFailableTask<Value> {
    //
    let queue = queue ?? Queue.defaultOperationQueue
    precondition(queue.maxConcurrentOperationCount > 1 || queue.maxConcurrentOperationCount == OperationQueue.defaultMaxConcurrentOperationCount)
    
    //
    let task = NonFailableTask<Value>(dependency: dependency, condition: condition, closure: taskClosure)
    let operation = BlockOperation(block: task.start)
    
    //
    queue.addOperation(operation)
    
    //
    return task
}
// MARK: -

extension Thread {
    
    fileprivate var cancellableTask: CancellableTask? {
        get {
            return self.threadDictionary["___AAK_TASK"] as? CancellableTask
        }
        set {
            self.threadDictionary["___AAK_TASK"] = newValue
        }
    }
    
}
