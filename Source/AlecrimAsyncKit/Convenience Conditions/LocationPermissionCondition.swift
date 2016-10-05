//
//  LocationPermissionCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import CoreLocation

/// A condition for verifying access to the user's location.
public final class LocationPermissionCondition: TaskCondition {
    
    public enum Usage {
        case whenInUse
        case always
    }
    
    private static func requestAuthorizationIfNeeded(usage: LocationPermissionCondition.Usage) -> Task<Void> {
        return asyncEx(conditions: [MutuallyExclusiveAlertCondition]) { task in
            /*
            Not only do we need to handle the "Not Determined" case, but we also
            need to handle the "upgrade" (.WhenInUse -> .Always) case.
            */
            switch (CLLocationManager.authorizationStatus(), usage) {
            case (.notDetermined, _), (.authorizedWhenInUse, .always):
                let locationManager = LocationManager()
                locationManager.didChangeAuthorizationStatusClosure = { status in
                    task.finish()
                }
                
                let key: String
                
                switch usage {
                case .whenInUse:
                    key = "NSLocationWhenInUseUsageDescription"
                    Queue.mainQueue.async {
                        locationManager.requestWhenInUseAuthorization()
                    }
                    
                case .always:
                    key = "NSLocationAlwaysUsageDescription"
                    Queue.mainQueue.async {
                        locationManager.requestAlwaysAuthorization()
                    }
                }
                
                // This is helpful when developing the app.
                assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")

                
            default:
                task.finish()
            }
        }
    }

    /// Initializes a condition for verifying access to the user's location.
    ///
    /// - parameter usage: The needed usage (when app is in use only or always).
    ///
    /// - returns: A condition for verifying access to the user's location.
    public init(usage: LocationPermissionCondition.Usage) {
        super.init(dependencyTask: LocationPermissionCondition.requestAuthorizationIfNeeded(usage: usage)) { result in
            let enabled = CLLocationManager.locationServicesEnabled()
            let actual = CLLocationManager.authorizationStatus()
            
            // There are several factors to consider when evaluating this condition
            switch (enabled, usage, actual) {
            case (true, _, .authorizedAlways):
                // The service is enabled, and we have "Always" permission -> condition satisfied.
                result(.satisfied)
                
            case (true, .whenInUse, .authorizedWhenInUse):
                // The service is enabled, and we have and need "WhenInUse" permission -> condition satisfied.
                result(.satisfied)
                
            default:
                /*
                Anything else is an error. Maybe location services are disabled,
                or maybe we need "Always" permission but only have "WhenInUse",
                or maybe access has been restricted or denied,
                or maybe access hasn't been request yet.
                
                The last case would happen if this condition were wrapped in a `SilentCondition`.
                */
                result(.notSatisfied)
            }
        }
    }
    
}

private final class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    
    fileprivate var didChangeAuthorizationStatusClosure: ((CLAuthorizationStatus) -> Void)? = nil
    
    fileprivate override init() {
        super.init()
        self.delegate = self
    }
    
    @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.didChangeAuthorizationStatusClosure?(status)
        
        self.delegate = nil
        self.didChangeAuthorizationStatusClosure = nil
    }
    
}

#endif
