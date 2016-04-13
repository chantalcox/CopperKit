//
//  UITextView+Copper.swift
//  Copper
//
//  Created by Doug Williams on 1/22/16.
//  Copyright © 2015 Copper Technologies, Inc. All rights reserved.
//

import UIKit

extension UITextView {
    
    public func boldRange(range: Range<String.Index>) {
        if let text = self.attributedText {
            let attr = NSMutableAttributedString(attributedString: text)
            let start = text.string.startIndex.distanceTo(range.startIndex)
            let length = range.startIndex.distanceTo(range.endIndex)
            attr.addAttributes([NSFontAttributeName: UIFont.boldSystemFontOfSize(self.font!.pointSize)], range: NSMakeRange(start, length))
            self.attributedText = attr
        }
    }
    
    public func boldSubstring(substr: String) {
        let range = self.text?.rangeOfString(substr)
        if let r = range {
            boldRange(r)
        }
    }

}