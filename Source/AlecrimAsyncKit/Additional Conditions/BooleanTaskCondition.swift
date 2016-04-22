//
//  BooleanTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-06.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

/// A condition that is satisfied according a boolean value.
public final class BooleanTaskCondition: TaskCondition {
    
    /// Initializes a `BooleanTaskCondition` that will be satisfied if the passed closure returns `true`.
    ///
    /// - parameter valueClosure: The closure that will return `true` if the condition is satisfied, `false` otherwise.
    ///
    /// - returns: An initialized `BooleanTaskCondition` that will be satisfied if the passed closure returns `true`
    public init(@autoclosure(escaping) _ valueClosure: () -> Bool) {
        super.init() { result in
            if valueClosure() {
                result(.satisfied)
            }
            else {
                result(.notSatisfied)
            }
        }
    }

}
