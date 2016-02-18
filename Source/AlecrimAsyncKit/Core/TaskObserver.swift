//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public protocol TaskObserverType {
}

public protocol TaskWillStartObserverType: TaskObserverType {
    func willStartTask(task: TaskType)
}

public protocol TaskDidStartObserverType: TaskObserverType {
    func didStartTask(task: TaskType)
}

public protocol TaskWillFinishObserverType: TaskObserverType {
    func willFinishTask(task: TaskType)
}

public protocol TaskDidFinishObserverType: TaskObserverType {
    func didFinishTask(task: TaskType)
}


// MARK: - experiments

//public struct TaskCancelledObserver: TaskDidFinishObserverType {
//    
//    private let closure: TaskType -> Void
//    
//    public init(closure: TaskType -> Void) {
//        self.closure = closure
//    }
//    
//    public func didFinishTask(task: TaskType) {
//        if let task = task as? CancellableTaskType where task.cancelled {
//            closure(task)
//        }
//    }
//    
//}