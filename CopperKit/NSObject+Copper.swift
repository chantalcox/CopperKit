//
//  NSObject+Copper.swift
//  Copper
//
//  Created by Doug Williams on 12/3/15.
//  Copyright © 2015 Copper Technologies, Inc. All rights reserved.
//

import Foundation

extension NSObject {
    
    public var className: String {
        return NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!
    }
    
}