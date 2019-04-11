//
//  Sequence+Extensions.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 15/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public protocol FailableTaskProtocol {
    associatedtype ValueType
}

public protocol NonFailableTaskProtocol {
    associatedtype ValueType
}

extension Task: FailableTaskProtocol {
    public typealias ValueType = Value

}

extension NonFailableTask: NonFailableTaskProtocol {
    public typealias ValueType = Value
}


// MARK: -

public struct WhenAllError: Error {
    let collectedErrors: [Error]
}

// MARK: -

extension Sequence where Element: FailableTaskProtocol {
    
    public func all() -> Task<[Element.ValueType]>  {
        return async { task in
            let whenAllGroup = DispatchGroup()
            
            var collectedValues = [Element.ValueType]()
            var collectedErrors = [Error]()
            
            do {
                whenAllGroup.enter(); defer { whenAllGroup.leave() }
                
                for element in self {
                    let failableTask = element as! Task<Element.ValueType>
                    
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
                            collectedValues.append(failableTask.value!)
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
    
    
    public func any() -> Task<Void> {
        return async { task in
            var isFinished = false
            
            var count = 0
            
            self.forEach { element in
                count += 1
                
                let failableTask = element as! Task<Element.ValueType>
                
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

extension Sequence where Element: NonFailableTaskProtocol {
    
    public func all() -> NonFailableTask<[Element.ValueType]> {
        return async {
            let whenAllGroup = DispatchGroup()
            
            var collectedValues = [Element.ValueType]()
            
            do {
                whenAllGroup.enter(); defer { whenAllGroup.leave() }
                
                for element in self {
                    let nonFailableTask = element as! NonFailableTask<Element.ValueType>
                    
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
    
    public func any() -> NonFailableTask<Void> {
        return async { task in
            var isFinished = false
            
            var count = 0
            
            self.forEach { element in
                count += 1
                
                let nonFailableTask = element as! NonFailableTask<Element.ValueType>
                
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
