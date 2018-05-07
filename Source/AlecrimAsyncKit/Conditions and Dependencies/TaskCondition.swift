//
//  TaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 05/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

//
// example:
//
// extension Reachability: TaskCondition {
//     public func evaluate() -> Bool {
//         return self.connection != .none
//     }
// }
//
// ...
//
// async(condition: self.reachability) { ... }
//

public protocol TaskCondition {
    // this will always be executed on a background thread, so the result does not need to me immediately computed
    func evaluate() -> Bool
}

// MARK: -

// boolean tasks can be used as conditions too

extension BaseTask: TaskCondition where Value == Bool {
    public func evaluate() -> Bool {
        do {
            return try self.await()
        }
        catch {
            return false
        }
    }
}

// MARK: -

// ex: let mtc = ManualTaskCondition(); ...; ...; ...; mtc.result = true

public final class ManualTaskCondition: BaseTask<Bool> {
    public init() {
        super.init(dependency: nil, condition: nil, closure: { _ in })
    }

    public var result = false {
        didSet {
            self.finish(with: self.result)
        }
    }
}


// MARK: -

public final class CompoundTaskCondition: TaskCondition {
    public enum LogicalType: UInt {
        case not = 0
        case and
        case or
    }

    public let compoundTaskConditionType: LogicalType
    public let subconditions: [TaskCondition]

    public convenience init(andConditionWithSubconditions subconditions: [TaskCondition]) {
        self.init(type: .and, subconditions: subconditions)
    }

    public convenience init(orConditionWithSubconditions subconditions: [TaskCondition]) {
        self.init(type: .or, subconditions: subconditions)

    }

    public convenience init(notConditionWithSubcondition subcondition: TaskCondition) {
        self.init(type: .and, subconditions: [subcondition])
    }

    public init(type: LogicalType, subconditions: [TaskCondition]) {
        precondition(subconditions.count > 0)
        precondition(type == .not ? subconditions.count == 1 : true)

        self.compoundTaskConditionType = type
        self.subconditions = subconditions
    }

    public func evaluate() -> Bool {
        switch self.compoundTaskConditionType {
        case .and:
            var all = true
            for subcondition in self.subconditions {
                if !subcondition.evaluate()  {
                    all = false
                    break
                }
            }

            return all

        case .or:
            var any = false
            for subcondition in self.subconditions {
                if subcondition.evaluate() {
                    any = true
                    break
                }
            }

            return any

        case .not:
            let subcondition = self.subconditions.first!
            return !subcondition.evaluate()
        }
    }

}

// So we can use: async(condition: (condition1 || condition2) && condition3 && !condition4) { ... }

public func &&(left: TaskCondition, right: TaskCondition) -> TaskCondition {
    return CompoundTaskCondition(type: .and, subconditions: [left, right])
}

public func ||(left: TaskCondition, right: TaskCondition) -> TaskCondition {
    return CompoundTaskCondition(type: .or, subconditions: [left, right])
}

prefix public func !(left: TaskCondition) -> TaskCondition {
    return CompoundTaskCondition(type: .not, subconditions: [left])
}
