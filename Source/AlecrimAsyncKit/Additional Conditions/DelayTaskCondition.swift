//
//  DelayTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// A condition that will simply wait for a given time interval to be satisfied.
public final class DelayTaskCondition: TaskCondition {
    
    /// Initializes a condition that will wait for a given time interval to be satisfied.
    ///
    /// - parameter timeInterval: The time interval to wait.
    /// - parameter tolerance:    The tolerance time interval (optional, defaults to 0).
    ///
    /// - returns: A condition that will wait for a given time interval to be satisfied.
    public init(timeInterval: NSTimeInterval, tolerance: NSTimeInterval = 0) {
        super.init() { result in
            let queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
            let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
            
            let intervalInNanoseconds = Int64(timeInterval * NSTimeInterval(NSEC_PER_SEC))
            let toleranceInNanoseconds = Int64(tolerance * NSTimeInterval(NSEC_PER_SEC))
            
            dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, intervalInNanoseconds), UInt64(intervalInNanoseconds), UInt64(toleranceInNanoseconds))
            
            dispatch_source_set_event_handler(timer) {
                dispatch_source_cancel(timer)
                result(.Satisfied)
            }
            
            dispatch_resume(timer)
        }
    }
    
}
