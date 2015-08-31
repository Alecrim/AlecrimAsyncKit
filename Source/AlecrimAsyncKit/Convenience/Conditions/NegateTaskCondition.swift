//
//  NegateTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public final class NegateTaskCondition: TaskCondition {
    
    public init(_ otherCondition: TaskCondition) {
        super.init(subconditions: otherCondition.subconditions, dependencyTask: otherCondition.dependencyTask, evaluationClosure: otherCondition.evaluationClosure)
    }

    internal override func asyncEvaluate() -> Task<Void> {
        return asyncEx { task in
            do {
                try await(super.asyncEvaluate())
                
                let error = NSError(domain: "com.alecrim.AlecrimAsyncKit.NegateTaskCondition", code: 1000, userInfo: nil)
                task.finishWithError(error)
            }
            catch {
                task.finish()
            }
        }
    }
    
}