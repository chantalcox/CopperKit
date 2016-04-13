//
//  UIButton+Copper
//  Copper
//
//  Created by Doug Williams on 1/26/16.
//  Copyright (c) 2016 Doug Williams. All rights reserved.
//

import UIKit

extension UIButton {

}

public class TouchAndHoldButton: UIButton {
    
    private var holdTimer: NSTimer?
    private var timeInterval: NSTimeInterval!
    private weak var target: AnyObject!
    private var action: Selector!
    
    public func addTarget(target: AnyObject, action: Selector, timeInterval: NSTimeInterval) {
        self.target = target
        self.action = action
        self.timeInterval = timeInterval
        self.addTarget(self, action: #selector(TouchAndHoldButton.sourceTouchUp(_:)), forControlEvents: .TouchUpInside)
        self.addTarget(self, action: #selector(TouchAndHoldButton.sourceTouchUp(_:)), forControlEvents: .TouchUpOutside)
        self.addTarget(self, action: #selector(TouchAndHoldButton.sourceTouchDown(_:)), forControlEvents: .TouchDown)
    }
    
    public func sourceTouchUp(sender: UIButton) {
        if holdTimer != nil {
            holdTimer!.invalidate()
            holdTimer = nil
        }
    }
    
    public func sourceTouchDown(sender: UIButton) {
        holdTimer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: target, selector: action, userInfo: nil, repeats: true)
        holdTimer!.fire()
    }
}