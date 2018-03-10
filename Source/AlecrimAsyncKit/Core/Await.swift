//
//  Await.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

@discardableResult
public func await<Value>(_ task: Task<Value>) throws -> Value {
    return try task.await()
}

@discardableResult
public func await<Value>(_ task: NonFailableTask<Value>) -> Value {
    return try! task.await()
}


@discardableResult
public func await<Value>(_ closure: () -> Task<Value>) throws -> Value {
    let task = closure()
    return try task.await()
}

@discardableResult
public func await<Value>(_ closure: () -> NonFailableTask<Value>) -> Value {
    let task = closure()
    return try! task.await()
}

