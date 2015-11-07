//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public class TaskObserver {
    
    internal final var taskWillStartClosure: ((TaskType) -> Void)?
    internal final var taskDidStartClosure: ((TaskType) -> Void)?

    internal final var taskWillFinishClosure: ((TaskType) -> Void)?
    internal final var taskDidFinishClosure: ((TaskType) -> Void)?
    
    public init() {
    }
    
    public final func taskWillStart(closure: (TaskType) -> Void) -> Self {
        self.taskWillStartClosure = closure
        return self
    }

    public final func taskDidStart(closure: (TaskType) -> Void) -> Self {
        self.taskDidStartClosure = closure
        return self
    }

    public final func taskWillFinish(closure: (TaskType) -> Void) -> Self {
        self.taskWillFinishClosure = closure
        return self
    }

    public final func taskDidFinish(closure: (TaskType) -> Void) -> Self {
        self.taskDidFinishClosure = closure
        return self
    }

}
