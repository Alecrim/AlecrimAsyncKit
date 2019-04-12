//
//  Async.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

private let _defaultDispatchQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.Async.Default", qos: .utility, attributes: .concurrent)

// MARK: - Async

public func async<V>(on queue: DispatchQueue? = nil, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping () throws -> V) -> Task<V, Error> {
    let task = Task(qos: qos, flags: flags, closure: closure)
    task.execute(on: queue ?? _defaultDispatchQueue)

    return task
}

public func async<V>(on queue: DispatchQueue? = nil, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping () -> V) -> Task<V, Never> {
    let task = Task(qos: qos, flags: flags, closure: closure)
    task.execute(on: queue ?? _defaultDispatchQueue)

    return task
}

public func async<V, E: Error>(on queue: DispatchQueue? = nil, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping (Task<V, E>) -> Void) -> Task<V, E> {
    let task = Task(qos: qos, flags: flags, closure: closure)
    task.execute(on: queue ?? _defaultDispatchQueue)

    return task
}
