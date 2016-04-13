//
//  LAContext+Copper.swift
//  Copper
//
//  Created by Benjamin Sandofsky on 9/2/15.
//  Copyright © 2015 Copper Technologies, Inc. All rights reserved.
//

import Foundation
import LocalAuthentication

extension LAContext {
    
    public func copper_canEvaluatePolicy(policy: LAPolicy) throws {
        var error : NSError?
        self.canEvaluatePolicy(policy, error: &error)
        if let error = error { throw error }
    }
    
}