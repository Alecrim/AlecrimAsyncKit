//
//  ProcessInfoActivityObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-27.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public final class ProcessInfoActivityObserver: TaskDidStartObserver, TaskDidFinishObserver {
    
    private let options: ProcessInfo.ActivityOptions
    private let reason: String

    private var activity: NSObjectProtocol?
    
    public init(options: ProcessInfo.ActivityOptions, reason: String) {
        self.options = options
        self.reason = reason
    }
    
    public func didStartTask(_ task: TaskProtocol) {
        self.activity = ProcessInfo.processInfo().beginActivity(self.options, reason: self.reason)
    }
    
    public func didFinishTask(_ task: TaskProtocol) {
        if let activity = self.activity {
            ProcessInfo.processInfo().endActivity(activity)
            self.activity = nil
        }
    }
    
}
