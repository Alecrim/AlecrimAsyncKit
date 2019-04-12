//
//  XCTestCaseExtensions.swift
//  AlecrimAsyncKitTests
//
//  Created by Vanderlei Martinelli on 12/04/19.
//  Copyright © 2019 Alecrim. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func expectation() -> XCTestExpectation {
        return self.expectation(description: "GenericExpectation")
    }

    @discardableResult
    func expectNotification(_ name: Notification.Name, object: AnyObject? = nil, handler: XCTNSNotificationExpectation.Handler? = nil) -> XCTestExpectation {
        return self.expectation(forNotification: name, object: object, handler: handler)
    }

    func wait(_ timeout: TimeInterval = 10.0, handler: XCWaitCompletionHandler? = nil) {
        self.waitForExpectations(timeout: timeout, handler: handler)
    }

    func doNothing(forTimeInterval timeInterval: TimeInterval, completionHandler: @escaping () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
            completionHandler()
        }
    }

}
