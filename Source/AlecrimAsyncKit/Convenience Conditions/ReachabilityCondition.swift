//
//  ReachabilityCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if os(OSX) || os(iOS)

import Foundation
import SystemConfiguration

/// A condition that performs network reachability check.
public final class ReachabilityCondition: TaskCondition {
    
    /// Initializes a condition that performs network reachability check.
    ///
    /// - parameter URL: The URL containing the host to test the reachability.
    ///
    /// - returns: A condition that performs network reachability check.
    public init(url: URL) {
        super.init() { result in
            if requestReachability(for: url) {
                result(.satisfied)
            }
            else {
                result(.notSatisfied)
            }
        }
    }
    
}

// MARK: -
    
private var reachabilityRefs = [String : SCNetworkReachability]()

private func requestReachability(for url: URL) -> Bool {
    guard let host = url.host else { return false }
    
    var ref = reachabilityRefs[host]
    
    if ref == nil {
        if let utf8String = (host as NSString).utf8String {
            ref = SCNetworkReachabilityCreateWithName(nil, utf8String)
        }
    }
    
    if let ref = ref {
        reachabilityRefs[host] = ref
        
        var reachable = false
        var flags: SCNetworkReachabilityFlags = []
        
        if SCNetworkReachabilityGetFlags(ref, &flags) {
            /*
            Note that this is a very basic "is reachable" check.
            Your app may choose to allow for other considerations,
            such as whether or not the connection would require
            VPN, a cellular connection, etc.
            */
            reachable = flags.contains(.reachable)
        }
        
        return reachable
    }
    else {
        return false
    }
}

#endif
