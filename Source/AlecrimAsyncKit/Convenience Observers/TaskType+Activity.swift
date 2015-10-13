//
//  TaskType+Activity.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-27.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

extension TaskType {
    
    public func bindToActivityWithOptions(options: NSActivityOptions, reason: String) -> Self {
        var activity: NSObjectProtocol!
        
        self.didStart { _ in
            activity = NSProcessInfo.processInfo().beginActivityWithOptions(options, reason: reason)
        }
        
        self.didFinish { _ in
            NSProcessInfo.processInfo().endActivity(activity)
            activity = nil
        }
        
        return self
    }
    
}
