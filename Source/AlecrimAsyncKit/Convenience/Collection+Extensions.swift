//
//  Collection+Extensions.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 15/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public protocol FailableTaskProtocol {}
public protocol NonFailableTaskProtocol {}

extension Task: FailableTaskProtocol {}
extension NonFailableTask: NonFailableTaskProtocol {}

// MARK: -

public struct WhenAllError: Error {
    let collectedErrors: [Error]
}

// MARK: -

extension Collection where Self.Iterator.Element == FailableTaskProtocol {
    
    public func whenAll() -> Task<[Any]> {
        return async { task in
            let whenAllGroup = DispatchGroup()
            
            var collectedValues = [Any]()
            var collectedErrors = [Error]()
            
            do {
                whenAllGroup.enter(); defer { whenAllGroup.leave() }
                
                for t in self {
                    let failableTask = t as! Task<Any>
                    
                    whenAllGroup.enter()
                    failableTask.group.notify(queue: DispatchQueue.global()) {
                        whenAllGroup.leave()
                        
                        if let error = failableTask.error {
                            if error.isUserCancelled {
                                task.finish(with: NSError.userCancelled)
                            }
                            else {
                                collectedErrors.append(error)
                            }
                        }
                        else {
                            collectedValues.append(task.value!)
                        }
                    }
                }
            }
            
            whenAllGroup.wait()
            
            //
            if collectedErrors.count > 0 {
                task.finish(with: WhenAllError(collectedErrors: collectedErrors))
            }
            else {
                task.finish(with: collectedValues)
            }
            
        }
    }
    
    
    public func whenAny() -> Task<Void> {
        return async { task in
            var isFinished = false
            
            var count = 0
            
            self.forEach { t in
                count += 1
                
                let failableTask = t as! Task<Any>
                
                failableTask.group.notify(queue: DispatchQueue.global()) {
                    if !isFinished {
                        isFinished = true
                        task.finish()
                    }
                }
            }
            
            if count == 0 {
                isFinished = true
                task.finish()
            }
        }
    }
    
}

extension Collection where Self.Iterator.Element == NonFailableTaskProtocol {
    
    public func whenAll() -> NonFailableTask<[Any]> {
        return async {
            let whenAllGroup = DispatchGroup()
            
            var collectedValues = [Any]()
            
            do {
                whenAllGroup.enter(); defer { whenAllGroup.leave() }
                
                for t in self {
                    let nonFailableTask = t as! NonFailableTask<Any>
                    
                    whenAllGroup.enter()
                    nonFailableTask.group.notify(queue: DispatchQueue.global()) {
                        whenAllGroup.leave()
                        collectedValues.append(nonFailableTask.value!)
                    }
                }
            }
            
            whenAllGroup.wait()
            
            return collectedValues
        }
    }
    
    public func whenAny() -> NonFailableTask<Void> {
        return async { task in
            var isFinished = false
            
            var count = 0
            
            self.forEach { t in
                count += 1
                
                let nonFailableTask = t as! NonFailableTask<Any>
                
                nonFailableTask.group.notify(queue: DispatchQueue.global()) {
                    if !isFinished {
                        isFinished = true
                        task.finish()
                    }
                }
            }
            
            if count == 0 {
                isFinished = true
                task.finish()
            }
        }
    }
    
}
