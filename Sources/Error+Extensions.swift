//
//  Errors.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 09/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

extension Error {
    internal var isUserCancelled: Bool {
        let error = self as NSError
        return error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError
    }
}

//extension CustomNSError {
//    internal var isUserCancelled: Bool {
//        return type(of: self).errorDomain == NSCocoaErrorDomain && self.errorCode == NSUserCancelledError
//    }
//}

// MAR: -

fileprivate let _userCancelledError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)

extension Error {
    internal static var userCancelled: Error { return _userCancelledError }
}
