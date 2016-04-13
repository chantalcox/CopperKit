//
//  NSDate+String
//  Copper
//
//  Created by Doug Williams on 12/19/15.
//  Copyright (c) 2015 Doug Williams. All rights reserved.
//

import Foundation

extension NSDate {
    
    // change to a readable time format and change to local time zone
    // e.g. "EEE, MMM d, yyyy - h:mm a"
    public func toLocalStringWithFormat(dateFormat: String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        let timeStamp = dateFormatter.stringFromDate(self)
        return timeStamp
    }

    // returns true if the calling timestamp represents a time that is past the threshold amount right now
    public func isPastThreshold(seconds: Double) -> Bool {
        return (self.timeIntervalSince1970 < NSDate().timeIntervalSince1970 - seconds)
    }
    
}
