//
//  NSError+Copper.swift
//  Copper
//
//  Created by Doug Williams on 12/3/15.
//  Copyright © 2015 Copper Technologies, Inc. All rights reserved.
//

import Foundation

extension NSError {

    public var dictionary: [String:AnyObject] {
        var dict = [String:AnyObject]()
        for (key, value) in self.userInfo {
            if let key = key as? String {
                dict[key] = value
            }
        }
        dict["description"] = self.localizedDescription
        dict["code"] = self.code
        dict["domain"] = self.domain
        return dict
    }
}