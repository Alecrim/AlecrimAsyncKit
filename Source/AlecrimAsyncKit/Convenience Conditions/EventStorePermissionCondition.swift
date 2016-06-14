//
//  EventStorePermissionCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-06.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if !os(tvOS)

import Foundation
import EventKit

// `EKEventStore` takes a while to initialize, so we use a shared instance.
private let _sharedEventStore = EKEventStore()

/// A condition for verifying access to the user's calendar.
public final class EventStorePermissionCondition: TaskCondition {
    
    @warn_unused_result
    private static func requestAuthorization(entityType: EKEntityType) -> Task<Void> {
        return asyncEx(conditions: [MutuallyExclusiveAlertCondition]) { task in
            let status = EKEventStore.authorizationStatus(for: entityType)

            switch status {
            case .notDetermined:
                Queue.mainQueue.async() {
                    _sharedEventStore.requestAccess(to: entityType) { _, error in
                        if let error = error {
                            task.finish(with: error)
                        }
                        else {
                            task.finish()
                        }
                    }
                }
                
            default:
                task.finish()
            }
        }
    }
    
    /// Initializes a condition for verifying access to the user's calendar.
    ///
    /// - parameter entityType: The authorization needed (event or reminder).
    ///
    /// - returns: A condition for verifying access to the user's calendar.
    public init(entityType: EKEntityType) {
        super.init(dependencyTask: EventStorePermissionCondition.requestAuthorization(entityType: entityType)) { result in
            switch EKEventStore.authorizationStatus(for: entityType) {
            case .authorized:
                result(.satisfied)
                
            default:
                result(.notSatisfied)
            }
        }
    }
    
}

#endif
