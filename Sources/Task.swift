//
//  Task.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: - Task

public final class Task<V, E: Error> {

    // MARK: Result

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

    // MARK: Work Item

    // Work Item
    private var workItem: DispatchWorkItem?

    // Dispatch Group (needed when used with closures without immediate return and `finish` methods)
    private var _dispatchGroup: DispatchGroup?

    // Result and Dispatch Group Lock
    private var _lock = os_unfair_lock_s()
    private func lock() { os_unfair_lock_lock(&self._lock) }
    private func unlock() { os_unfair_lock_unlock(&self._lock) }

    // MARK: Initializers

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

        // will need to leave using a `finish` method
        self.enterDispatchGroup()

        //
        let block: () -> Void = {
            Thread.current.cancellableTaskBox = CancellableTaskBox(self as? CancellableTask)
            closure(self)
        }

        //
        self.workItem = DispatchWorkItem(qos: qos, flags: flags, block: block)
    }

    // MARK: Executing

    internal func execute(on queue: DispatchQueue) {
        if let _ = self.result {
            return
        }
        else if let workItem = self.workItem {
            Thread.current.cancellableTaskBox?.value?.cancellation += { [weak self] in
                (self as? CancellableTask)?.cancel()
            }

            queue.async(execute: workItem)
        }
        else {
            fatalError()
        }
    }

    // MARK: Cancelling

    fileprivate private(set) lazy var _cancellation = Cancellation()

    // MARK: Finishing

    public func finish(with value: V) {
        self._finish(with: .success(value))
    }

    fileprivate func _finish(with result: Swift.Result<V, E>) {
        self.result = result
        self.leaveDispatchGroup()
    }

    // MARK: Dispatch Group Helpers
    private func enterDispatchGroup() {
        self.lock(); defer { self.unlock() }

        self._dispatchGroup = DispatchGroup()
        self._dispatchGroup?.enter()
    }

    private func leaveDispatchGroup() {
        self.lock(); defer { self.unlock() }

        if let dispatchGroup = self._dispatchGroup {
            self._dispatchGroup = nil
            dispatchGroup.leave()
        }
    }

    private func waitDispatchGroup() {
        var dispatchGroup: DispatchGroup?

        do {
            self.lock(); defer { self.unlock() }
            dispatchGroup = self._dispatchGroup
        }

        dispatchGroup?.wait()
    }

}

// MARK: - Failable Task

extension Task where E == Swift.Error {

    // MARK: Initializers

    internal convenience init(error: E) {
        self.init(result: .failure(error))
    }

    internal convenience init(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping () throws -> V) {
        self.init(result: nil)

        let block: () -> Void = {
            Thread.current.cancellableTaskBox = CancellableTaskBox(self)
            self._finish(with: Swift.Result(catching: closure))
        }

        self.workItem = DispatchWorkItem(qos: qos, flags: flags, block: block)
    }

    // MARK: Awaiting

    internal func await() throws -> V {
        if let result = self.result {
            return try result.get()
        }
        else if let workItem = self.workItem {
            workItem.wait()
            waitDispatchGroup()

            guard let result = self.result else {
                fatalError("Task may be not properly finished. See `Task.finish(with: _)`.")
            }

            return try result.get()
        }
        else {
            fatalError()
        }
    }

    // MARK: Cancelling

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

    public var cancellation: Cancellation {
        return self._cancellation
    }


    //

    public func cancel() {
        self._finish(with: .failure(NSError.userCancelled))

        if let workItem = self.workItem {
            self.cancellation.run(after: workItem)
            workItem.cancel() // fired by workItem notify, runs on a private concurrent queue
        }
        else {
            self.cancellation.run() // runs immediately on current queue
        }
    }

    // MARK: Finishing

    public func finish(with error: E) {
        self._finish(with: .failure(error))
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
        self._finish(with: result)
    }

}

// MARK: - Non Failable Task

extension Task where E == Never {

    // MARK: Initializers

    internal convenience init(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], closure: @escaping () -> V) {
        self.init(result: nil)

        let block: () -> Void = {
            Thread.current.cancellableTaskBox = nil
            self._finish(with: .success(closure()))
        }

        self.workItem = DispatchWorkItem(qos: qos, flags: flags, block: block)
    }

    // MARK: Executing

    internal func await() -> V {
        if let result = self.result {
            return try! result.get()
        }
        else if let workItem = self.workItem {
            workItem.wait()
            waitDispatchGroup()

            guard let result = self.result else {
                fatalError()
            }

            return try! result.get()
        }
        else {
            fatalError()
        }
    }

}

// MARK: - Void Value Task

extension Task where V == Void {

    public func finish() {
        self.finish(with: ())
    }

}

// MARK: - CancellableTask

fileprivate protocol CancellableTask: AnyObject {
    var cancellation: Cancellation { get }
    func cancel()
}

extension Task: CancellableTask where E == Error {

}

extension Thread {

    fileprivate var cancellableTaskBox: CancellableTaskBox? {
        get {
            return self.threadDictionary["___AAK_TASK"] as? CancellableTaskBox
        }
        set {
            self.threadDictionary["___AAK_TASK"] = newValue
        }
    }

}

fileprivate struct CancellableTaskBox {
    fileprivate weak var value: CancellableTask?

    fileprivate init(_ value: CancellableTask?) {
        self.value = value
    }
}
