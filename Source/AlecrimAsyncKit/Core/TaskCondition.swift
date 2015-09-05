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
    case NotSatisfied
    case Failed(error: ErrorType)
}


public class TaskCondition {
    
    internal let subconditions: [TaskCondition]?
    internal let dependencyTaskClosure: () -> Task<Void>?
    internal let evaluationClosure: ((TaskConditionResult) -> Void) -> Void
   
    public init(evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = nil
        self.dependencyTaskClosure = { return nil }
        self.evaluationClosure = evaluationClosure
    }

    public init(@autoclosure(escaping) dependencyTask dependencyTaskClosure: () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = nil
        self.dependencyTaskClosure = dependencyTaskClosure
        self.evaluationClosure = evaluationClosure
    }

    public init(subcondition: TaskCondition, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = [subcondition]
        self.dependencyTaskClosure = { return nil }
        self.evaluationClosure = evaluationClosure
    }

    public init(subcondition: TaskCondition, @autoclosure(escaping) dependencyTask dependencyTaskClosure: () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = [subcondition]
        self.dependencyTaskClosure = dependencyTaskClosure
        self.evaluationClosure = evaluationClosure
    }

    public init(subconditions: [TaskCondition], evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = subconditions
        self.dependencyTaskClosure = { return nil }
        self.evaluationClosure = evaluationClosure
    }

    public init(subconditions: [TaskCondition]?, @autoclosure(escaping) dependencyTask dependencyTaskClosure: () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = subconditions
        self.dependencyTaskClosure = dependencyTaskClosure
        self.evaluationClosure = evaluationClosure
    }

    internal func asyncEvaluate() -> Task<Void> {
        return asyncEx(_defaultTaskConditionQueue) { [unowned self] task in
            self.evaluationClosure { conditionResult in
                switch conditionResult {
                case .Satisfied:
                    task.finish()
                 
                case .NotSatisfied:
                    task.finishWithError(TaskConditionError.NotSatisfied)
                    
                case .Failed(let error):
                    task.finishWithError(TaskConditionError.Failed(innerError: error))
                }
            }
        }
    }
    
}

extension TaskCondition {
    
    internal static func asyncEvaluateConditions(conditions: [TaskCondition]) -> Task<Void> {
        return async(_defaultTaskConditionQueue) {
            for condition in conditions {
                if let subconditions = condition.subconditions where !subconditions.isEmpty {
                    try await(TaskCondition.asyncEvaluateConditions(subconditions))
                }
                
                if let dependencyTask = condition.dependencyTaskClosure() {
                    try await(dependencyTask)
                }
                
                try await(condition.asyncEvaluate())
            }
        }
    }

}

