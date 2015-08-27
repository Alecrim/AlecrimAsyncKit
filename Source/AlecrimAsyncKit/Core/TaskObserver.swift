//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public class TaskObserver {
    
    // MARK: -
    
    private var didStartClosures = Array<((TaskType) -> Void)>()
    private var didFinishClosures = Array<((TaskType) -> Void)>()

    // MARK: -
    public init() {
        
    }
    
    // MARK: -
    
    internal final func taskDidStart(task: TaskType) {
        self.didStartClosures.forEach { $0(task) }
    }
    
    internal final func taskDidFinish(task: TaskType) {
        self.didFinishClosures.forEach { $0(task) }
    }

    // MARK: -

    public final func didStart(closure: (TaskType) -> Void) -> Self {
        self.didStartClosures.append(closure)
        return self
    }
    
    public final func didFinish(closure: (TaskType) -> Void) -> Self {
        self.didFinishClosures.append(closure)
        return self
    }
    
}
