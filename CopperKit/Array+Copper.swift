//
//  Enum+String
//  Copper
//
//  Created by Doug Williams on 4/7/16.
//  Copyright (c) 2015 Doug Williams. All rights reserved.
//

import Foundation
    
func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
    var i = 0
    return AnyGenerator {
        let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
        i += 1
        return next.hashValue == i ? next : nil
    }
}

