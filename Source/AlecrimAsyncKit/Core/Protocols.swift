//
//  Protocols.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-25.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: - TaskProtocol

public protocol TaskProtocol: class {
    func waitUntilFinished()
}

// MARK: - InitializableTask

internal protocol InitializableTask: TaskProtocol {
    init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: @escaping (Self) -> Void)
}

// MARK: - CancellableTask

public protocol CancellableTask: TaskProtocol {
    var isCancelled: Bool { get }
    var cancellationHandler: (() -> Void)? { get set }
    
    func cancel()
}

extension CancellableTask {
    
    @available(*, deprecated)
    @discardableResult
    public final func forwardCancellation(to task: CancellableTask) -> Self {
        self.cancellationHandler = { [weak task] in
            task?.cancel()
        }
        
        return self
    }
    
    @available(*, deprecated)
    @discardableResult
    public final func inheritCancellation(from task: CancellableTask) -> Self {
        task.cancellationHandler = { [weak self] in
            self?.cancel()
        }

        return self
    }

    internal final func internalInheritCancellation(from task: CancellableTask) {
        task.cancellationHandler = { [weak self] in
            self?.cancel()
        }
    }

}

// MARK: - ValueReportingTask

public protocol ValueReportingTask: TaskProtocol {
    associatedtype ValueType
    
    var value: Self.ValueType! { get }
    func finish(with value: Self.ValueType)
}

extension ValueReportingTask where Self.ValueType == Void {
    
    /// Causes the receiver to treat the task as finished.
    public final func finish() {
        self.finish(with: ())
    }
    
}

// MARK: - ErrorReportingTask

public protocol ErrorReportingTask: TaskProtocol {
    var error: Error? { get }
    func finish(with error: Error)
}

// MARK: - FailableTaskProtocol

public protocol FailableTaskProtocol: CancellableTask, ValueReportingTask, ErrorReportingTask {
    func finish(with value: Self.ValueType!, or error: Error?)
}

extension FailableTaskProtocol {
    
    public final func finish(with value: Self.ValueType!, or error: Error?) {
        if let error = error {
            self.finish(with: error)
        }
        else {
            self.finish(with: value)
        }
    }
    
    /// Forwards the execution to other task and finishes the receiver when that task is finished.
    ///
    /// - parameter task: The task the execution is forward to.
    public final func forward<T: FailableTaskProtocol>(to task: T, inheritCancellation: Bool = true) where T.ValueType == Self.ValueType {
        if inheritCancellation {
            task.internalInheritCancellation(from: self)
        }
        
        task.waitUntilFinished()
        self.finish(with: task.value, or: task.error)
    }
    
}

// MARK: - NonFailableTaskProtocol

public protocol NonFailableTaskProtocol: ValueReportingTask {

}

extension NonFailableTaskProtocol {
    
    /// Forwards the execution to other non failable task and finishes the receiver when that task is finished.
    ///
    /// - parameter task: The non failable task the execution is forward to.
    public final func forward<T: NonFailableTaskProtocol>(to task: T) where T.ValueType == Self.ValueType {
        task.waitUntilFinished()
        self.finish(with: task.value)
    }
    
}
