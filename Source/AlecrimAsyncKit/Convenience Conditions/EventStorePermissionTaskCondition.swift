//
//  EventStorePermissionTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-06.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation
import EventKit

// `EKEventStore` takes a while to initialize, so we use a shared instance.
private let _sharedEventStore = EKEventStore()

/// A condition for verifying access to the user's calendar.
public final class EventStorePermissionTaskCondition: TaskCondition {
    
    private static func asyncRequestAuthorization(entityType: EKEntityType) -> Task<Void> {
        return asyncEx(condition: MutuallyExclusiveTaskCondition(.Alert)) { task in
            let status = EKEventStore.authorizationStatusForEntityType(entityType)

            switch status {
            case .NotDetermined:
                dispatch_async(dispatch_get_main_queue()) {
                    _sharedEventStore.requestAccessToEntityType(entityType) { _, error in
                        if let error = error {
                            task.finishWithError(error)
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
        super.init(dependencyTask: EventStorePermissionTaskCondition.asyncRequestAuthorization(entityType)) { result in
            switch EKEventStore.authorizationStatusForEntityType(entityType) {
            case .Authorized:
                result(.Satisfied)
                
            default:
                result(.NotSatisfied)
            }
        }
    }
    
}
