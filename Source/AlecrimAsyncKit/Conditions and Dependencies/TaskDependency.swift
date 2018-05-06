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

// So we can use: async(dependency: [dependency1, dependency2]) { ... }

extension Array: TaskDependency where Element: TaskDependency {
    public func notify(execute work: @escaping @convention(block) () -> Void) {
        return self.dependency().notify(execute: work)
    }
}

extension Array where Element: TaskDependency {
    fileprivate func dependency() -> TaskDependency {
        return ArrayTaskDependency(array: self)
    }
}

public final class ArrayTaskDependency: TaskDependency {
    private let array: [TaskDependency]

    fileprivate  init(array: [TaskDependency]) {
        self.array = array
    }

    public func notify(execute work: @escaping @convention(block) () -> Void) {
        let dispatchGroup = DispatchGroup()

        array.forEach {
            dispatchGroup.enter()
            $0.notify { dispatchGroup.leave() }
        }

        dispatchGroup.notify(execute: work)
    }
}

// So we can use: async(dependency: dependency1 && dependency2) { ... }

public func &&(left: TaskDependency, right: TaskDependency) -> TaskDependency {
    return ArrayTaskDependency(array: [left, right])
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

// limit the number of concurrent tasks running with the same dependency to n

public class ConcurrencyTaskDependency: TaskSemaphoreDependency, TaskDependency {
    private let rawValue: DispatchSemaphore

    public init(maxConcurrentTaskCount: Int) {
        precondition(maxConcurrentTaskCount > 0)
        self.rawValue = DispatchSemaphore(value: maxConcurrentTaskCount)
    }

    internal func wait() {
        self.rawValue.wait()
    }

    @discardableResult
    internal func signal() -> Int {
        return self.rawValue.signal()
    }
}

// limit the number of concurrent tasks running with the same dependency to 1

public final class MutuallyExclusiveTaskDependency: ConcurrencyTaskDependency {
    public init() {
        super.init(maxConcurrentTaskCount: 1)
    }
}
