//
//  TimeoutObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public struct TimeoutObserver: TaskWillStartObserver {
    
    private let timeout: NSTimeInterval

    public init(timeout: NSTimeInterval) {
        self.timeout = timeout
    }

    public func willStart(task: TaskProtocol) {
        if let task = task as? CancellableTask {
            weak var weakTask = task
            
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                weakTask?.cancel()
            }
        }
    }
    
}
