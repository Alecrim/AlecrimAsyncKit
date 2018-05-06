//
//  TaskDependency.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 05/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public protocol TaskDependency {
    func notify(execute work: @escaping @convention(block) () -> Void)
}

// MARK: -

extension DispatchGroup: TaskDependency {
    public func notify(execute work: @escaping @convention(block) () -> Void) {
        self.notify(queue: Queue.taskDependencyDispatchQueue, execute: work)
    }
}

extension DispatchWorkItem: TaskDependency {
    public func notify(execute work: @escaping @convention(block) () -> Void) {
        self.notify(queue: Queue.taskDependencyDispatchQueue, execute: work)
    }
}

extension BaseTask: TaskDependency {
    public func notify(execute work: @escaping @convention(block) () -> Void) {
        return self.group.notify(execute: work)
    }
}

// MARK: -

// `BaseTask` has special knowledge of `TaskSemaphoreDependency`

internal protocol TaskSemaphoreDependency: TaskDependency  {
    func wait()

    @discardableResult
    func signal() -> Int
}

extension TaskSemaphoreDependency  {
    public func notify(execute work: @escaping @convention(block) () -> Void) {
        work()
    }
}

public class ConcurrencyTaskDependency: TaskSemaphoreDependency, TaskDependency {
    private let rawValue: DispatchSemaphore

    public init(maxConcurrentTaskCount: Int) {
        precondition(maxConcurrentTaskCount > 0)
        self.rawValue = DispatchSemaphore(value: maxConcurrentTaskCount)
    }

    public func wait() {
        self.rawValue.wait()
    }

    @discardableResult
    public func signal() -> Int {
        return self.rawValue.signal()
    }
}


public final class MutuallyExclusiveTaskDependency: ConcurrencyTaskDependency {
    public init() {
        super.init(maxConcurrentTaskCount: 1)
    }
}
