//
//  Condition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public enum ConditionResult {
    case Satisfied
    case Failed(ErrorType)
    
    public var error: ErrorType? {
        if case .Failed(let error) = self {
            return error
        }
        
        return nil
    }
}


public final class Condition: Task<Void> {
   
    public init<V>(subconditions: [Condition]? = nil, dependencyTask: Task<V>? = nil, closure: ((ConditionResult) -> Void) -> Void) {
        super.init(conditions: subconditions, observers: nil) { task in
            if let dependencyTask = dependencyTask {
                do {
                    try await(dependencyTask)
                }
                catch let error {
                    task.finishWithError(error)
                    return
                }
            }
            
            closure { conditionResult in
                switch conditionResult {
                case .Satisfied:
                    task.finish()
                    
                case .Failed(let error):
                    task.finishWithError(error)
                }
            }
        }
    }
    
}

extension Condition {
    
    internal static func asyncEvaluateConditions(conditions: [Condition]) -> Task<Void> {
        return async { task in
            do {
                for condition in conditions {
                    try await(condition)
                }
                
                task.finish()
            }
            catch let error {
                task.finishWithError(error)
            }
        }
    }

}
