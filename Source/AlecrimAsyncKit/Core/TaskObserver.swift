//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public class TaskObserver<T: TaskType, V where T.ValueType == V> {
    
    internal final var taskWillStartClosure: ((T) -> Void)?
    internal final var taskDidStartClosure: ((T) -> Void)?

    internal final var taskWillFinishClosure: ((T) -> Void)?
    internal final var taskDidFinishClosure: ((T) -> Void)?
    
    internal final var taskDidFinishWithValueClosure: ((T, V) -> Void)?
    
    internal final var taskDidCancelClosure: ((T) -> Void)?
    internal final var taskDidFinishWithErrorClosure: ((T, ErrorType) -> Void)?
    
    public init() {
    }
    
    deinit {
        print("TASKOBSERVER deinit")
    }

    
    public final func taskWillStart(closure: (T) -> Void) -> Self {
        self.taskWillStartClosure = closure
        return self
    }

    public final func taskDidStart(closure: (T) -> Void) -> Self {
        self.taskDidStartClosure = closure
        return self
    }

    public final func taskWillFinish(closure: (T) -> Void) -> Self {
        self.taskWillFinishClosure = closure
        return self
    }

    public final func taskDidFinish(closure: (T) -> Void) -> Self {
        self.taskDidFinishClosure = closure
        return self
    }

    public final func taskDidFinishWithValue(closure: (T, V) -> Void) -> Self {
        self.taskDidFinishWithValueClosure = closure
        return self
    }
    
}

extension TaskObserver where T: FailableTaskType {
    
    public final func taskDidCancel(closure: (T) -> Void) -> Self {
        self.taskDidCancelClosure = closure
        return self
    }
    
    public final func taskDidFinishWithError(closure: (T, ErrorType) -> Void) -> Self {
        self.taskDidFinishWithErrorClosure = closure
        return self
    }
    
}

