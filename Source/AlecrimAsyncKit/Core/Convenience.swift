//
//  Convenience.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public func async<Value>(in queue: OperationQueue? = nil, value: Value) -> Task<Value> {
    return async(in: queue) { return value }
}

public func async<Value>(in queue: OperationQueue? = nil, value: Value) -> NonFailableTask<Value> {
    return async(in: queue) { return value }
}

public func async<Value>(in queue: OperationQueue? = nil, error: Error) -> Task<Value> {
    return async(in: queue) { throw error }
}

//

fileprivate let delayQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.Delay", qos: .utility, attributes: .concurrent)

public func async(in queue: OperationQueue? = nil, delay timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(in: queue, sleepForTimeInterval: timeInterval)
}

public func async(in queue: OperationQueue? = nil, sleepForTimeInterval timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(in: queue) { task in
        delayQueue.asyncAfter(deadline: .now() + timeInterval) {
            task.finish()
        }
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


// MARK: -

@available(*, deprecated, renamed: "async(in:execute:)")
public func asyncEx<Value>(in queue: OperationQueue? = nil, execute closure: @escaping AsyncTaskFullClosure<Value>) -> Task<Value> {
    return async(in: queue, execute: closure)
}

@available(*, deprecated, renamed: "async(value:)")
public func asyncValue<Value>(in queue: OperationQueue? = nil, _ value: Value) -> Task<Value> {
    return async(in: queue, value: value)
}

@available(*, deprecated, renamed: "async(error:)")
public func asyncError<Value>(in queue: OperationQueue? = nil, _ error: Error) -> Task<Value> {
    return async(in: queue, error: error)
}

@available(*, deprecated, renamed: "async(in:delay:)")
public func asyncDelay(in queue: OperationQueue? = nil, timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(in: queue, delay: timeInterval)
}

@available(*, deprecated, renamed: "async(in:sleepForTimeInterval:)")
public func asyncSleep(in queue: OperationQueue? = nil, forTimeInterval timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(in: queue, sleepForTimeInterval: timeInterval)
}

@available(*, deprecated, renamed: "async(in:sleepUntil:)")
public func asyncSleep(in queue: OperationQueue? = nil, until date: Date) -> NonFailableTask<Void> {
    return async(in: queue, sleepUntil: date)
}

