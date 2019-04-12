//
//  AsyncAwaitBasicTests.swift
//  AlecrimAsyncKitTests
//
//  Created by Vanderlei Martinelli on 11/04/19.
//  Copyright © 2019 Alecrim. All rights reserved.
//

import XCTest
@testable import AlecrimAsyncKit

class AsyncAwaitBasicTests: XCTestCase {

    // MARK: -

    private let executeQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKitTests.AsyncAwaitBasicTests", attributes: .concurrent)

    // MARK: -

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: -

    func testImmediateValue() {
        let task: Task<Int, Error> = async {
            return 10
        }

        XCTAssert(task.isCancelled == false)

        do {
            let value = try await(task)
            XCTAssert(value == 10)
        }
        catch {
            XCTFail()
        }

        task.cancel()
        XCTAssert(task.isCancelled == false)
    }

    func testImmediateError() {
        let errorDomain = "com.alecrim.AlecrimAsyncKitTests"
        let errorCode = 1000

        let task: Task<Int, Error> = async {
            throw NSError(domain: errorDomain, code: errorCode, userInfo: nil)
        }

        XCTAssert(task.isCancelled == false)

        do {
            let _ = try await(task)
            XCTFail()
        }
        catch {
            let error = error as NSError
            XCTAssert(error.domain == errorDomain)
            XCTAssert(error.code == errorCode)
        }

        task.cancel()
        XCTAssert(task.isCancelled == false)
    }

    func testNonFailableImmediateValue() {
        let task: Task<Int, Never> = async {
            return 10
        }

        let value = await(task)
        XCTAssert(value == 10)
    }

    func testValue() {
        let task: Task<Int, Error> = async {
            Thread.sleep(forTimeInterval: 1)
            return 10
        }

        XCTAssert(task.isCancelled == false)

        do {
            let value = try await(task)
            XCTAssert(value == 10)
        }
        catch {
            XCTFail()
        }

        task.cancel()
        XCTAssert(task.isCancelled == false)
    }

    func testError() {
        let errorDomain = "com.alecrim.AlecrimAsyncKitTests"
        let errorCode = 1000

        let task: Task<Int, Error> = async {
            Thread.sleep(forTimeInterval: 1)
            throw NSError(domain: errorDomain, code: errorCode, userInfo: nil)
        }

        XCTAssert(task.isCancelled == false)

        do {
            let _ = try await(task)
            XCTFail()
        }
        catch {
            let error = error as NSError
            XCTAssert(error.domain == errorDomain)
            XCTAssert(error.code == errorCode)
        }

        task.cancel()
        XCTAssert(task.isCancelled == false)
    }

    func testCustomError() {
        enum CustomError: Error {
            case general
        }

        let task: Task<Int, Error> = async {
            Thread.sleep(forTimeInterval: 1)
            throw CustomError.general
        }

        XCTAssert(task.isCancelled == false)

        do {
            let _ = try await(task)
            XCTFail()
        }
        catch CustomError.general {
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }

        task.cancel()
        XCTAssert(task.isCancelled == false)
    }


    func testNonFailableValue() {
        let task: Task<Int, Never> = async {
            Thread.sleep(forTimeInterval: 1)
            return 10
        }

        let value = await(task)
        XCTAssert(value == 10)
    }

    func testCancel() {
        let errorDomain = "com.alecrim.AlecrimAsyncKitTests"
        let errorCode = 1000

        let task: Task<Int, Error> = async {
            Thread.sleep(forTimeInterval: 1)
            throw NSError(domain: errorDomain, code: errorCode, userInfo: nil)
        }

        XCTAssert(task.isCancelled == false)

        task.cancel()
        XCTAssert(task.isCancelled == true)

        do {
            let _ = try await(task)
            XCTFail()
        }
        catch {
            let error = error as NSError
            XCTAssert(error.domain != errorDomain)
            XCTAssert(error.code != errorCode)
            XCTAssert(error.isUserCancelled)
        }

        task.cancel()
        XCTAssert(task.isCancelled == true)
    }

    // MARK: -

    func testFinishingWithValue() {
        let task: Task<Int, Error> = async {
            Thread.sleep(forTimeInterval: 1)
            $0.finish(with: 10)
        }

        XCTAssert(task.isCancelled == false)

        do {
            let value = try await(task)
            XCTAssert(value == 10)
        }
        catch {
            XCTFail()
        }

        task.cancel()
        XCTAssert(task.isCancelled == false)
    }

    func testFinishingWithError() {
        let errorDomain = "com.alecrim.AlecrimAsyncKitTests"
        let errorCode = 1000

        let task: Task<Int, Error> = async {
            Thread.sleep(forTimeInterval: 1)
            $0.finish(with: NSError(domain: errorDomain, code: errorCode, userInfo: nil))
        }

        XCTAssert(task.isCancelled == false)

        do {
            let _ = try await(task)
            XCTFail()
        }
        catch {
            let error = error as NSError
            XCTAssert(error.domain == errorDomain)
            XCTAssert(error.code == errorCode)
        }

        task.cancel()
        XCTAssert(task.isCancelled == false)
    }

    func testFinishingWithNonFailableValue() {
        let task: Task<Int, Never> = async {
            Thread.sleep(forTimeInterval: 1)
            $0.finish(with: 10)
        }

        let value = await(task)
        XCTAssert(value == 10)
    }


}
