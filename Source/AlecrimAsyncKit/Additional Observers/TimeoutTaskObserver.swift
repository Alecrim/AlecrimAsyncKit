//
//  TimeoutTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// A task observer that causes the observed failable task to be cancelled if not finished before a specified time interval.
public final class TimeoutTaskObserver: TaskObserver {

    /// Initializes a task observer that causes the observed failable task to be cancelled if not finished before a specified time interval.
    ///
    /// - parameter timeout: The timeout time interval.
    ///
    /// - returns: An observer that causes a failable task to be cancelled if not finished before a specified time interval.
    public init(timeout: NSTimeInterval) {
        super.init()
        
        self.didStart { task in
            assert(task is FailableTaskType, "The timeout observer only works on failable tasks.")
            
            weak var weakTask = task

            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                if let strongTask = weakTask as? FailableTaskType {
                    strongTask.cancel()
                }
            }
        }
    }
    
}
