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
    init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (Self) -> Void)
}

// MARK: - CancellableTask

public protocol CancellableTask: TaskProtocol {
    var cancelled: Bool { get }
    var cancellationHandler: (() -> Void)? { get set }
    
    func cancel()
}

extension CancellableTask {
    
    @available(*, deprecated)
    public func forwardCancellation(to task: CancellableTask) -> Self {
        self.cancellationHandler = { [weak task] in
            task?.cancel()
        }
        
        return self
    }
    
    @available(*, deprecated)
    public func inheritCancellation(from task: CancellableTask) -> Self {
        task.cancellationHandler = { [weak self] in
            self?.cancel()
        }

        return self
    }

    internal func internalInheritCancellation(from task: CancellableTask) -> Self {
        task.cancellationHandler = { [weak self] in
            self?.cancel()
        }
        
        return self
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
    public func finish() {
        self.finish(with: ())
    }
    
}

// MARK: - ErrorReportingTask

public protocol ErrorReportingTask: TaskProtocol {
    var error: ErrorType? { get }
    func finish(with error: ErrorType)
}

// MARK: - FailableTaskProtocol

public protocol FailableTaskProtocol: CancellableTask, ValueReportingTask, ErrorReportingTask {
    func finish(with value: Self.ValueType!, or error: ErrorType?)
}

extension FailableTaskProtocol {
    
    public func finish(with value: Self.ValueType!, or error: ErrorType?) {
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
    public func forward<T: FailableTaskProtocol where T.ValueType == Self.ValueType>(to task: T, inheritCancellation: Bool = true) {
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
    public func forward<T: NonFailableTaskProtocol where T.ValueType == Self.ValueType>(to task: T) {
        task.waitUntilFinished()
        self.finish(with: task.value)
    }
    
}
