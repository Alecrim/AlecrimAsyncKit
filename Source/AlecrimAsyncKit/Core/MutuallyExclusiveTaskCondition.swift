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
        case Alert = "com.alecrim.AlecrimAsyncKit.MutuallyExclusiveTaskCondition.DefaultCategory.Alert"
    }

    private static var mutuallyExclusiveSemaphores = [String: (semaphore: dispatch_semaphore_t, count: Int)]()
    private static var spinlock = OS_SPINLOCK_INIT

    public convenience init(_ defaultCategory: MutuallyExclusiveTaskCondition.DefaultCategory) {
        self.init(defaultCategory.rawValue)
    }
    
    public let categoryName: String
    
    public init(_ categoryName: String) {
        self.categoryName = categoryName

        super.init() { result in
            result(.Satisfied)
        }
    }
    
    internal static func increment(categoryName: String) {
        let semaphore: dispatch_semaphore_t
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)

        if self.mutuallyExclusiveSemaphores[categoryName] == nil {
            semaphore = dispatch_semaphore_create(1)
            self.mutuallyExclusiveSemaphores[categoryName] = (semaphore, 1)
        }
        else {
            semaphore = self.mutuallyExclusiveSemaphores[categoryName]!.semaphore
            self.mutuallyExclusiveSemaphores[categoryName]!.count++
        }

        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    internal static func decrement(categoryName: String) {
        let semaphore: dispatch_semaphore_t
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)

        semaphore = self.mutuallyExclusiveSemaphores[categoryName]!.semaphore

        self.mutuallyExclusiveSemaphores[categoryName]!.count--
        
        if self.mutuallyExclusiveSemaphores[categoryName]!.count == 0 {
            self.mutuallyExclusiveSemaphores.removeValueForKey(categoryName)
        }
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock)
        
        dispatch_semaphore_signal(semaphore)
    }
    
}
