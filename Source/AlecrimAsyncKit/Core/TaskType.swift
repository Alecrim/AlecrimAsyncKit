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
    init(conditions: [TaskCondition]?, observers: [TaskObserver]?, asynchronous: Bool, closure: (Self) -> Void)
}

public protocol CancellableTaskType: TaskType {
    var cancelled: Bool { get }
    var cancellationHandler: (() -> Void)? { get set }
    
    func cancel()
}

public protocol TaskWithErrorType: TaskType {
    var error: ErrorType? { get }
    func finishWith(error error: ErrorType)
}

public protocol TaskWithValueType: TaskType {
    typealias ValueType
    
    var value: Self.ValueType! { get }
    func finishWith(value value: Self.ValueType)
}

public protocol FailableTaskType: CancellableTaskType, TaskWithValueType, TaskWithErrorType {
    func finishWith(value value: Self.ValueType!, error: ErrorType?)
}

public protocol NonFailableTaskType: TaskWithValueType {

}

// MARK: -

extension CancellableTaskType {
    
    public func forwardCancellationToTask(task: CancellableTaskType) -> Self {
        self.cancellationHandler = { [weak task] in
            task?.cancel()
        }
        
        return self
    }
    
    public func inheritCancellationFromTask(task: CancellableTaskType) -> Self {
        task.forwardCancellationToTask(self)
        
        return self
    }

}

// MARK: -

extension TaskWithValueType where Self.ValueType == Void {
    
    public func finish() {
        self.finishWith(value: ())
    }
    
}

// MARK: -

extension FailableTaskType {
    
    public func finishWith(value value: Self.ValueType!, error: ErrorType?) {
        if let error = error {
            self.finishWith(error: error)
        }
        else {
            self.finishWith(value: value)
        }
    }
    
    public func continueWithTask<T: FailableTaskType where T.ValueType == Self.ValueType>(task: T) {
        task.waitUntilFinished()
        self.finishWith(value: task.value, error: task.error)
    }
    
}

// MARK: -

extension NonFailableTaskType {
    
    public func continueWithTask<T: NonFailableTaskType where T.ValueType == Self.ValueType>(task: T) {
        task.waitUntilFinished()
        self.finishWith(value: task.value)
    }
    
}
