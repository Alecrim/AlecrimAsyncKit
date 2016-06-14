//
//  Queue.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2016-06-14.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

internal struct Queue {
    
    // MARK: - Task Queues
    
    internal static let taskDefaultOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.alecrim.AlecrimAsyncKit.Task"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        
        return queue
    }()
    
    // MARK: - Task Condition Queues
    
    internal static let taskConditionOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.alecrim.AlecrimAsyncKit.TaskCondition"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        
        return queue
    }()

    internal static let taskConditionEvaluationOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.alecrim.AlecrimAsyncKit.TaskCondition.Evaluation"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        
        return queue
    }()

    // MARK: - Task Awaiter Queues
    
    internal static let taskAwaiterDefaultOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.alecrim.AlecrimAsyncKit.TaskAwaiter"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        
        return queue
    }()
    
    internal static let taskAwaiterCallbackSerialQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.TaskAwaiter.Callback", attributes: [.qosUtility, .serial])
    
    // MARK: - Convenience Queues
    
    internal static let mainQueue = DispatchQueue.main
    internal static let delayQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.Delay", attributes: [.qosUtility, .concurrent])
    
}
