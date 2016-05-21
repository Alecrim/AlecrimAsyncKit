//
//  Protocols.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-25.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol TaskProtocol: class {
    func waitUntilFinished()
}

internal protocol InitializableTask: TaskProtocol {
    init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (Self) -> Void)
}

public protocol CancellableTask: TaskProtocol {
    var cancelled: Bool { get }
    var cancellationHandler: (() -> Void)? { get set }
    
    func cancel()
}

public protocol ValueReportingTask: TaskProtocol {
    associatedtype ValueType
    
    var value: Self.ValueType! { get }
    func finish(with value: Self.ValueType)
}

public protocol ErrorReportingTask: TaskProtocol {
    var error: ErrorType? { get }
    func finish(with error: ErrorType)
}

public protocol FailableTaskProtocol: CancellableTask, ValueReportingTask, ErrorReportingTask {
    func finish(with value: Self.ValueType!, or error: ErrorType?)
}

public protocol NonFailableTaskProtocol: ValueReportingTask {

}

// MARK: -

extension CancellableTask {
    
    public func forwardCancellation(to task: CancellableTask) -> Self {
        self.cancellationHandler = { [weak task] in
            task?.cancel()
        }
        
        return self
    }
    
    public func inheritCancellation(from task: CancellableTask) -> Self {
        task.forwardCancellation(to: self)
        
        return self
    }

}

// MARK: -

extension ValueReportingTask where Self.ValueType == Void {
    
    public func finish() {
        self.finish(with: ())
    }
    
}

// MARK: -

extension FailableTaskProtocol {
    
    public func finish(with value: Self.ValueType!, or error: ErrorType?) {
        if let error = error {
            self.finish(with: error)
        }
        else {
            self.finish(with: value)
        }
    }
    
    public func `continue`<T: FailableTaskProtocol where T.ValueType == Self.ValueType>(with task: T, inheritCancellation: Bool = true) {
        if inheritCancellation {
            task.inheritCancellation(from: self)
        }
        
        task.waitUntilFinished()
        self.finish(with: task.value, or: task.error)
    }
    
}

// MARK: -

extension NonFailableTaskProtocol {
    
    public func `continue`<T: NonFailableTaskProtocol where T.ValueType == Self.ValueType>(with task: T) {
        task.waitUntilFinished()
        self.finish(with: task.value)
    }
    
}
