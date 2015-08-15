//
//  MutuallyExclusiveTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public final class MutuallyExclusiveTaskCondition: TaskCondition {

    public enum DefaultCategory: String {
        case Alert = "METCDC.Alert"
    }

    private static var mutuallyExclusiveTaskConditions = [String: (queue: dispatch_queue_t, count: Int)]()
    private static var spinlock = OS_SPINLOCK_INIT

    public convenience init(_ defaultCategory: MutuallyExclusiveTaskCondition.DefaultCategory) {
        self.init(defaultCategory.rawValue)
    }
    
    public init(_ categoryName: String) {
        super.init(subconditions: nil, dependencyTask: nil) { result in
            let queue = MutuallyExclusiveTaskCondition.add(categoryName)
            dispatch_async(queue) {
                result(.Satisfied)
                MutuallyExclusiveTaskCondition.remove(categoryName)
            }
        }
    }
    
    private static func add(categoryName: String) -> dispatch_queue_t {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)

        let queue: dispatch_queue_t

        if self.mutuallyExclusiveTaskConditions[categoryName] == nil {
            let newQueue = dispatch_queue_create("com.alecrim.AlecrimAsyncKit.MutuallyExclusiveTaskCondition." + categoryName, DISPATCH_QUEUE_SERIAL)
            self.mutuallyExclusiveTaskConditions[categoryName] = (newQueue, 1)
            queue = newQueue
        }
        else {
            self.mutuallyExclusiveTaskConditions[categoryName]!.count++
            queue = self.mutuallyExclusiveTaskConditions[categoryName]!.queue
        }
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
        
        return queue
    }
    
    private static func remove(categoryName: String) {
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        
        if self.mutuallyExclusiveTaskConditions[categoryName] != nil {
            self.mutuallyExclusiveTaskConditions[categoryName]!.count--
            
            if self.mutuallyExclusiveTaskConditions[categoryName]!.count == 0 {
                self.mutuallyExclusiveTaskConditions.removeValueForKey(categoryName)
            }
        }
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
    }
    
}
