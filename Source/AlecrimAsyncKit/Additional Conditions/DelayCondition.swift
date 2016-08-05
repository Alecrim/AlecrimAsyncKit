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
    ///
    /// - returns: A condition that will wait for a given time interval to be satisfied.
    public init(timeInterval: TimeInterval) {
        super.init() { result in
            Queue.delayQueue.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
                result(.satisfied)
            }
        }
    }
    
}
