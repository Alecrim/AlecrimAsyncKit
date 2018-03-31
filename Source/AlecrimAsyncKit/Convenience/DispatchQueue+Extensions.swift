//
//  DispatchQueue+Extensions.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 15/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

extension DispatchQueue {
    
    public func async<Value>(execute closure: @escaping AsyncTaskClosure<Value>) -> Task<Value> {
        return AlecrimAsyncKit.async(in: _operationQueue(for: self), execute: closure)
    }
    
    public func async<Value>(execute closure: @escaping AsyncNonFailableTaskClosure<Value>) -> NonFailableTask<Value> {
        return AlecrimAsyncKit.async(in: _operationQueue(for: self), execute: closure)
    }
    
    public func async<Value>(execute taskClosure: @escaping AsyncTaskFullClosure<Value>) -> Task<Value> {
        return AlecrimAsyncKit.async(in: _operationQueue(for: self), execute: taskClosure)
    }
    
    public func async<Value>(execute taskClosure: @escaping AsyncTaskFullClosure<Value>) -> NonFailableTask<Value> {
        return AlecrimAsyncKit.async(in: _operationQueue(for: self), execute: taskClosure)
    }
    
}

fileprivate func _operationQueue(for dispatchQueue: DispatchQueue) -> OperationQueue {
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = ProcessInfo().activeProcessorCount * 2
    operationQueue.underlyingQueue = dispatchQueue
    
    return operationQueue
}

