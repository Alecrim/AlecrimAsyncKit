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

    func testCancellation() {
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

        do {
            try await(task1)
        }
        catch {
            XCTFail()
        }

        do {
            try await(task2)
            XCTFail()
        }
        catch {
            XCTAssert((error as NSError).isUserCancelled)
        }

        XCTAssert(something2IsCancelled)
        XCTAssert(value == -8)
    }

    func testCascadeCancel() {
        var finishedTaskCount = 0

        func someTask1(with value: Int) -> Task<Int, Error> {
            return async { t in
                finishedTaskCount += 1
                t.finish(with: value)
            }
        }

        func someTask2(with value: Int) -> Task<Int, Error> {
            return async { t in
                self.doNothing(forTimeInterval: 1) {
                    do {
                        try await(someTask1(with: 1))
                        try await(someTask1(with: 2))
                        try await(someTask1(with: 3))

                        finishedTaskCount += 1
                        t.finish(with: value)
                    }
                    catch {
                        t.finish(with: error)
                    }
                }
            }
        }

        func someTask3(with value: Int) -> Task<Int, Error> {
            return async { t in
                self.doNothing(forTimeInterval: 1) {
                    do {

                        try await(someTask2(with: 10))
                        try await(someTask2(with: 20))
                        try await(someTask2(with: 30))

                        finishedTaskCount += 1
                        t.finish(with: value)
                    }
                    catch {
                        t.finish(with: error)
                    }
                }
            }
        }

        let t = someTask3(with: 100)

        self.doNothing(forTimeInterval: 2) {
            t.cancel()
        }

        //
        do {
            try await(t)
            XCTFail()
        }
        catch {
            XCTAssert(finishedTaskCount < 13)
        }

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
