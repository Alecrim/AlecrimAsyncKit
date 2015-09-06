//
//  SilentTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public final class SilentTaskCondition: TaskCondition {
    
    public init(_ otherCondition: TaskCondition) {
        super.init(subconditions: otherCondition.subconditions, dependencyTask: nil, evaluationClosure: otherCondition.evaluationClosure)
    }
    
}
