//
//  TaskAwaiter.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

private let _taskAwaiterDefaultDispatchQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.Default", qos: .utility, attributes: .concurrent)


// MARK: - TaskAwaiter

public final class TaskAwaiter<V, E: Swift.Error> {
    fileprivate let queue: DispatchQueue
    fileprivate let callbackQueue: DispatchQueue

    public let task: Task<V, E>

    fileprivate var thenClosure: ((V) -> Void)?
    fileprivate var catchClosure: ((E) -> Void)?
    fileprivate var cancelClosure: (() -> Void)?
    fileprivate var finallyClosure: (() -> Void)?

    fileprivate init(queue: DispatchQueue, callbackQueue: DispatchQueue, task: Task<V, E>) {
        self.queue = queue
        self.callbackQueue = callbackQueue
        self.task = task
    }
}

// MARK: -

extension TaskAwaiter where E == Error {

    @discardableResult
    public func then(_ closure: @escaping (V) -> Void) -> Self {
        self.thenClosure = closure
        return self
    }

    @discardableResult
    public func `catch`(_ closure: @escaping (E) -> Void) -> Self {
        self.catchClosure = closure
        return self
    }

    @discardableResult
    public func cancelled(_ closure: @escaping () -> Void) -> Self {
        self.cancelClosure = closure
        return self
    }

    @discardableResult
    public func finally(_ closure: @escaping () -> Void) -> Self {
        self.finallyClosure = closure
        return self
    }

}

extension TaskAwaiter where E == Never {

    @discardableResult
    public func then(_ closure: @escaping (V) -> Void) -> Self {
        self.thenClosure = closure
        return self
    }

}

// MARK: -

extension TaskAwaiter where E == Error {

    fileprivate func enqueue() {
        self.queue.async {
            defer {
                if let finallyClosure = self.finallyClosure {
                    self.finallyClosure = nil

                    self.callbackQueue.async {
                        finallyClosure()
                    }
                }
            }

            do {
                let value = try await(self.task)

                if let thenClosure = self.thenClosure {
                    self.callbackQueue.async {
                        thenClosure(value)
                        self.thenClosure = nil
                    }
                }
            }
            catch {
                if error.isUserCancelled {
                    if let cancelClosure = self.cancelClosure {
                        self.callbackQueue.async {
                            cancelClosure()
                            self.cancelClosure = nil
                        }
                    }
                }
                else {
                    if let catchClosure = self.catchClosure {
                        self.callbackQueue.async {
                            catchClosure(error)
                            self.catchClosure = nil
                        }
                    }
                }
            }
        }
    }

}

extension TaskAwaiter where E == Never {

    fileprivate func enqueue() {
        self.queue.async {
            let value = await(self.task)

            if let thenClosure = self.thenClosure {
                self.callbackQueue.async {
                    thenClosure(value)
                    self.thenClosure = nil
                }
            }
        }
    }

}

// MARK: -

extension Task where E == Error {

    @discardableResult
    public func then(on queue: DispatchQueue? = nil, callbackQueue: DispatchQueue? = nil, closure: @escaping (V) -> Void) -> TaskAwaiter<V, E> {
        let ta = TaskAwaiter(queue: queue ?? _taskAwaiterDefaultDispatchQueue, callbackQueue: callbackQueue ?? DispatchQueue.main, task: self).then(closure)
        ta.enqueue()

        return ta
    }

    @discardableResult
    public func `catch`(on queue: DispatchQueue? = nil, callbackQueue: DispatchQueue? = nil, closure: @escaping (E) -> Void) -> TaskAwaiter<V, E> {
        let ta = TaskAwaiter(queue: queue ?? _taskAwaiterDefaultDispatchQueue, callbackQueue: callbackQueue ?? DispatchQueue.main, task: self).catch(closure)
        ta.enqueue()

        return ta
    }

    @discardableResult
    public func cancelled(on queue: DispatchQueue? = nil, callbackQueue: DispatchQueue? = nil, closure: @escaping () -> Void) -> TaskAwaiter<V, E> {
        let ta = TaskAwaiter(queue: queue ?? _taskAwaiterDefaultDispatchQueue, callbackQueue: callbackQueue ?? DispatchQueue.main, task: self).cancelled(closure)
        ta.enqueue()

        return ta
    }

    @discardableResult
    public func finally(on queue: DispatchQueue? = nil, callbackQueue: DispatchQueue? = nil, closure: @escaping () -> Void) -> TaskAwaiter<V, E> {
        let ta = TaskAwaiter(queue: queue ?? _taskAwaiterDefaultDispatchQueue, callbackQueue: callbackQueue ?? DispatchQueue.main, task: self).finally(closure)
        ta.enqueue()

        return ta
    }

}

extension Task where E == Never {

    @discardableResult
    public func then(on queue: DispatchQueue? = nil, callbackQueue: DispatchQueue? = nil, closure: @escaping (V) -> Void) -> TaskAwaiter<V, E> {
        let ta = TaskAwaiter(queue: queue ?? _taskAwaiterDefaultDispatchQueue, callbackQueue: callbackQueue ?? DispatchQueue.main, task: self).then(closure)
        ta.enqueue()

        return ta
    }

}
