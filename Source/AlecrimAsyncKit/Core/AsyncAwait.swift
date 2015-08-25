//
//  AsyncAwait.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-05-10.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private let _defaultRunTaskQueue: dispatch_queue_t = {
    let typeAttribute = DISPATCH_QUEUE_CONCURRENT
    let qualityOfServiceClass = QOS_CLASS_DEFAULT
    
    let name = "com.alecrim.AlecrimAsyncKit.RunTask"
    let attributes = dispatch_queue_attr_make_with_qos_class(typeAttribute, qualityOfServiceClass, QOS_MIN_RELATIVE_PRIORITY)
    
    return dispatch_queue_create(name, attributes)
    }()

private let _defaultRunTaskCompletionQueue: dispatch_queue_t = dispatch_get_main_queue()


// MARK: - async

@warn_unused_result
public func async<V>(closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(observers: nil, conditions: nil, closure: closure)
}

@warn_unused_result
public func async<V>(condition: TaskCondition, closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(observers: nil, conditions: [condition], closure: closure)
}

@warn_unused_result
public func async<V>(conditions: [TaskCondition], closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(observers: nil, conditions: conditions, closure: closure)
}

@warn_unused_result
public func async<V>(observers: [TaskObserver<V>], closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(observers: observers, conditions: nil, closure: closure)
}

@warn_unused_result
public func async<V>(conditions: [TaskCondition], observers: [TaskObserver<V>], closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(observers: observers, conditions: conditions, closure: closure)
}

// MARK: - async - non failable task

@warn_unused_result
public func async<V>(closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return NonFailableTask<V>(observers: nil, closure: closure)
}

@warn_unused_result
public func async<V>(observers: [TaskObserver<V>], closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return NonFailableTask<V>(observers: observers, closure: closure)
}


// MARK: - await

public func await<V>(@noescape closure: () -> Task<V>) throws -> V {
    return try closure().waitForCompletionAndReturnValue()
}

public func await<V>(task: Task<V>) throws -> V {
    return try task.waitForCompletionAndReturnValue()
}

public func runTask<V>(task: Task<V>, queue: dispatch_queue_t = _defaultRunTaskQueue, completionQueue: dispatch_queue_t = _defaultRunTaskCompletionQueue, completion completionHandler: ((V!, ErrorType?) -> Void)? = nil) {
    dispatch_async(queue) {
        do {
            let value = try task.waitForCompletionAndReturnValue()
            
            if let completionHandler = completionHandler {
                dispatch_async(completionQueue) {
                    completionHandler(value, nil)
                }
            }
        }
        catch let error {
            if let completionHandler = completionHandler {
                dispatch_async(completionQueue) {
                    completionHandler(nil, error)
                }
            }
        }
    }
}


// MARK: - await - non failable task

public func await<V>(@noescape closure: () -> NonFailableTask<V>) -> V {
    return closure().waitForCompletionAndReturnValue()
}

public func await<V>(task: NonFailableTask<V>) -> V {
    return task.waitForCompletionAndReturnValue()
}

public func runTask<V>(task: NonFailableTask<V>, queue: dispatch_queue_t = _defaultRunTaskQueue, completionQueue: dispatch_queue_t = _defaultRunTaskCompletionQueue, completion completionHandler: ((V) -> Void)? = nil) {
    dispatch_async(queue) {
        let value = task.waitForCompletionAndReturnValue()

        if let completionHandler = completionHandler {
            dispatch_async(completionQueue) {
                completionHandler(value)
            }
        }
    }
}
