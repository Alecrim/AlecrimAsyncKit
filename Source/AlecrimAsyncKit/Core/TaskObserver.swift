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
    
    private var didStartClosures = Array<((Task<V>) -> Void)>()
    private var didFinishClosures = Array<((Task<V>) -> Void)>()

    // MARK: -
    public init() {
        
    }
    
    
    // MARK: -
    
    public final func taskDidStart(task: Task<V>) {
        for closure in self.didStartClosures {
            closure(task)
        }
    }
    
    public final func taskDidFinish(task: Task<V>) {
        for closure in self.didFinishClosures {
            closure(task)
        }
    }

    // MARK: -

    public final func didStart(closure: (Task<V>) -> Void) -> Self {
        self.didStartClosures.append(closure)
        return self
    }
    
    public final func didFinish(closure: (Task<V>) -> Void) -> Self {
        self.didFinishClosures.append(closure)
        return self
    }
    
}
