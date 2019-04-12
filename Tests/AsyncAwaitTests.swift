//
//  AsyncAwaitTests.swift
//  AlecrimAsyncKitTests
//
//  Created by Vanderlei Martinelli on 11/04/19.
//  Copyright © 2019 Alecrim. All rights reserved.
//

import XCTest
@testable import AlecrimAsyncKit

class AsyncAwaitTests: XCTestCase {

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

        let task1 = doSomething1()
        let task2 = doSomething2()

        await(task1)
        await(task2)

        XCTAssert(value == 5)
    }

    func testCancel() {
        var value = 0
        var something2IsCancelled = false

        func doSomething1() -> Task<Void, Error> {
            return async { t in
                doNothing(forTimeInterval: 1) {
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

                Thread.sleep(forTimeInterval: 3)

                guard !$0.isCancelled else {
                    return
                }

                value += 3
                $0.finish()
            }
        }

        value += 1

        let task1 = doSomething1()
        let task2 = doSomething2()

        task2.cancel()

        do {
            try await(task1)
        }
        catch {
            XCTAssert(false)
        }

        do {
            try await(task2)
            XCTAssert(false)
        }
        catch {
            XCTAssert((error as NSError).isUserCancelled)
        }

        XCTAssert(something2IsCancelled)
        XCTAssert(value == -8)
    }

    func testBackgroundExecution() {
        var value = 0
        var taskCount = 0

        func doSomething1() -> Task<Int, Never> {
            return async { t in
                taskCount += 1

                doNothing(forTimeInterval: 1) {
                    t.finish(with: 1)
                }
            }
        }

        func doSomething2() -> Task<Int, Never> {
            return async { t in
                taskCount += 1

                doNothing(forTimeInterval: 3) {
                    t.finish(with: 3)
                }
            }
        }

        value += 1

        let task1 = doSomething1()
        let task2 = doSomething2()

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssert(taskCount == 2)
        XCTAssert(value == 1)

        value += await(task1)
        XCTAssert(value == 2)

        value += await(task2)
        XCTAssert(value == 5)
    }
}

// MARK: -

fileprivate func doNothing(forTimeInterval timeInterval: TimeInterval, completionHandler: @escaping () -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
        completionHandler()
    }
}

