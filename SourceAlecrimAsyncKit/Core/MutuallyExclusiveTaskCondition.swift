//
//  MutuallyExclusiveTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

/// A condition for describing kinds of operations that may not execute concurrently.
public final class MutuallyExclusiveTaskCondition: TaskCondition {

    /// An enumeration with the default categories used by the condition.
    ///
    /// - Alert: The category that represents a potential modal alert to the user.
    public enum DefaultCategory: String {
        case Alert = "com.alecrim.AlecrimAsyncKit.MutuallyExclusiveTaskCondition.DefaultCategory.Alert"
    }

    private static var mutuallyExclusiveSemaphores = [String: (semaphore: dispatch_semaphore_t, count: Int)]()
    private static var spinlock = OS_SPINLOCK_INIT

    /// The category name that will define the condition exclusivity group.
    public let categoryName: String

    /// Initialize a condition for describing kinds of operations that may not execute concurrently.
    ///
    /// - parameter defaultCategory: The default category enumeration member that will define the condition exclusivity group.
    ///
    /// - returns: A condition for describing kinds of operations that may not execute concurrently.
    public convenience init(_ defaultCategory: MutuallyExclusiveTaskCondition.DefaultCategory) {
        self.init(defaultCategory.rawValue)
    }
    
    /// Initializes a condition for describing kinds of operations that may not execute concurrently.
    ///
    /// - parameter categoryName: The category name that will define the condition exclusivity group.
    ///
    /// - returns: A condition for describing kinds of operations that may not execute concurrently.
    public init(_ categoryName: String) {
        self.categoryName = categoryName

        super.init() { result in
            result(.Satisfied)
        }
    }
    
    internal static func increment(categoryName: String) {
        assert(!NSThread.isMainThread())
        
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
