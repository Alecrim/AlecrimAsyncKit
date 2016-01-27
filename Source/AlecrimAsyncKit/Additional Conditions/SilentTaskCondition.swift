//
//  SilentTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// A simple condition that causes another condition to not run its dependency task.
public final class SilentTaskCondition: TaskCondition {
    
    /// Initializes a condition that causes another condition to not run its dependency task.
    ///
    /// - parameter otherCondition: The condition that `dependencyTask` will not run.
    ///
    /// - returns: A condition that causes another condition to not run its dependency task.
    public init(otherCondition: TaskCondition) {
        super.init(subconditions: otherCondition.subconditions, dependencyTask: nil, evaluationClosure: otherCondition.evaluationClosure)
    }
    
}
