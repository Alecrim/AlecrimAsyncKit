//
//  TaskAwaiter.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-26.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

private let _defaultTaskAwaiterQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.TaskAwaiter"
    queue.qualityOfService = .Default
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

public final class NonFailableTaskAwaiter<V> {
    
    public let task: NonFailableTask<V>
    
    private var didFinishClosure: ((NonFailableTask<V>) -> Void)?
    private var didFinishWithValueClosure: ((V) -> Void)?
    
    private init(queue: NSOperationQueue, callbackQueue: NSOperationQueue, task: NonFailableTask<V>) {
        self.task = task
        
        queue.addOperationWithBlock {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    callbackQueue.addOperationWithBlock {
                        didFinishClosure(task)
                    }
                }
            }
            
            await(task)
            
            if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                callbackQueue.addOperationWithBlock {
                    didFinishWithValueClosure(task.value)
                }
            }
        }
    }
    
    public func didFinish(closure: (NonFailableTask<V>) -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }

    public func didFinishWithValue(closure: (V) -> Void) -> Self {
        self.didFinishWithValueClosure = closure
        return self
    }
    
}

public final class TaskAwaiter<V> {
    
    public let task: Task<V>
    
    private var didFinishClosure: ((Task<V>) -> Void)?
    private var didFinishWithValueClosure: ((V) -> Void)?
    private var didFinishWithErrorClosure: ((ErrorType) -> Void)?
    private var didCancelClosure: (() -> Void)?
    
    private init(queue: NSOperationQueue, callbackQueue: NSOperationQueue, task: Task<V>) {
        self.task = task
        
        queue.addOperationWithBlock {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    callbackQueue.addOperationWithBlock {
                        didFinishClosure(task)
                    }
                }
            }
            
            do {
                try await(task)
                
                if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                    callbackQueue.addOperationWithBlock {
                        didFinishWithValueClosure(task.value)
                    }
                }

            }
            catch let error {
                if error.userCancelled {
                    if let didCancelClosure = self.didCancelClosure {
                        callbackQueue.addOperationWithBlock {
                            didCancelClosure()
                        }
                    }
                }
                else {
                    if let didFinishWithErrorClosure = self.didFinishWithErrorClosure {
                        callbackQueue.addOperationWithBlock {
                            didFinishWithErrorClosure(error)
                        }
                    }
                }
            }
        }
    }
    
    public func didFinish(closure: (Task<V>) -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }
    
    public func didFinishWithValue(closure: (V) -> Void) -> Self {
        self.didFinishWithValueClosure = closure
        return self
    }

    public func didFinishWithError(closure: (ErrorType) -> Void) -> Self {
        self.didFinishWithErrorClosure = closure
        return self
    }

    public func didCancel(closure: () -> Void) -> Self {
        self.didCancelClosure = closure
        return self
    }
    
}

// MARK: - helper extensions

extension NonFailableTask {
    
    public func didFinish(queue: NSOperationQueue = _defaultTaskAwaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), closure: (NonFailableTask<V>) -> Void) -> NonFailableTaskAwaiter<V> {
        return NonFailableTaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinish(closure)
    }
    
    public func didFinishWithValue(queue: NSOperationQueue = _defaultTaskAwaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), closure: (V) -> Void) -> NonFailableTaskAwaiter<V> {
        return NonFailableTaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinishWithValue(closure)
    }
    
}

extension Task {

    public func didFinish(queue: NSOperationQueue = _defaultTaskAwaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), closure: (Task<V>) -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinish(closure)
    }
    
    public func didFinishWithValue(queue: NSOperationQueue = _defaultTaskAwaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), closure: (V) -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinishWithValue(closure)
    }

    public func didFinishWithError(queue: NSOperationQueue = _defaultTaskAwaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), closure: (ErrorType) -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinishWithError(closure)
    }
    
    public func didCancel(queue: NSOperationQueue = _defaultTaskAwaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), closure: () -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didCancel(closure)
    }
    
}
