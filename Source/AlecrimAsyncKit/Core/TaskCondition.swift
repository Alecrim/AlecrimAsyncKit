//
//  TaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// An enumeration with the possible condition results.
///
/// - satisfied:    The condition was satisfied.
/// - notSatisfied: The condition was not satisfied.
/// - failed:       An error was occurred while evaluating the condition.
public enum TaskConditionResult {
    case satisfied
    case notSatisfied
    case failed(Error)
}

/// A condition determines if a task can be executed or not.
public class TaskCondition {
    
    internal let subconditions: [TaskCondition]?
    internal let dependencyTaskClosure: (() -> Task<Void>?)?
    internal var evaluationClosure: (((TaskConditionResult) -> Void) -> Void)
    
    // for deferred evaluationClosure assignment only (we don't care about the evaluationClosureAssignmentDeferred value)
    internal init(evaluationClosureAssignmentDeferred: Bool) {
        self.subconditions = nil
        self.dependencyTaskClosure = nil
        self.evaluationClosure = { _ in fatalError() }
    }
    
    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter evaluationClosure: The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
    public init(evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = nil
        self.dependencyTaskClosure = nil
        self.evaluationClosure = evaluationClosure
    }

    /// Initializes a condition that will determine if a task can be executed or not.
    ///
    /// - parameter dependencyTaskClosure: A failable task that to be runned before the condition evaluation. If the task finishes with an error, the condition evalution closure is not executed and the condition is mark as failed. The dependency task will be only started, if needed, at the moment of the evaluation.
    /// - parameter evaluationClosure:     The evaluation closure returning a `TaskConditionResult` enumeration member.
    ///
    /// - returns: A condition that will determine if a task can be executed or not.
    public init( dependencyTask dependencyTaskClosure: @autoclosure(escaping) () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
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
    public init(subcondition: TaskCondition, dependencyTask dependencyTaskClosure: @autoclosure(escaping) () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
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
    public init(subconditions: [TaskCondition]?, dependencyTask dependencyTaskClosure: @autoclosure(escaping) () -> Task<Void>?, evaluationClosure: ((TaskConditionResult) -> Void) -> Void) {
        self.subconditions = subconditions
        self.dependencyTaskClosure = dependencyTaskClosure
        self.evaluationClosure = evaluationClosure
    }
    
    internal func evaluate() -> Task<Void> {
        return asyncEx(in: Queue.taskConditionOperationQueue) { [unowned self] task in
            self.evaluationClosure { conditionResult in
                switch conditionResult {
                case .satisfied:
                    task.finish()
                 
                case .notSatisfied:
                    task.finish(with: TaskConditionError.notSatisfied)
                    
                case .failed(let error):
                    task.finish(with: TaskConditionError.failed(error))
                }
            }
        }
    }
    
}

extension TaskCondition {
    
    internal static func evaluateConditions(_ conditions: [TaskCondition]) -> Task<Void> {
        return async(in: Queue.taskConditionOperationQueue) {
            for condition in conditions {
                if let subconditions = condition.subconditions, !subconditions.isEmpty {
                    try await(TaskCondition.evaluateConditions(subconditions))
                }
                
                if let dependencyTask = condition.dependencyTaskClosure?() {
                    try await(dependencyTask)
                }
                
                try await(condition.evaluate())
            }
        }
    }

}

