//
//  SequenceType+Extensions.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2016-05-28.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

extension SequenceType where Self.Generator.Element == TaskProtocol {
    
    /// Creates a task that will finish when all of the tasks in the sequence have finished.
    ///
    /// - returns: A task that represents the completion of all of the tasks.
    @warn_unused_result
    public func whenAll() -> Task<Void> {
        return async {
            for task in self {
                task.waitUntilFinished()
                
                if let errorReportingTask = task as? ErrorReportingTask, let error = errorReportingTask.error {
                    throw error
                }
            }
        }
    }
    
    /// Creates a task that will finish when any of the tasks in the sequence have finished.
    ///
    /// - returns: A task that represents the completion of one of the tasks. The returned task's result is the task that finished.
    @warn_unused_result
    public func whenAny() -> Task<Self.Generator.Element> {
        return asyncEx { t in
            func observeTask(task: Self.Generator.Element) throws -> Task<Void> {
                return async {
                    task.waitUntilFinished()
                    
                    if let errorReportingTask = task as? ErrorReportingTask, let error = errorReportingTask.error {
                        throw error
                    }
                    
                    t.finish(with: task)
                }
            }
            
            do {
                for task in self {
                    if t.finished {
                        break
                    }
                    
                    try observeTask(task)
                }
            }
            catch let error {
                t.finish(with: error)
            }
        }
    }
    
}
