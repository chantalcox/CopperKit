//
//  Copper+UITableView
//  Copper
//
//  Created by Doug Williams on 1/19/15.
//  Copyright (c) 2015 Doug Williams. All rights reserved.
//

import UIKit

extension UITableView {

    public func getTableView() -> UITableView? {
        var view = self as UIView
        while(!(view is UITableView)) {
            if let _ = view.superview {
                view = view.superview!
            } else {
                return UITableView?()
            }
        }
        return (view is UITableView) ? (view as! UITableView) : UITableView?()
    }

    public func isVisible(indexPath: NSIndexPath) -> Bool {
        guard let visiblePaths = self.indexPathsForVisibleRows else {
            return false
        }        
        return visiblePaths.contains(indexPath)
    }
    
    public var indexPathForLastCell: NSIndexPath {
        get {
            // make sure we have a section
            guard self.numberOfSections > 0 else {
                return NSIndexPath(forRow: 0, inSection: 0)
            }
            let lastSection = self.numberOfSections-1
            // make sure we have a row in that section
            if self.numberOfRowsInSection(lastSection) == 0 {
                return NSIndexPath(forRow: 0, inSection: lastSection)
            }
            // otherwise we have a valid section
            return NSIndexPath(forRow: self.numberOfRowsInSection(lastSection)-1, inSection: lastSection)
        }
    }
}