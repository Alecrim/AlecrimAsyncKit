//
//  ProcessInfoActivityTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-27.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public final class ProcessInfoActivityTaskObserver<T: TaskType, V where T.ValueType == V>: TaskObserver<T, V> {
    
    public init(options: NSActivityOptions, reason: String) {
        super.init()
        
        var activity: NSObjectProtocol!
        
        self.taskDidStart { _ in
            activity = NSProcessInfo.processInfo().beginActivityWithOptions(options, reason: reason)
        }
        
        self.taskDidFinish { _ in
            NSProcessInfo.processInfo().endActivity(activity)
            activity = nil
        }
    }
    
}
