//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: - Task

public final class Task<V, E: Swift.Error> {

    // MARK: - Result

    // Result
    private var _result: Swift.Result<V, E>?
    private var result: Swift.Result<V, E>? {
        get {
            self.lock(); defer { self.unlock() }
            return self._result
        }
        set {
            self.lock(); defer { self.unlock() }

            // We can set the result once
            if self._result == nil {
                self._result = newValue
            }
        }
    }

    // Result Lock
    private var _lock = os_unfair_lock_s()
    private func lock() { os_unfair_lock_lock(&self._lock) }
    private func unlock() { os_unfair_lock_unlock(&self._lock) }

    // MARK: - Work Item

    // Work Item
    private var workItem: DispatchWorkItem?

    // MARK: - Initializers

    internal convenience init() {
        self.init(result: nil)
    }

    internal convenience init(value: V) {
        self.init(result: .success(value))
    }

    fileprivate init(result: Swift.Result<V, E>?) {
        self.result = result
    }

    internal convenience init(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping (Task<V, E>) -> Void) {
        self.init(result: nil)

        let block: () -> Void = {
            closure(self)
        }

        self.workItem = DispatchWorkItem(qos: qos, flags: flags, block: block)
    }

    // MARK: - Finishing

    public func finish(with value: V) {
        self.result = .success(value)
    }

}

extension Task where E == Swift.Error {

    // Initializers

    internal convenience init(error: E) {
        self.init(result: .failure(error))
    }

    internal convenience init(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping () throws -> V) {
        self.init(result: nil)

        let block: () -> Void = {
            self.result = Swift.Result(catching: closure)
        }

        self.workItem = DispatchWorkItem(qos: qos, flags: flags, block: block)
    }

    // MARK: - Executing

    internal func execute(on queue: DispatchQueue) throws -> V {
        func getValue(from result: Swift.Result<V, E>) throws -> V {
            switch result {
            case let .success(value):
                return value

            case let .failure(error):
                throw error
            }
        }

        if let result = self.result {
            return try getValue(from: result)
        }
        else if let workItem = self.workItem {
            queue.async(execute: workItem)
            workItem.wait()

            guard let result = self.result else {
                fatalError()
            }

            return try getValue(from: result)
        }
        else {
            fatalError()
        }
    }

    // MARK: - Cancelling

    /// A Boolean value that indicates whether the `Task` has been cancelled.
    public var isCancelled: Bool {
        guard let result = self.result else {
            return false
        }

        switch result {
        case let .failure(error):
            return error.isUserCancelled

        default:
            return false
        }
    }

    public func cancel() {
        self.result = .failure(NSError.userCancelled)
        self.workItem?.cancel()
    }

    // MARK: - Finishing

    public func finish(with error: E) {
        self.result = .failure(error)
    }

    public func finish(with value: V?, or error: E?) {
        precondition(value != nil || error != nil)

        if let error = error {
            self.finish(with: error)
        }
        else if let value = value {
            self.finish(with: value)
        }
        else {
            fatalError()
        }
    }

    public func finish(with result: Swift.Result<V, E>) {
        self.result = result
    }

}

extension Task where E == Never {

    // Initializers

    @available(*, unavailable)
    internal convenience init(error: E) {
        fatalError()
    }

    internal convenience init(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping () -> V) {
        self.init(result: nil)

        let block: () -> Void = {
            self.result = .success(closure())
        }

        self.workItem = DispatchWorkItem(qos: qos, flags: flags, block: block)
    }

    // MARK: - Cancelling

    @available(*, unavailable)
    public var isCancelled: Bool {
        fatalError()
    }


    @available(*, unavailable)
    public func cancel() {
        fatalError()
    }

    // MARK: - Executing

    internal func execute(on queue: DispatchQueue) -> V {
        func getValue(from result: Swift.Result<V, E>) throws -> V {
            switch result {
            case let .success(value):
                return value

            case let .failure(error):
                throw error
            }
        }

        if let result = self.result {
            return try! getValue(from: result)
        }
        else if let workItem = self.workItem {
            queue.async(execute: workItem)
            workItem.wait()

            guard let result = self.result else {
                fatalError()
            }

            return try! getValue(from: result)
        }
        else {
            fatalError()
        }
    }

}

extension Task where V == Void {

    public func finish() {
        self.finish(with: ())
    }

}
