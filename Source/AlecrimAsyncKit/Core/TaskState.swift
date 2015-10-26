//
//  TaskState.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-10-25.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

public enum TaskState: Int {
    case Initialized
    case Pending
    case EvaluatingConditions
    case Ready
    case Executing
    case Finishing
    case Finished
    
    internal func canTransitionToState(newState: TaskState) -> Bool {
        switch (self, newState) {
        case (.Initialized, .Pending):
            return true
            
        case (.Pending, .EvaluatingConditions):
            return true
            
        case (.Pending, .Ready):
            return true
            
        case (.Pending, .Finishing):
            return true
            
        case (.EvaluatingConditions, .Ready):
            return true
            
        case (.EvaluatingConditions, .Finishing):
            return true
            
        case (.Ready, .Executing):
            return true
            
        case (.Ready, .Finishing):
            return true
            
        case (.Executing, .Finishing):
            return true
            
        case (.Finishing, .Finished):
            return true
            
        default:
            return false
        }
    }
    
}
