//
//  TimeoutObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public struct TimeoutObserver: TaskWillStartObserver {
    
    private let timeout: TimeInterval

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public func willStartTask(_ task: TaskProtocol) {
        if let task = task as? CancellableTask {
            weak var weakTask = task
            
            Queue.delayQueue.asyncAfter(deadline: DispatchTime.now() + self.timeout) {
                weakTask?.cancel()
            }
        }
    }
    
}
