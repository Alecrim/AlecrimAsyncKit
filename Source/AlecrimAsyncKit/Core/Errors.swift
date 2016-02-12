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

extension NSError {
    
    public static func userCancelledError(domain domain: String = NSCocoaErrorDomain, userInfo dict: [NSObject : AnyObject]? = nil) -> NSError {
        return NSError(domain: domain, code: NSUserCancelledError, userInfo: dict)
    }
    
}

extension ErrorType {
    
    public var isUserCancelled: Bool {
        return (self as NSError).code == NSUserCancelledError
    }
    
}