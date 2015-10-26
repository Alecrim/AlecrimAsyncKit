//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public class TaskObserver {
    
    internal final var taskWillStartClosure: ((Any) -> Void)?
    internal final var taskDidStartClosure: ((Any) -> Void)?

    internal final var taskWillFinishClosure: ((Any) -> Void)?
    internal final var taskDidFinishClosure: ((Any) -> Void)?
    
    public init() {
    }
    
    public final func taskWillStart(closure: (Any) -> Void) -> Self {
        self.taskWillStartClosure = closure
        return self
    }

    public final func taskDidStart(closure: (Any) -> Void) -> Self {
        self.taskDidStartClosure = closure
        return self
    }

    public final func taskWillFinish(closure: (Any) -> Void) -> Self {
        self.taskWillFinishClosure = closure
        return self
    }

    public final func taskDidFinish(closure: (Any) -> Void) -> Self {
        self.taskDidFinishClosure = closure
        return self
    }

}
