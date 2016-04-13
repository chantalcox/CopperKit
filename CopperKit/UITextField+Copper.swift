//
//  UITextField+Copper.swift
//  Copper
//
//  Created by Doug Williams on 11/29/15.
//  Copyright © 2015 Copper Technologies, Inc. All rights reserved.
//

import UIKit

extension UITextField {
    
    public func setPlaceholderColor(color: UIColor) {
        self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "",
                attributes:[NSForegroundColorAttributeName: color])
    }

}