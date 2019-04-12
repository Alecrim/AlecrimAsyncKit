//
//  TaskAwaiterTests.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 12/04/19.
//  Copyright © 2019 Alecrim. All rights reserved.
//

import XCTest
@testable import AlecrimAsyncKit

class TaskAwaiterTests: XCTestCase {

    // MARK: -

    private let executeQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKitTests.AsyncAwaitTests", attributes: .concurrent)

    // MARK: -

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: -

    func testSimple() {
        var value = 0

        func doSomething1() -> Task<Void, Never> {
            return async {
                Thread.sleep(forTimeInterval: 1)
                value += 1
            }
        }

        func doSomething2() -> Task<Void, Never> {
            return async {
                Thread.sleep(forTimeInterval: 3)
                value += 3
            }
        }

        value += 1

        let expectation = self.expectation()
        expectation.expectedFulfillmentCount = 2

        doSomething1().then {
            expectation.fulfill()
        }

        doSomething2().then {
            expectation.fulfill()
        }


        self.wait()
        XCTAssert(value == 5)
    }

    func testCancel() {
        var value = 0
        var something2IsCancelled = false

        func doSomething1() -> Task<Void, Error> {
            return async { t in
                self.doNothing(forTimeInterval: 1) {
                    guard !t.isCancelled else {
                        return
                    }

                    value += 1
                    t.finish()
                }
            }
        }

        func doSomething2() -> Task<Void, Error> {
            return async(on: self.executeQueue) {
                $0.cancellation += {
                    something2IsCancelled = true
                }

                $0.cancellation += {
                    value -= 10
                }

                guard !$0.isCancelled else {
                    return
                }

                Thread.sleep(forTimeInterval: 3)
                value += 3
                $0.finish()
            }
        }

        value += 1

        let task1 = doSomething1()
        let task2 = doSomething2()

        task2.cancel()

        let expectation = self.expectation()
        expectation.expectedFulfillmentCount = 2

        task1.then {
            expectation.fulfill()
        }

        task2.cancelled {
            expectation.fulfill()
        }

        self.wait()

        XCTAssert(something2IsCancelled)
        XCTAssert(value == -8)
    }

    func testBackgroundExecution() {
        var value = 0
        var taskCount = 0

        func doSomething1() -> Task<Int, Never> {
            return async { t in
                taskCount += 1

                self.doNothing(forTimeInterval: 1) {
                    t.finish(with: 1)
                }
            }
        }

        func doSomething2() -> Task<Int, Never> {
            return async { t in
                taskCount += 1

                self.doNothing(forTimeInterval: 3) {
                    t.finish(with: 3)
                }
            }
        }

        func doSomething3() -> Task<Int, Error> {
            return async {
                taskCount += 1

                let errorDomain = "com.alecrim.AlecrimAsyncKitTests"
                let errorCode = 1000

                throw NSError(domain: errorDomain, code: errorCode, userInfo: nil)
            }
        }


        value += 1

        let task1 = doSomething1()
        let task2 = doSomething2()
        let task3 = doSomething3()

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssert(taskCount == 3)
        XCTAssert(value == 1)

        let expectation = self.expectation()
        expectation.expectedFulfillmentCount = 4

        task1.then {
            value += $0
            expectation.fulfill()
        }

        task2.then {
            value += $0
            expectation.fulfill()
        }

        task3
            .then {
                value += $0
            }
            .catch { _ in
                expectation.fulfill()
            }
            .finally {
                expectation.fulfill()
        }

        self.wait()

        XCTAssert(value == 5)
    }
}

// MARK: -

extension TaskAwaiterTests {

    fileprivate func expectation() -> XCTestExpectation {
        return self.expectation(description: "GenericExpectation")
    }

    fileprivate func wait(_ timeout: TimeInterval = 10.0, handler: XCWaitCompletionHandler? = nil) {
        waitForExpectations(timeout: timeout, handler: handler)
    }

    fileprivate func doNothing(forTimeInterval timeInterval: TimeInterval, completionHandler: @escaping () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
            completionHandler()
        }
    }

}

