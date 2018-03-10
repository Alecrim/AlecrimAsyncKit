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

public func async<Value>(in queue: OperationQueue? = nil, error: Error) -> Task<Value> {
    return async(in: queue) { throw error }
}

// MARK:

extension NSError {
    
    internal static let userCancelled = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)

}

extension Error {
    
    internal var isUserCancelled: Bool {
        let error = self as NSError
        return error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError
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
