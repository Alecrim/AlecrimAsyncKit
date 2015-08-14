//
//  Observer.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public final class Observer<V> {

    // MARK: -
    
    private var didStartClosures = Array<(() -> Void)>()
    private var didFinishClosures = Array<((V!, ErrorType?) -> Void)>()

    // MARK: -

    internal func taskDidStart(task: Task<V>) {
        for closure in self.didStartClosures {
            closure()
        }
    }
    
    internal func task(task: Task<V>, didFinishWithValue value: V!, error: ErrorType?) {
        for closure in self.didFinishClosures {
            closure(value, error)
        }
    }

    // MARK: -

    public func didStart(closure: () -> Void) -> Self {
        self.didStartClosures.append(closure)
        return self
    }
    
    public func didFinish(closure: (V!, ErrorType?) -> Void) -> Self {
        self.didFinishClosures.append(closure)
        return self
    }
    
}
