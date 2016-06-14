//
//  DelayCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// A condition that will simply wait for a given time interval to be satisfied.
public final class DelayCondition: TaskCondition {
    
    /// Initializes a condition that will wait for a given time interval to be satisfied.
    ///
    /// - parameter timeInterval: The time interval to wait.
    /// - parameter tolerance:    The tolerance time interval (optional, defaults to 0).
    ///
    /// - returns: A condition that will wait for a given time interval to be satisfied.
    public init(timeInterval: TimeInterval, tolerance: TimeInterval = 0) {
        super.init() { result in
            let toleranceInNanoseconds = Int(tolerance * TimeInterval(NSEC_PER_SEC))
            let timer = DispatchSource.timer(flags: [], queue: Queue.delayQueue)

            timer.scheduleOneshot(deadline: DispatchTime.now() + timeInterval, leeway: .nanoseconds(toleranceInNanoseconds))
            timer.setEventHandler() { result(.satisfied) }
            timer.resume()
        }
    }
    
}
