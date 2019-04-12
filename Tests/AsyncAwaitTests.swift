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

        func doSomething1() -> Task<Void, Error> {
            return async {
                Thread.sleep(forTimeInterval: 1)

                guard !$0.isCancelled else {
                    return
                }

                value += 1
                $0.finish()
            }
        }

        func doSomething2() -> Task<Void, Error> {
            return async {
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

        XCTAssert(value == 2)
    }

    func testBackgroundExecution() {
        var value = 0
        var taskCount = 0

        func doSomething1() -> Task<Int, Never> {
            return async {
                taskCount += 1

                Thread.sleep(forTimeInterval: 1)
                $0.finish(with: 1)
            }
        }

        func doSomething2() -> Task<Int, Never> {
            return async {
                taskCount += 1

                Thread.sleep(forTimeInterval: 3)
                $0.finish(with: 3)
            }
        }

        value += 1

        let task1 = doSomething1()
        let task2 = doSomething2()

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssert(taskCount == 2)

        value += await(task1)
        value += await(task2)

        XCTAssert(value == 5)
    }
}
