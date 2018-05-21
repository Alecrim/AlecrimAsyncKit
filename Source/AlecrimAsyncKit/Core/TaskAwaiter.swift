//
//  TaskAwaiter.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: - TaskAwaiter

public final class TaskAwaiter<Value> {
    
    public let task: Task<Value>
    
    private var didFinishWithValueClosure: ((Value) -> Void)?
    private var didFinishWithErrorClosure: ((Error) -> Void)?
    private var didCancelClosure: (() -> Void)?
    private var didFinishClosure: (() -> Void)?

    fileprivate init(queue: OperationQueue, callbackQueue: OperationQueue, task: Task<Value>) {
        //
        self.task = task
        
        //
        queue.addOperation {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    self.didFinishClosure = nil
                    
                    callbackQueue.addOperation {
                        didFinishClosure()
                    }
                }
            }
            
            do {
                try await(task)
                
                if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                    callbackQueue.addOperation {
                        didFinishWithValueClosure(task.value!)
                        self.didFinishWithValueClosure = nil
                    }
                }
            }
            catch let error {
                if error.isUserCancelled {
                    if let didCancelClosure = self.didCancelClosure {
                        callbackQueue.addOperation {
                            didCancelClosure()
                            self.didCancelClosure = nil
                        }
                    }
                }
                else {
                    if let didFinishWithErrorClosure = self.didFinishWithErrorClosure {
                        callbackQueue.addOperation {
                            didFinishWithErrorClosure(error)
                            self.didFinishWithErrorClosure = nil
                        }
                    }
                }
            }
        }
    }
    
    @discardableResult
    public func then(_ closure: @escaping (Value) -> Void) -> Self {
        self.didFinishWithValueClosure = closure
        return self
    }
    
    @discardableResult
    public func `catch`(_ closure: @escaping (Error) -> Void) -> Self {
        self.didFinishWithErrorClosure = closure
        return self
    }
    
    @discardableResult
    public func cancelled(_ closure: @escaping () -> Void) -> Self {
        self.didCancelClosure = closure
        return self
    }
    
    @discardableResult
    public func finally(_ closure: @escaping () -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }
    
}

extension Task {
    
    @discardableResult
    public func then(on queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping (Value) -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? Queue.taskAwaiterDefaultOperationQueue, callbackQueue: callbackQueue ?? OperationQueue.main, task: self).then(closure)
    }
    
    @discardableResult
    public func `catch`(on queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping (Error) -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? Queue.taskAwaiterDefaultOperationQueue, callbackQueue: callbackQueue ?? OperationQueue.main, task: self).catch(closure)
    }
    
    @discardableResult
    public func cancelled(on queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping () -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? Queue.taskAwaiterDefaultOperationQueue, callbackQueue: callbackQueue ?? OperationQueue.main, task: self).cancelled(closure)
    }

    @discardableResult
    public func finally(on queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping () -> Void) -> TaskAwaiter<Value> {
        return TaskAwaiter(queue: queue ?? Queue.taskAwaiterDefaultOperationQueue, callbackQueue: callbackQueue ?? OperationQueue.main, task: self).finally(closure)
    }

}

// MARK: - NonFailableTaskAwaiter

public final class NonFailableTaskAwaiter<Value> {
    
    public let task: NonFailableTask<Value>
    
    private var didFinishWithValueClosure: ((Value) -> Void)?
    private var didFinishClosure: (() -> Void)?
    
    fileprivate init(queue: OperationQueue, callbackQueue: OperationQueue, task: NonFailableTask<Value>) {
        //
        self.task = task
        
        //
        queue.addOperation {
            defer {
                if let didFinishClosure = self.didFinishClosure {
                    callbackQueue.addOperation {
                        didFinishClosure()
                        self.didFinishClosure = nil
                    }
                }
            }
            
            await(task)
            
            if let didFinishWithValueClosure = self.didFinishWithValueClosure {
                callbackQueue.addOperation {
                    didFinishWithValueClosure(task.value!)
                    self.didFinishWithValueClosure = nil
                }
            }
        }
    }
    
    @discardableResult
    public func then(_ closure: @escaping (Value) -> Void) -> Self {
        self.didFinishWithValueClosure = closure
        return self
    }
    
    @discardableResult
    public func finally(_ closure: @escaping () -> Void) -> Self {
        self.didFinishClosure = closure
        return self
    }
    
}

extension NonFailableTask {
    
    @discardableResult
    public func then(on queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping (Value) -> Void) -> NonFailableTaskAwaiter<Value> {
        return NonFailableTaskAwaiter(queue: queue ?? Queue.taskAwaiterDefaultOperationQueue, callbackQueue: callbackQueue ?? OperationQueue.main, task: self).then(closure)
    }
    
    @discardableResult
    public func finally(on queue: OperationQueue? = nil, callbackQueue: OperationQueue? = nil, closure: @escaping () -> Void) -> NonFailableTaskAwaiter<Value> {
        return NonFailableTaskAwaiter(queue: queue ?? Queue.taskAwaiterDefaultOperationQueue, callbackQueue: callbackQueue ?? OperationQueue.main, task: self).finally(closure)
    }
    
}
