//
//  TimeoutTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

extension FailableTaskType {

    public func cancelAfterTimeout(timeout: NSTimeInterval) -> Self {
        self.didStart { task in
            weak var weakTask = task
            
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))
            
            let queue: dispatch_queue_t
            if #available(OSXApplicationExtension 10.10, *) {
                queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
            } else {
                queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            }
            
            dispatch_after(when, queue) {
                weakTask?.cancel()
            }
        }
        
        return self
    }
    
}
