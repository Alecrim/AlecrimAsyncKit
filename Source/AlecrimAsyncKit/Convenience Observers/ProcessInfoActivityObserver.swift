//
//  ProcessInfoActivityObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-27.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public final class ProcessInfoActivityObserver: TaskDidStartObserver, TaskDidFinishObserver {
    
    private let options: NSActivityOptions
    private let reason: String

    private var activity: NSObjectProtocol?
    
    public init(options: NSActivityOptions, reason: String) {
        self.options = options
        self.reason = reason
    }
    
    public func didStart(task: TaskProtocol) {
        self.activity = NSProcessInfo.processInfo().beginActivityWithOptions(self.options, reason: self.reason)
    }
    
    public func didFinish(task: TaskProtocol) {
        if let activity = self.activity {
            NSProcessInfo.processInfo().endActivity(activity)
            self.activity = nil
        }
    }
    
}
