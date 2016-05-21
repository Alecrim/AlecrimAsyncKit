//
//  PhotosPermissionCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import Photos

/// A condition for verifying access to the user's Photos library.
public final class PhotosPermissionCondition: TaskCondition {
    
    @warn_unused_result
    private static func requestAuthorizationIfNeeded() -> Task<Void> {
        return asyncEx(conditions: [MutuallyExclusiveAlertCondition]) { task in
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if case .NotDetermined = authorizationStatus {
                dispatch_async(dispatch_get_main_queue()) {
                    PHPhotoLibrary.requestAuthorization { _ in
                        task.finish()
                    }
                }
            }
            else {
                task.finish()
            }
        }
    }

    /// Initializes a condition for verifying access to the user's Photos library.
    ///
    /// - returns: A condition for verifying access to the user's Photos library.
    public init() {
        super.init(dependencyTask: PhotosPermissionCondition.requestAuthorizationIfNeeded()) { result in
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if case .Authorized = authorizationStatus {
                result(.satisfied)
            }
            else {
                result(.notSatisfied)
            }
        }
    }
    
}

#endif
