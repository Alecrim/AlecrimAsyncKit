//
//  TaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private let _defaultTaskConditionQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.name = "com.alecrim.AlecrimAsyncKit.TaskCondition"
    queue.qualityOfService = .Background
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
    }()


public enum TaskConditionResult {
    case Satisfied
    case Failed
    case FailedWithError(ErrorType)
}


public class TaskCondition {
    
    internal let subconditions: [TaskCondition]?
    internal let dependencyTask: Task<Void>?
    internal let evaluationClosure: ((TaskConditionResult) -> Void) -> Void
   
    public convenience init(evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.init(subconditions: nil, dependencyTask: nil, evaluationClosure: evaluationClosure)
    }

    public convenience init(dependencyTask: Task<Void>, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.init(subconditions: nil, dependencyTask: dependencyTask, evaluationClosure: evaluationClosure)
    }

    public convenience init(subcondition: TaskCondition, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.init(subconditions: [subcondition], dependencyTask: nil, evaluationClosure: evaluationClosure)
    }

    public convenience init(subcondition: TaskCondition, dependencyTask: Task<Void>, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.init(subconditions: [subcondition], dependencyTask: dependencyTask, evaluationClosure: evaluationClosure)
    }

    public convenience init(subconditions: [TaskCondition], evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.init(subconditions: subconditions, dependencyTask: nil, evaluationClosure: evaluationClosure)
    }

    public init(subconditions: [TaskCondition]?, dependencyTask: Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = subconditions
        self.dependencyTask = dependencyTask
        self.evaluationClosure = evaluationClosure
    }
    
    internal func asyncEvaluate() -> Task<Void> {
        return async(_defaultTaskConditionQueue) { [unowned self] task in
            self.evaluationClosure { conditionResult in
                switch conditionResult {
                case .Satisfied:
                    task.finish()
                 
                case .Failed:
                    task.finishWithError(taskCancelledError)
                    
                case .FailedWithError(let error):
                    task.finishWithError(error)
                }
            }
        }
    }
    
}

extension TaskCondition {
    
    internal static func asyncEvaluateConditions(conditions: [TaskCondition]) -> Task<Void> {
        return async(_defaultTaskConditionQueue) { task in
            do {
                for condition in conditions {
                    if let subconditions = condition.subconditions {
                        try await(TaskCondition.asyncEvaluateConditions(subconditions))
                    }
                    
                    if let dependencyTask = condition.dependencyTask {
                        try await(dependencyTask)
                    }
                    
                    try await(condition.asyncEvaluate())
                }
                
                task.finish()
            }
            catch let error {
                task.finishWithError(error)
            }
        }
    }

}
