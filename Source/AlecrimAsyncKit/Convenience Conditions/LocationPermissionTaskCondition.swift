//
//  LocationPermissionTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreLocation

/// A condition for verifying access to the user's location.
public final class LocationPermissionTaskCondition: TaskCondition {
    
    public enum Usage {
        case WhenInUse
        case Always
    }
    
    private static func asyncRequestAuthorizationIfNeededForUsage(usage: LocationPermissionTaskCondition.Usage) -> Task<Void> {
        return asyncEx(condition: MutuallyExclusiveTaskCondition(.Alert)) { task in
            /*
            Not only do we need to handle the "Not Determined" case, but we also
            need to handle the "upgrade" (.WhenInUse -> .Always) case.
            */
            switch (CLLocationManager.authorizationStatus(), usage) {
            case (.NotDetermined, _), (.AuthorizedWhenInUse, .Always):
                let locationManager = LocationManager()
                locationManager.didChangeAuthorizationStatusClosure = { status in
                    task.finish()
                }
                
                let key: String
                
                switch usage {
                case .WhenInUse:
                    key = "NSLocationWhenInUseUsageDescription"
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        locationManager.requestWhenInUseAuthorization()
                    }
                    
                case .Always:
                    key = "NSLocationAlwaysUsageDescription"
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        locationManager.requestAlwaysAuthorization()
                    }
                }
                
                // This is helpful when developing the app.
                assert(NSBundle.mainBundle().objectForInfoDictionaryKey(key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")

                
            default:
                task.finish()
            }
        }
    }

    public init(usage: LocationPermissionTaskCondition.Usage) {
        super.init(dependencyTask: LocationPermissionTaskCondition.asyncRequestAuthorizationIfNeededForUsage(usage)) { result in
            let enabled = CLLocationManager.locationServicesEnabled()
            let actual = CLLocationManager.authorizationStatus()
            
            // There are several factors to consider when evaluating this condition
            switch (enabled, usage, actual) {
            case (true, _, .AuthorizedAlways):
                // The service is enabled, and we have "Always" permission -> condition satisfied.
                result(.Satisfied)
                
            case (true, .WhenInUse, .AuthorizedWhenInUse):
                // The service is enabled, and we have and need "WhenInUse" permission -> condition satisfied.
                result(.Satisfied)
                
            default:
                /*
                Anything else is an error. Maybe location services are disabled,
                or maybe we need "Always" permission but only have "WhenInUse",
                or maybe access has been restricted or denied,
                or maybe access hasn't been request yet.
                
                The last case would happen if this condition were wrapped in a `SilentCondition`.
                */
                result(.NotSatisfied)
            }
        }
    }
    
}

private final class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    
    private var didChangeAuthorizationStatusClosure: ((CLAuthorizationStatus) -> Void)? = nil
    
    private override init() {
        super.init()
        self.delegate = self
    }
    
    @objc private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.didChangeAuthorizationStatusClosure?(status)
        
        self.delegate = nil
        self.didChangeAuthorizationStatusClosure = nil
    }
    
}
