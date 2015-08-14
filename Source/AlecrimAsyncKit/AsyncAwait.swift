//
//  AsyncAwait.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private let executeOperationQueue: NSOperationQueue = {
    let oq = NSOperationQueue()
    oq.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    oq.qualityOfService = .Default
    
    return oq
    }()


// MARK: - async

@warn_unused_result
public func async<V>(closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(conditions: nil, observers: nil, closure: closure)
}

@warn_unused_result
public func async<V>(conditions: [Condition], closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(conditions: conditions, observers: nil, closure: closure)
}

@warn_unused_result
public func async<V>(observers: [Observer<V>], closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(conditions: nil, observers: observers, closure: closure)
}

@warn_unused_result
public func async<V>(conditions: [Condition], observers: [Observer<V>], closure: (Task<V>) -> Void) -> Task<V> {
    return Task<V>(conditions: conditions, observers: observers, closure: closure)
}

// MARK: - async - non failable task

@warn_unused_result
public func async<V>(closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return NonFailableTask<V>(observers: nil, closure: closure)
}

@warn_unused_result
public func async<V>(observers: [Observer<V>], closure: (NonFailableTask<V>) -> Void) -> NonFailableTask<V> {
    return NonFailableTask<V>(observers: observers, closure: closure)
}


// MARK: - await

public func await<V>(@noescape closure: () -> Task<V>) throws -> V {
    return try await(closure())
}

public func await<V>(task: Task<V>) throws -> V {
    task.wait()
    
    if let error = task.error {
        throw error
    }
    else {
        return task.value
    }
}

public func execute<V>(task: Task<V>, queue: NSOperationQueue = executeOperationQueue, completionQueue: NSOperationQueue = NSOperationQueue.mainQueue(), completion completionHandler: ((V!, ErrorType?) -> Void)? = nil) {
    queue.addOperationWithBlock {
        do {
            let value = try await(task)
            
            if let completionHandler = completionHandler {
                completionQueue.addOperationWithBlock {
                    completionHandler(value, nil)
                }
            }
        }
        catch let error {
            if let completionHandler = completionHandler {
                completionQueue.addOperationWithBlock {
                    completionHandler(nil, error)
                }
            }
        }
    }
}


// MARK: - await - non failable task

public func await<V>(@noescape closure: () -> NonFailableTask<V>) -> V {
    return await(closure())
}

public func await<V>(task: NonFailableTask<V>) -> V {
    task.wait()
    
    if let _ = task.error {
        fatalError("A non failable task cannot finish with an error nor can be cancelled.")
    }
    else {
        return task.value
    }
}

public func execute<V>(task: NonFailableTask<V>, queue: NSOperationQueue = executeOperationQueue, completionQueue: NSOperationQueue = NSOperationQueue.mainQueue(), completion completionHandler: ((V) -> Void)? = nil) {
    queue.addOperationWithBlock {
        let value = await(task)

        if let completionHandler = completionHandler {
            completionQueue.addOperationWithBlock {
                completionHandler(value)
            }
        }
    }
}
