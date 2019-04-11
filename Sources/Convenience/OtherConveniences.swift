//
//  Convenience.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

//

// MARK: - externally controlled tasks

/// The task must be retained and the `finish` method shall be called externally when done.
public func manualTask<Value>(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil) -> Task<Value> {
    return async(on: queue, dependency: dependency, condition: condition) { _ in }
}

/// The task must be retained and the `finish` method shall be called externally when done.
public func manualTask<Value>(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil) -> NonFailableTask<Value> {
    return async(on: queue, dependency: dependency, condition: condition) { _ in }
}

// MARK: -

// stubs for Void tasks

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil) -> Task<Void> {
    return async(on: queue, dependency: dependency, condition: condition) { return () }
}

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil) -> NonFailableTask<Void> {
    return async(on: queue, dependency: dependency, condition: condition) { return () }
}

// shortcuts to simply return a value or throw an error

public func async<Value>(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, value: Value) -> Task<Value> {
    return async(on: queue, dependency: dependency, condition: condition) { return value }
}

public func async<Value>(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, value: Value) -> NonFailableTask<Value> {
    return async(on: queue, dependency: dependency, condition: condition) { return value }
}

public func async<Value>(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, error: Error) -> Task<Value> {
    return async(on: queue, dependency: dependency, condition: condition) { throw error }
}

// delay / sleep

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, delay timeInterval: TimeInterval) -> Task<Void> {
    return async(on: queue, dependency: dependency, condition: condition, sleepForTimeInterval: timeInterval)
}

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, delay timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(on: queue, dependency: dependency, condition: condition, sleepForTimeInterval: timeInterval)
}

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, sleepForTimeInterval timeInterval: TimeInterval) -> Task<Void> {
    return async(on: queue, dependency: dependency, condition: condition) { task in
        Queue.delayDispatchQueue.asyncAfter(deadline: .now() + timeInterval) {
            task.finish()
        }
    }
}

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, sleepForTimeInterval timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(on: queue, dependency: dependency, condition: condition) { task in
        Queue.delayDispatchQueue.asyncAfter(deadline: .now() + timeInterval) {
            task.finish()
        }
    }
}

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, sleepUntil date: Date) -> Task<Void> {
    let now = Date()
    
    if date > now {
        let timeInterval = date.timeIntervalSince(now)
        return async(on: queue, dependency: dependency, condition: condition, sleepForTimeInterval: timeInterval)
    }
    else {
        return async(on: queue, dependency: dependency, condition: condition) {}
    }
}

public func async(on queue: OperationQueue? = nil, dependency: TaskDependency? = nil, condition: TaskCondition? = nil, sleepUntil date: Date) -> NonFailableTask<Void> {
    let now = Date()
    
    if date > now {
        let timeInterval = date.timeIntervalSince(now)
        return async(on: queue, dependency: dependency, condition: condition, sleepForTimeInterval: timeInterval)
    }
    else {
        return async(on: queue, dependency: dependency, condition: condition) {}
    }
}
