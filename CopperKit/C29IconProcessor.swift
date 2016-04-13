//
//  IconProcessor.swift
//  Copper
//
//  Created by Doug Williams on 9/19/15.
//  Copyright © 2015 Doug Williams. All rights reserved.
//

import UIKit

private let IconWidth:CGFloat = 64.0
private let IconHeight:CGFloat = 64.0


private var token: dispatch_once_t = 0
class IconProcessor: NSObject {
    
    var sourceImage:UIImage
    init(sourceImage:UIImage){
        self.sourceImage = sourceImage
        super.init()
    }
    
    enum ColorStyle {
        case Light
        case Dark
        
        var backgroundColor: UIColor {
            switch self {
            case .Light:
                return UIColor.copper_white()
            case .Dark:
                return UIColor.copper_black20()
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .Light:
                return UIColor.copper_black92()
            case .Dark:
                return UIColor.copper_white()
            }
        }
    }
    
    class func defaultClientIconImage(applicationName: String! = nil, style: ColorStyle = .Dark) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(IconWidth, IconHeight), false, 0.0)
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSaveGState(ctx)
        
        let rect = CGRectMake(0, 0, IconHeight, IconWidth)
        CGContextSetFillColorWithColor(ctx, style.backgroundColor.CGColor);
        CGContextFillEllipseInRect(ctx, rect);
        
        CGContextRestoreGState(ctx)
        let iconBackgroundImageView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let iconImageView = UIImageView()
        iconImageView.frame.size = iconBackgroundImageView.size
        iconImageView.image = iconBackgroundImageView
        if let applicationName = applicationName {
            // TODO do we want these uppercased?
            let firstLetterString:String = applicationName[0]
            let firstLetterView = UILabel()
            firstLetterView.text = firstLetterString.uppercaseString
            firstLetterView.font = UIFont.copper_ClientIconFont()
            firstLetterView.textAlignment = .Center
            firstLetterView.textColor = style.textColor
            firstLetterView.frame = iconImageView.frame
            iconImageView.addSubview(firstLetterView)
        }
        return UIImage.toImage(iconImageView)
    }
}