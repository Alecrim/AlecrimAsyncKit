//
//  Queue.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 05/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

internal /* namespace */ enum Queue {

    //private static let defaultMaxConcurrentOperationCount = ProcessInfo().activeProcessorCount * 2
    private static let defaultMaxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount

    internal static let defaultOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.alecrim.AlecrimAsyncKit.Task"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = Queue.defaultMaxConcurrentOperationCount

        return queue
    }()

    internal static let taskAwaiterDefaultOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.alecrim.AlecrimAsyncKit.TaskAwaiter"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = Queue.defaultMaxConcurrentOperationCount

        return queue
    }()

    internal static func operationQueue(for dispatchQueue: DispatchQueue) -> OperationQueue {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = Queue.defaultMaxConcurrentOperationCount
        operationQueue.underlyingQueue = dispatchQueue

        return operationQueue
    }

    internal static let delayDispatchQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.Delay", qos: .utility, attributes: .concurrent)

    internal static let taskConditionOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.alecrim.AlecrimAsyncKit.TaskCondition"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = Queue.defaultMaxConcurrentOperationCount

        return queue
    }()

    internal static let taskDependencyDispatchQueue: DispatchQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.TaskDependency", qos: .utility, attributes: .concurrent)

}
