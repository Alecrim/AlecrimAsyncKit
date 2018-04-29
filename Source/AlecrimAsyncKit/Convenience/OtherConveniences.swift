//
//  Convenience.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: - externally controlled tasks

/// The task must be retained and the `finish` method shall be called externally when done.
public func manualTask<Value>(in queue: OperationQueue? = nil) -> Task<Value> {
    return async(in: queue) { _ in }
}

/// The task must be retained and the `finish` method shall be called externally when done.
public func manualTask<Value>(in queue: OperationQueue? = nil) -> NonFailableTask<Value> {
    return async(in: queue) { _ in }
}

// MARK: -

// stubs for Void tasks

public func async(in queue: OperationQueue? = nil) -> Task<Void> {
    return async(in: queue) { return () }
}

public func async(in queue: OperationQueue? = nil) -> NonFailableTask<Void> {
    return async(in: queue) { return () }
}

// shortcuts to simply return a value or throw an error

public func async<Value>(in queue: OperationQueue? = nil, value: Value) -> Task<Value> {
    return async(in: queue) { return value }
}

public func async<Value>(in queue: OperationQueue? = nil, value: Value) -> NonFailableTask<Value> {
    return async(in: queue) { return value }
}

public func async<Value>(in queue: OperationQueue? = nil, error: Error) -> Task<Value> {
    return async(in: queue) { throw error }
}

// delay / sleep

fileprivate let _delayQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.Delay", qos: .utility, attributes: .concurrent)

public func async(in queue: OperationQueue? = nil, delay timeInterval: TimeInterval) -> Task<Void> {
    return async(in: queue, sleepForTimeInterval: timeInterval)
}

public func async(in queue: OperationQueue? = nil, delay timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(in: queue, sleepForTimeInterval: timeInterval)
}

public func async(in queue: OperationQueue? = nil, sleepForTimeInterval timeInterval: TimeInterval) -> Task<Void> {
    return async(in: queue) { task in
        _delayQueue.asyncAfter(deadline: .now() + timeInterval) {
            task.finish()
        }
    }
}

public func async(in queue: OperationQueue? = nil, sleepForTimeInterval timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(in: queue) { task in
        _delayQueue.asyncAfter(deadline: .now() + timeInterval) {
            task.finish()
        }
    }
}

public func async(in queue: OperationQueue? = nil, sleepUntil date: Date) -> Task<Void> {
    let now = Date()
    
    if date > now {
        let timeInterval = date.timeIntervalSince(now)
        return async(in: queue, sleepForTimeInterval: timeInterval)
    }
    else {
        return async(in: queue) {}
    }
}

public func async(in queue: OperationQueue? = nil, sleepUntil date: Date) -> NonFailableTask<Void> {
    let now = Date()
    
    if date > now {
        let timeInterval = date.timeIntervalSince(now)
        return async(in: queue, sleepForTimeInterval: timeInterval)
    }
    else {
        return async(in: queue) {}
    }
}
