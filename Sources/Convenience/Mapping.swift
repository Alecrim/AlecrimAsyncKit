//
//  Mapping.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 06/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

extension Task {

    public func map<U>(on queue: OperationQueue? = nil, closure: @escaping (Value) throws -> U) -> Task<U> {
        return async(on: queue) {
            let value = try self.await()
            let mappedValue = try closure(value)

            return mappedValue
        }
    }

    public func map<U>(on queue: OperationQueue? = nil, closure: @escaping (Value) -> U) -> Task<U> {
        return async(on: queue) {
            let value = try self.await()
            let mappedValue = closure(value)

            return mappedValue
        }
    }

}

extension Task {

    public func asNonFailable(on queue: OperationQueue? = nil) -> NonFailableTask<Value> {
        return async(on: queue) {
            return try! self.await()
        }
    }

}

// MARK: -

extension NonFailableTask {

    public func map<U>(on queue: OperationQueue? = nil, closure: @escaping (Value) -> U) -> NonFailableTask<U> {
        return async(on: queue) {
            let value = try! self.await()
            let mappedValue = closure(value)

            return mappedValue
        }
    }

}

extension NonFailableTask {

    public func asFailable(on queue: OperationQueue? = nil) -> Task<Value> {
        return async(on: queue) {
            return try self.await()
        }
    }

}
