//
//  DispatchQueue+Extensions.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2016-12-03.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

extension DispatchQueue {
    
    @discardableResult
    public func asyncTask<V>(using closure: @escaping () -> V) -> NonFailableTask<V> {
        return asyncEx { task in
            self.async {
                task.finish(with: closure())
            }
        }
    }
    
}
