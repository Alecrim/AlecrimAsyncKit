//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// An observer that will be notified about the task start and finish.
public class TaskObserver {
    
    // MARK: - Private properties.
    
    private var didStartClosures = Array<((TaskType) -> Void)>()
    private var didFinishClosures = Array<((TaskType) -> Void)>()

    // MARK: - Initializers.
    
    /// Initializes an observer that will be notified about the task start and finish.
    ///
    /// - returns: An observer that will be notified about the task start and finish.
    public init() {
    
    }
    
    // MARK: - Internal methods.
    
    internal final func taskDidStart(task: TaskType) {
        self.didStartClosures.forEach { $0(task) }
    }
    
    internal final func taskDidFinish(task: TaskType) {
        self.didFinishClosures.forEach { $0(task) }
    }

    // MARK: - Public methods.

    /// Adds a closure that will be run when the task is started.
    ///
    /// - parameter closure: The closure that will be run when the task is started.
    ///
    /// - returns: The observer itself.
    public final func didStart(closure: (TaskType) -> Void) -> Self {
        self.didStartClosures.append(closure)
        return self
    }
    
    /// Adds a closure that will be run when the task is finished.
    ///
    /// - parameter closure: The closure that will be run when the task is finished.
    ///
    /// - returns: The observer itself.
    public final func didFinish(closure: (TaskType) -> Void) -> Self {
        self.didFinishClosures.append(closure)
        return self
    }
    
}
