//
//  TaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public enum TaskConditionResult {
    case Satisfied
    case Failed(ErrorType)
    
    public var error: ErrorType? {
        if case .Failed(let error) = self {
            return error
        }
        
        return nil
    }
}


public final class TaskCondition: Task<Void> {
   
    public convenience init(evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.init(subconditions: nil, dependencyTask: nil, evaluationClosure: evaluationClosure)
    }
    
    public init(subconditions: [TaskCondition]?, dependencyTask: Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
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
            
            evaluationClosure { conditionResult in
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

extension TaskCondition {
    
    internal static func asyncEvaluateConditions(conditions: [TaskCondition]) -> Task<Void> {
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
