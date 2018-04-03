//
//  TaskAwaiter.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: - queues

fileprivate let taskAwaiterDefaultOperationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.TaskAwaiter"
    queue.qualityOfService = .utility
    queue.maxConcurrentOperationCount = ProcessInfo().activeProcessorCount * 2
    
    return queue
}()

// MARK: - TaskAwaiter

public final class TaskAwaiter<Value> {
    
    public let task: Task<Value>
    
    private var didFinishWithValueClosure: ((Value) -> Void)?
    private var didFinishWithErrorClosure: ((Error) -> Void)?
    private var didCancelClosure: (() -> Void)?
    private var didFinishClosure: (() -> Void)?

    fileprivate init(queue: OperationQueue, task: Task<Value>) {
        //
        self.task = task
        
        //
        queue.addOperation {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    self.didFinishClosure = nil
                    
                    DispatchQueue.main.async {
                        didFinishClosure()
                    }
                }
            }
            
            do {
                try await(task)
                
                if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                    self.didFinishWithValueClosure = nil
                    
                    DispatchQueue.main.async {
                        didFinishWithValueClosure(task.value!)
                    }
                }
            }
            catch let error {
                if error.isUserCancelled {
                    if let didCancelClosure = self.didCancelClosure {
                        self.didCancelClosure = nil
                        
                        DispatchQueue.main.async {
                            didCancelClosure()
                        }
                    }
                }
                else {
                    if let didFinishWithErrorClosure = self.didFinishWithErrorClosure {
                        self.didFinishWithErrorClosure = nil
                        
                        DispatchQueue.main.async {
                            didFinishWithErrorClosure(error)
                        }
                    }
                }
            }
        }
    }
    
    @discardableResult
    public func didFinishWithValue(_ closure: @escaping (Value) -> Void) -> Self {
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
    
    @discardableResult
    public func didFinish(_ closure: @escaping () -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }
    
}

extension Task {
    
    @discardableResult
    public func didFinishWithValue(queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping (Value) -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? taskAwaiterDefaultOperationQueue, task: self).didFinishWithValue(closure)
    }
    
    @discardableResult
    public func didFinishWithError(queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping (Error) -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? taskAwaiterDefaultOperationQueue, task: self).didFinishWithError(closure)
    }
    
    @discardableResult
    public func didCancel(queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping () -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? taskAwaiterDefaultOperationQueue, task: self).didCancel(closure)
    }

    @discardableResult
    public func didFinish(queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping () -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? taskAwaiterDefaultOperationQueue, task: self).didFinish(closure)
    }

}

// MARK: - NonFailableTaskAwaiter

public final class NonFailableTaskAwaiter<Value> {
    
    public let task: NonFailableTask<Value>
    
    private var didFinishWithValueClosure: ((Value) -> Void)?
    private var didFinishClosure: (() -> Void)?
    
    fileprivate init(queue: OperationQueue, task: NonFailableTask<Value>) {
        //
        self.task = task
        
        //
        queue.addOperation {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    self.didFinishClosure = nil
                    
                    DispatchQueue.main.async {
                        didFinishClosure()
                    }
                }
            }
            
            await(task)
            
            if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                self.didFinishWithValueClosure = nil
                
                DispatchQueue.main.async {
                    didFinishWithValueClosure(task.value!)
                }
            }
        }
    }
    
    @discardableResult
    public func didFinishWithValue(_ closure: @escaping (Value) -> Void) -> Self {
        self.didFinishWithValueClosure = closure
        return self
    }
    
    @discardableResult
    public func didFinish(_ closure: @escaping () -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }
    
}

extension NonFailableTask {
    
    @discardableResult
    public func didFinishWithValue(queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping (Value) -> Void) -> NonFailableTaskAwaiter<Value> {
        return NonFailableTaskAwaiter(queue: queue ?? taskAwaiterDefaultOperationQueue, task: self).didFinishWithValue(closure)
    }
    
    @discardableResult
    public func didFinish(queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping () -> Void) -> NonFailableTaskAwaiter<Value> {
        return NonFailableTaskAwaiter(queue: queue ?? taskAwaiterDefaultOperationQueue, task: self).didFinish(closure)
    }
    
}
