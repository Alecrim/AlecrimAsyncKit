//
//  NegateTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// A simple condition that negates the evaluation of another condition.
public final class NegateTaskCondition: TaskCondition {
    
    /// Initializes a condition that negates the evaluation of another condition.
    ///
    /// - parameter otherCondition: The condition to be negated.
    ///
    /// - returns: A condition that negates the evaluation of another condition.
    public init(otherCondition: TaskCondition) {
        super.init(subconditions: otherCondition.subconditions, dependencyTask: otherCondition.dependencyTaskClosure?(), evaluationClosure: otherCondition.evaluationClosure)
    }

    internal override func asyncEvaluate() -> Task<Void> {
        return asyncEx { task in
            do {
                try await(super.asyncEvaluate())
                task.finishWith(error: TaskConditionError.NotSatisfied)
            }
            catch {
                task.finish()
            }
        }
    }
    
}