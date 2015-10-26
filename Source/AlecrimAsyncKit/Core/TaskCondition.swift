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
    
    if #available(OSXApplicationExtension 10.10, *) {
        queue.qualityOfService = .Background
    }
    
    queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    return queue
    }()


/// An enumeration with the possible condition results.
///
/// - Satisfied:    The condition was satisfied.
/// - NotSatisfied: The condition was not satisfied.
/// - Failed:       An error was occurred while evaluating the condition.
public enum TaskConditionResult {
    case Satisfied
    case NotSatisfied
    case Failed(ErrorType)
}

/// A condition determines if a task can be executed or not.
public class TaskCondition {
    
    internal let subconditions: [TaskCondition]?
    internal let dependencyTaskClosure: () -> Task<Void>?
    internal let evaluationClosure: ((TaskConditionResult) -> Void) -> Void
   
    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter evaluationClosure: The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
    public init(evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = nil
        self.dependencyTaskClosure = { return nil }
        self.evaluationClosure = evaluationClosure
    }

    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter dependencyTaskClosure: A failable task that to be runned before the condition evaluation. If the task finishes with an error, the condition evalution closure is not executed and the condition is mark as failed. The dependency task will be only started, if needed, at the moment of the evaluation.
    /// - parameter evaluationClosure:     The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
    public init(@autoclosure(escaping) dependencyTask dependencyTaskClosure: () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = nil
        self.dependencyTaskClosure = dependencyTaskClosure
        self.evaluationClosure = evaluationClosure
    }

    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter subcondition:      A subcondition that determines if the condition itself will be evaluated.
    /// - parameter evaluationClosure: The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
    public init(subcondition: TaskCondition, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = [subcondition]
        self.dependencyTaskClosure = { return nil }
        self.evaluationClosure = evaluationClosure
    }

    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter subcondition:          A subcondition that determines if the condition itself will be evaluated.
    /// - parameter dependencyTaskClosure: A failable task that to be runned before the condition evaluation. If the task finishes with an error, the condition evalution closure is not executed and the condition is mark as failed. The dependency task will be only started, if needed, at the moment of the evaluation.
    /// - parameter evaluationClosure:     The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
    public init(subcondition: TaskCondition, @autoclosure(escaping) dependencyTask dependencyTaskClosure: () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = [subcondition]
        self.dependencyTaskClosure = dependencyTaskClosure
        self.evaluationClosure = evaluationClosure
    }

    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter subconditions:     The subconditions that will determine if the condition itself will be evaluated.
    /// - parameter evaluationClosure: The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
    public init(subconditions: [TaskCondition], evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = subconditions
        self.dependencyTaskClosure = { return nil }
        self.evaluationClosure = evaluationClosure
    }

    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter subconditions:         The subconditions that will determine if the condition itself will be evaluated.
    /// - parameter dependencyTaskClosure: A failable task that to be runned before the condition evaluation. If the task finishes with an error, the condition evalution closure is not executed and the condition is mark as failed. The dependency task will be only started, if needed, at the moment of the evaluation.
    /// - parameter evaluationClosure:     The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
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
                    task.finishWithError(TaskConditionError.Failed(error))
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

