//
//  ObjectValueCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2016-05-20.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

public final class ObjectValueCondition: TaskCondition {
    
    public init(object: NSObject, keyPath: String, evaluationClosure: @escaping (Any?) -> Bool) {
        super.init() { result in
            let _ = ValueObserver(object: object, keyPath: keyPath, evaluationClosure: evaluationClosure) { satisfied in
                if satisfied {
                    result(.satisfied)
                }
            }
        }
    }
    
}

// MARK: -

private final class ValueObserver: NSObject {
    
    private var context = 0
    private var observing = false
    
    private let object: NSObject
    private let keyPath: String
    private let evaluationClosure: (Any?) -> Bool
    private let callbackClosure: (Bool) -> Void
    
    fileprivate init(object: NSObject, keyPath: String, evaluationClosure: @escaping (Any?) -> Bool, callbackClosure: @escaping (Bool) -> Void) {
        self.object = object
        self.keyPath = keyPath
        self.evaluationClosure = evaluationClosure
        self.callbackClosure = callbackClosure
        
        super.init()

        self.startObserving()
    }
    
    deinit {
        self.stopObserving()
    }
    
    fileprivate override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.context {
            if let newValue = change?[NSKeyValueChangeKey.newKey] {
                let satisfied = self.evaluationClosure(newValue)
                self.callbackClosure(satisfied)
                
                if satisfied {
                    self.stopObserving()
                }
            }
        }
    }
    
    private func startObserving() {
        self.object.addObserver(self, forKeyPath: self.keyPath, options: [.initial, .new], context: &self.context)
        self.observing = true
    }
    
    private func stopObserving() {
        guard self.observing else { return }
        
        self.object.removeObserver(self, forKeyPath: self.keyPath, context: &self.context)
        self.observing = false
    }
    
}
