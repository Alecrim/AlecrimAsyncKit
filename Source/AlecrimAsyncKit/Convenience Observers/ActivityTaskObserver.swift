//
//  ActivityTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-27.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public final class ActivityTaskObserver: TaskObserver {
    
    public init(options: NSActivityOptions, reason: String) {
        super.init()
        
        var activity: NSObjectProtocol!
        
        self.didStart { _ in
            activity = NSProcessInfo.processInfo().beginActivityWithOptions(options, reason: reason)
        }
        
        self.didFinish { _ in
            NSProcessInfo.processInfo().endActivity(activity)
            activity = nil
        }
    }
    
}
