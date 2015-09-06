//
//  Errors.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

/// The possible errors related to task condition evalution.
///
/// - NotSatisfied: The condition was not satisfied.
/// - Failed:       The condition evaluation was failed with an error.
public enum TaskConditionError: ErrorType {
    case NotSatisfied
    case Failed(ErrorType)
}

// MARK: -

internal let taskCancelledError = NSError(code: NSUserCancelledError)

// MARK: -

extension NSError {

    private convenience init(code: Int, userInfo dict: [NSObject : AnyObject]? = nil) {
        self.init(domain: "com.alecrim.AlecrimAsyncKit", code: code, userInfo: dict)
    }
    
}
