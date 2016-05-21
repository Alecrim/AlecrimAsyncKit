//
//  ObjectValueTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2016-05-20.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

public final class ObjectValueTaskCondition: TaskCondition {
    
    public init(object: NSObject, keyPath: String, evaluationClosure: (AnyObject?) -> Bool) {
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
    
    private let object: AnyObject
    private let keyPath: String
    private let evaluationClosure: (AnyObject?) -> Bool
    private let callbackClosure: ((Bool) -> Void)
    
    private init(object: NSObject, keyPath: String, evaluationClosure: (AnyObject?) -> Bool, callbackClosure: ((Bool) -> Void)) {
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
    
    private override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &self.context {
            if let newValue = change?[NSKeyValueChangeNewKey] {
                let satisfied = self.evaluationClosure(newValue)
                self.callbackClosure(satisfied)
                
                if satisfied {
                    self.stopObserving()
                }
            }
        }
    }
    
    private func startObserving() {
        self.object.addObserver(self, forKeyPath: self.keyPath, options: [.Initial, .New], context: &self.context)
        self.observing = true
    }
    
    private func stopObserving() {
        guard self.observing else { return }
        
        self.object.removeObserver(self, forKeyPath: self.keyPath, context: &self.context)
        self.observing = false
    }
    
}
