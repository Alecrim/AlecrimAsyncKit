//
//  Await.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: - Await

@discardableResult
public func await<V>(_ task: Task<V, Error>) throws -> V {
    return try task.await()
}

@discardableResult
public func await<V>(_ task: Task<V, Never>) -> V {
    return task.await()
}

@discardableResult
public func await<V>(_ closure: () -> Task<V, Error>) throws -> V {
    let task = closure()
    return try task.await()
}

@discardableResult
public func await<V>(_ closure: () -> Task<V, Never>) -> V {
    let task = closure()
    return task.await()
}
