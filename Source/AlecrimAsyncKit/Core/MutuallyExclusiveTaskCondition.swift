//
//  MutuallyExclusiveTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private final class Semaphore {
    private let group: dispatch_group_t
    private var count: Int
    
    private init(group: dispatch_group_t, count: Int) {
        self.group = group
        self.count = count
    }
}

/// A condition for describing kinds of operations that may not execute concurrently.
public final class MutuallyExclusiveTaskCondition: TaskCondition {

    /// An enumeration with the default categories used by the condition.
    ///
    /// - Alert: The category that represents a potential modal alert to the user.
    public enum DefaultCategory: String {
        case Alert = "_CAAAK.METC.DC.Alert"
    }

    private static var spinlock = OS_SPINLOCK_INIT
    private static var mutuallyExclusiveSemaphores = [String : Semaphore]()

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
            MutuallyExclusiveTaskCondition.wait(categoryName)
            result(.Satisfied)
        }
    }
    
    private static func wait(categoryName: String) {
        let group: dispatch_group_t?
        
        do {
            withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
            defer { withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock) }

            group = self.mutuallyExclusiveSemaphores[categoryName]?.group
        }
        
        if let group = group {
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        }
    }
    
    internal static func enter(categoryName: String) {
        let group: dispatch_group_t
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        defer { withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock) }

        if let semaphore = self.mutuallyExclusiveSemaphores[categoryName] {
            semaphore.count++
            group = semaphore.group
        }
        else {
            let semaphore = Semaphore(group: dispatch_group_create(), count: 1)
            self.mutuallyExclusiveSemaphores[categoryName] = semaphore
            group = semaphore.group
        }
        
        dispatch_group_enter(group)
    }
    
    internal static func leave(categoryName: String) {
        let group: dispatch_group_t
        
        do {
            withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
            defer { withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock) }
            
            let semaphore = self.mutuallyExclusiveSemaphores[categoryName]!
            semaphore.count--
            group = semaphore.group
            
            if semaphore.count == 0 {
                self.mutuallyExclusiveSemaphores[categoryName] = nil
            }
        }
        
        dispatch_group_leave(group)
    }
    
}
