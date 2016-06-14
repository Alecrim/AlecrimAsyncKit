//
//  MutuallyExclusiveCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

private final class Semaphore {
    private let dispatchSemaphore: DispatchSemaphore
    private var count: Int
    
    private init(dispatchSemaphore: DispatchSemaphore, count: Int) {
        self.dispatchSemaphore = dispatchSemaphore
        self.count = count
    }
}

public let MutuallyExclusiveAlertCondition = MutuallyExclusiveCondition(category: .alert)

/// A condition for describing kinds of operations that may not execute concurrently.
public final class MutuallyExclusiveCondition: TaskCondition {

    /// An enumeration with the default categories used by the condition.
    ///
    /// - Alert: The category that represents a potential modal alert to the user.
    private enum Category: String {
        case alert = "_CAAAK.METC.DC.Alert"
    }

    private static var spinlock = OS_SPINLOCK_INIT
    private static var mutuallyExclusiveSemaphores = [String : Semaphore]()

    /// The category name that will define the condition exclusivity group.
    public let categoryName: String
    private var waiting: Bool = false
    
    /// Initialize a condition for describing kinds of operations that may not execute concurrently.
    ///
    /// - parameter defaultCategory: The default category enumeration member that will define the condition exclusivity group.
    ///
    /// - returns: A condition for describing kinds of operations that may not execute concurrently.
    private convenience init(category: MutuallyExclusiveCondition.Category) {
        self.init(name: category.rawValue)
    }
    
    /// Initializes a condition for describing kinds of operations that may not execute concurrently.
    ///
    /// - parameter categoryName: The category name that will define the condition exclusivity group.
    ///
    /// - returns: A condition for describing kinds of operations that may not execute concurrently.
    public init(name categoryName: String) {
        self.categoryName = categoryName
        super.init(evaluationClosureAssignmentDeferred: true)
        
        self.evaluationClosure = { [unowned self] result in
            MutuallyExclusiveCondition.wait(for: self, categoryName: categoryName)
            result(.satisfied)
        }
    }
    
    private static func wait(for condition: MutuallyExclusiveCondition, categoryName: String) {
        let dispatchSemaphore: DispatchSemaphore
        
        do {
            withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
            defer { withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock) }
            
            if let semaphore = self.mutuallyExclusiveSemaphores[categoryName] {
                semaphore.count += 1
                dispatchSemaphore = semaphore.dispatchSemaphore
            }
            else {
                let semaphore = Semaphore(dispatchSemaphore: DispatchSemaphore(value: 1), count: 1)
                self.mutuallyExclusiveSemaphores[categoryName] = semaphore
                dispatchSemaphore = semaphore.dispatchSemaphore
            }
            
            condition.waiting = true
        }
        
        dispatchSemaphore.wait()
    }
    
    internal static func signal(condition: MutuallyExclusiveCondition, categoryName: String) {
        let dispatchSemaphore: DispatchSemaphore
        
        withUnsafeMutablePointer(&self.spinlock, OSSpinLockLock)
        defer { withUnsafeMutablePointer(&self.spinlock, OSSpinLockUnlock) }
        
        if condition.waiting {
            condition.waiting = false

            let semaphore = self.mutuallyExclusiveSemaphores[categoryName]!
            semaphore.count -= 1
            dispatchSemaphore = semaphore.dispatchSemaphore
            
            if semaphore.count == 0 {
                self.mutuallyExclusiveSemaphores[categoryName] = nil
            }
            
            dispatchSemaphore.signal()
        }
    }
    
}
