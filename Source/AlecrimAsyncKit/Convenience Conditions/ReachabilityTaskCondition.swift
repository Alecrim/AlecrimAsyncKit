//
//  ReachabilityTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if os(OSX) || os(iOS)

import Foundation
import SystemConfiguration

public final class ReachabilityTaskCondition: TaskCondition {
    
    private static var reachabilityRefs = [String : SCNetworkReachability]()

    private static func asyncRequestReachabilityForURL(URL: NSURL) -> NonFailableTask<Bool> {
        return async {
            guard let host = URL.host else { return false }
            
            var ref = self.reachabilityRefs[host]
            
            if ref == nil {
                let hostString = host as NSString
                ref = SCNetworkReachabilityCreateWithName(nil, hostString.UTF8String)
            }
            
            if let ref = ref {
                self.reachabilityRefs[host] = ref
                
                var reachable = false
                var flags: SCNetworkReachabilityFlags = []
                if SCNetworkReachabilityGetFlags(ref, &flags) {
                    /*
                    Note that this is a very basic "is reachable" check.
                    Your app may choose to allow for other considerations,
                    such as whether or not the connection would require
                    VPN, a cellular connection, etc.
                    */
                    reachable = flags.contains(.Reachable)
                }
                
                return reachable
            }
            else {
                return false
            }
        }
    }
    
    public init(URL: NSURL) {
        super.init() { result in
            if await(ReachabilityTaskCondition.asyncRequestReachabilityForURL(URL)) {
                result(.Satisfied)
            }
            else {
                result(.NotSatisfied)
            }
        }
    }
    
}

#endif
