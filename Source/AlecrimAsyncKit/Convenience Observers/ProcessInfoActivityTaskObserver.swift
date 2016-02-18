//
//  ProcessInfoActivityTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-27.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public final class ProcessInfoActivityTaskObserver: TaskDidStartObserverType, TaskDidFinishObserverType {
    
    private let options: NSActivityOptions
    private let reason: String

    private var activity: NSObjectProtocol?
    
    public init(options: NSActivityOptions, reason: String) {
        self.options = options
        self.reason = reason
    }
    
    public func didStartTask(task: TaskType) {
        self.activity = NSProcessInfo.processInfo().beginActivityWithOptions(self.options, reason: self.reason)
    }
    
    public func didFinishTask(task: TaskType) {
        if let activity = self.activity {
            NSProcessInfo.processInfo().endActivity(activity)
            self.activity = nil
        }
    }
    
}
