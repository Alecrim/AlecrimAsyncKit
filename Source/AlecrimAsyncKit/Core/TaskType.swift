//
//  TaskType.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-25.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol TaskType: class {
    func waitUntilFinished()
}

internal protocol InitializableTaskType: TaskType {
    init(conditions: [TaskCondition]?, observers: [TaskObserverType]?, asynchronous: Bool, closure: (Self) -> Void)
}

public protocol CancellableTaskType: TaskType {
    var cancelled: Bool { get }
    var cancellationHandler: (() -> Void)? { get set }
    
    func cancel()
}

public protocol TaskWithErrorType: TaskType {
    var error: ErrorType? { get }
    func finish(with error: ErrorType)
}

public protocol TaskWithValueType: TaskType {
    associatedtype ValueType
    
    var value: Self.ValueType! { get }
    func finish(with value: Self.ValueType)
}

public protocol FailableTaskType: CancellableTaskType, TaskWithValueType, TaskWithErrorType {
    func finish(with value: Self.ValueType!, or error: ErrorType?)
}

public protocol NonFailableTaskType: TaskWithValueType {

}

// MARK: -

extension CancellableTaskType {
    
    public func forwardCancellation(to task: CancellableTaskType) -> Self {
        self.cancellationHandler = { [weak task] in
            task?.cancel()
        }
        
        return self
    }
    
    public func inheritCancellation(from task: CancellableTaskType) -> Self {
        task.forwardCancellation(to: self)
        
        return self
    }

}

// MARK: -

extension TaskWithValueType where Self.ValueType == Void {
    
    public func finish() {
        self.finish(with: ())
    }
    
}

// MARK: -

extension FailableTaskType {
    
    public func finish(with value: Self.ValueType!, or error: ErrorType?) {
        if let error = error {
            self.finish(with: error)
        }
        else {
            self.finish(with: value)
        }
    }
    
    public func `continue`<T: FailableTaskType where T.ValueType == Self.ValueType>(withTask task: T, inheritCancellation: Bool = true) {
        if inheritCancellation {
            task.inheritCancellation(from: self)
        }
        
        task.waitUntilFinished()
        self.finish(with: task.value, or: task.error)
    }
    
}

// MARK: -

extension NonFailableTaskType {
    
    public func `continue`<T: NonFailableTaskType where T.ValueType == Self.ValueType>(withTask task: T) {
        task.waitUntilFinished()
        self.finish(with: task.value)
    }
    
}
