//
//  TaskType.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-25.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol BaseTaskType: class {
    typealias ValueType
    
    var finished: Bool { get }
    
    var value: Self.ValueType! { get }
    
    var progress: NSProgress? { get set }
    
    func finishWithValue(value: Self.ValueType)
    
}

public protocol TaskType: BaseTaskType {
    
    init(closure: (Self) -> Void)
    
}


public protocol NonFailableTaskType: TaskType {
    
}

public protocol FailableTaskType: TaskType {
    
    var error: ErrorType? { get }
    
    var cancelled: Bool { get }
    
    func cancel()
    
    func finishWithValue(value: Self.ValueType!, error: ErrorType?)
    func finishWithError(error: ErrorType)
    
}

extension TaskType where Self.ValueType == Void {
    
    public func finish() {
        self.finishWithValue(())
    }
    
}

extension NonFailableTaskType {
    
    public func continueWithTask<T: NonFailableTaskType where T.ValueType == Self.ValueType>(task: T) {
        try! (task as! NonFailableTask<Self.ValueType>).wait()
        self.finishWithValue(task.value)
    }
    
}

extension FailableTaskType {
    
    public func continueWithTask<T: TaskType where T.ValueType == Self.ValueType>(task: T) {
        do {
            try (task as! Task<Self.ValueType>).wait()
            self.finishWithValue(task.value)
        }
        catch let error {
            self.finishWithError(error)
        }
    }
    
}
