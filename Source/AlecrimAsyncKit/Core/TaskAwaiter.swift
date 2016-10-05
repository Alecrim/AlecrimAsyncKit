//
//  TaskAwaiter.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-26.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public final class NonFailableTaskAwaiter<V> {
    
    public let task: NonFailableTask<V>
    
    private var didFinishClosure: ((NonFailableTask<V>) -> Void)?
    private var didFinishWithValueClosure: ((V) -> Void)?
    
    fileprivate init(queue: OperationQueue, callbackQueue: OperationQueue, task: NonFailableTask<V>) {
        self.task = task
        
        // prefer GCD over OperationQueue for main thread dispatching
        let callbackQueueIsMainOperationQueue = (callbackQueue === OperationQueue.main)
        
        func dispatchToCallbackQueue(closure: @escaping () -> Void) {
            if callbackQueueIsMainOperationQueue {
                Queue.taskAwaiterCallbackSerialQueue.async {
                    Queue.mainQueue.sync(execute: closure)
                }
            }
            else {
                callbackQueue.addOperation(closure)
            }
        }

        //
        queue.addOperation {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    dispatchToCallbackQueue {
                        didFinishClosure(task)
                    }
                }
            }
            
            await(task)
            
            if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                dispatchToCallbackQueue {
                    didFinishWithValueClosure(task.value)
                }
            }
        }
    }
    
    @discardableResult
    public func didFinish(_ closure: @escaping (NonFailableTask<V>) -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }

    @discardableResult
    public func didFinishWithValue(_ closure: @escaping (V) -> Void) -> Self {
        self.didFinishWithValueClosure = closure
        return self
    }
    
}

public final class TaskAwaiter<V> {
    
    public let task: Task<V>
    
    private var didFinishClosure: ((Task<V>) -> Void)?
    private var didFinishWithValueClosure: ((V) -> Void)?
    private var didFinishWithErrorClosure: ((Error) -> Void)?
    private var didCancelClosure: (() -> Void)?
    
    fileprivate init(queue: OperationQueue, callbackQueue: OperationQueue, task: Task<V>) {
        self.task = task
        
        // prefer GCD over OperationQueue for main thread dispatching
        let callbackQueueIsMainOperationQueue = (callbackQueue === OperationQueue.main)
        
        func dispatchToCallbackQueue(closure: @escaping () -> Void) {
            if callbackQueueIsMainOperationQueue {
                Queue.taskAwaiterCallbackSerialQueue.async {
                    Queue.mainQueue.sync(execute: closure)
                }
            }
            else {
                callbackQueue.addOperation(closure)
            }
        }
        
        //
        queue.addOperation {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    dispatchToCallbackQueue {
                        didFinishClosure(task)
                    }
                }
            }
            
            do {
                try await(task)
                
                if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                    dispatchToCallbackQueue {
                        didFinishWithValueClosure(task.value)
                    }
                }

            }
            catch let error {
                if error.isUserCancelled {
                    if let didCancelClosure = self.didCancelClosure {
                        dispatchToCallbackQueue {
                            didCancelClosure()
                        }
                    }
                }
                else {
                    if let didFinishWithErrorClosure = self.didFinishWithErrorClosure {
                        dispatchToCallbackQueue {
                            didFinishWithErrorClosure(error)
                        }
                    }
                }
            }
        }
    }
    
    @discardableResult
    public func didFinish(_ closure: @escaping (Task<V>) -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }
    
    @discardableResult
    public func didFinishWithValue(_ closure: @escaping (V) -> Void) -> Self {
        self.didFinishWithValueClosure = closure
        return self
    }

    @discardableResult
    public func didFinishWithError(_ closure: @escaping (Error) -> Void) -> Self {
        self.didFinishWithErrorClosure = closure
        return self
    }

    @discardableResult
    public func didCancel(_ closure: @escaping () -> Void) -> Self {
        self.didCancelClosure = closure
        return self
    }
    
}

// MARK: - helper extensions

extension NonFailableTask {
    
    @discardableResult
    public func didFinish(queue: OperationQueue = Queue.taskAwaiterDefaultOperationQueue, callbackQueue: OperationQueue = OperationQueue.main, closure: @escaping (NonFailableTask<V>) -> Void) -> NonFailableTaskAwaiter<V> {
        return NonFailableTaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinish(closure)
    }
    
    @discardableResult
    public func didFinishWithValue(queue: OperationQueue = Queue.taskAwaiterDefaultOperationQueue, callbackQueue: OperationQueue = OperationQueue.main, closure: @escaping (V) -> Void) -> NonFailableTaskAwaiter<V> {
        return NonFailableTaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinishWithValue(closure)
    }
    
}

extension Task {

    @discardableResult
    public func didFinish(queue: OperationQueue = Queue.taskAwaiterDefaultOperationQueue, callbackQueue: OperationQueue = OperationQueue.main, closure: @escaping (Task<V>) -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinish(closure)
    }
    
    @discardableResult
    public func didFinishWithValue(queue: OperationQueue = Queue.taskAwaiterDefaultOperationQueue, callbackQueue: OperationQueue = OperationQueue.main, closure: @escaping (V) -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinishWithValue(closure)
    }

    @discardableResult
    public func didFinishWithError(queue: OperationQueue = Queue.taskAwaiterDefaultOperationQueue, callbackQueue: OperationQueue = OperationQueue.main, closure: @escaping (Error) -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didFinishWithError(closure)
    }
    
    @discardableResult
    public func didCancel(queue: OperationQueue = Queue.taskAwaiterDefaultOperationQueue, callbackQueue: OperationQueue = OperationQueue.main, closure: @escaping () -> Void) -> TaskAwaiter<V> {
        return TaskAwaiter(queue: queue, callbackQueue: callbackQueue, task: self).didCancel(closure)
    }
    
}
