//
//  TaskWaiter.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-26.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

private let _defaultTaskWaiterQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.TaskWaiter"
    queue.qualityOfService = .Default
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
}()

public final class NonFailableTaskWaiter<V> {
    
    public let task: NonFailableTask<V>
    
    private var didFinishClosure: ((NonFailableTask<V>) -> Void)?
    private var didFinishWithValueClosure: ((V) -> Void)?
    
    public init(queue: NSOperationQueue = _defaultTaskWaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), _ task: NonFailableTask<V>) {
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

public final class TaskWaiter<V> {
    
    public let task: Task<V>
    
    private var didFinishClosure: ((Task<V>) -> Void)?
    private var didFinishWithValueClosure: ((V) -> Void)?
    private var didFinishWithErrorClosure: ((ErrorType) -> Void)?
    private var didCancelClosure: (() -> Void)?
    
    public init(queue: NSOperationQueue = _defaultTaskWaiterQueue, callbackQueue: NSOperationQueue = NSOperationQueue.mainQueue(), task: Task<V>) {
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
