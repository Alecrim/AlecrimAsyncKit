//
//  OperationQueue+Extensions.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 15/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

extension OperationQueue {
    
    public func addOperation<Value>(_ closure: @escaping AsyncTaskClosure<Value>) -> Task<Value> {
        return AlecrimAsyncKit.async(on: self, execute: closure)
    }
    
    public func addOperation<Value>(_ closure: @escaping AsyncNonFailableTaskClosure<Value>) -> NonFailableTask<Value> {
        return AlecrimAsyncKit.async(on: self, execute: closure)
    }
    
    public func addOperation<Value>(_ taskClosure: @escaping AsyncTaskFullClosure<Value>) -> Task<Value> {
        return AlecrimAsyncKit.async(on: self, execute: taskClosure)
    }
    
    public func addOperation<Value>(_ taskClosure: @escaping AsyncTaskFullClosure<Value>) -> NonFailableTask<Value> {
        return AlecrimAsyncKit.async(on: self, execute: taskClosure)
    }
    
}
