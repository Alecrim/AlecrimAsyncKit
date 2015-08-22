//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public class TaskObserver<V> {
    
    // MARK: -
    
    private var didStartClosures = Array<((BaseTask<V>) -> Void)>()
    private var didFinishClosures = Array<((BaseTask<V>) -> Void)>()

    // MARK: -
    public init() {
        
    }
    
    // MARK: -
    
    internal final func taskDidStart(task: BaseTask<V>) {
        self.didStartClosures.forEach { $0(task) }
    }
    
    internal final func taskDidFinish(task: BaseTask<V>) {
        self.didFinishClosures.forEach { $0(task) }
    }

    // MARK: -

    public final func didStart(closure: (BaseTask<V>) -> Void) -> Self {
        self.didStartClosures.append(closure)
        return self
    }
    
    public final func didFinish(closure: (BaseTask<V>) -> Void) -> Self {
        self.didFinishClosures.append(closure)
        return self
    }
    
}
