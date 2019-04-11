//
//  Availability.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 15/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "async(on:execute:)")
public func asyncEx<Value>(in queue: OperationQueue? = nil, execute closure: @escaping AsyncTaskFullClosure<Value>) -> Task<Value> {
    return async(on: queue, execute: closure)
}

@available(*, deprecated, renamed: "async(value:)")
public func asyncValue<Value>(in queue: OperationQueue? = nil, _ value: Value) -> Task<Value> {
    return async(on: queue, value: value)
}

@available(*, deprecated, renamed: "async(error:)")
public func asyncError<Value>(in queue: OperationQueue? = nil, _ error: Error) -> Task<Value> {
    return async(on: queue, error: error)
}

@available(*, deprecated, renamed: "async(on:delay:)")
public func asyncDelay(in queue: OperationQueue? = nil, timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(on: queue, delay: timeInterval)
}

@available(*, deprecated, renamed: "async(on:sleepForTimeInterval:)")
public func asyncSleep(in queue: OperationQueue? = nil, forTimeInterval timeInterval: TimeInterval) -> NonFailableTask<Void> {
    return async(on: queue, sleepForTimeInterval: timeInterval)
}

@available(*, deprecated, renamed: "async(on:sleepUntil:)")
public func asyncSleep(in queue: OperationQueue? = nil, until date: Date) -> NonFailableTask<Void> {
    return async(on: queue, sleepUntil: date)
}
