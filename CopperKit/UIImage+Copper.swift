//
//  Copper+UIImage
//  Copper
//
//  Created by Doug Williams on 1/19/15.
//  Copyright (c) 2015 Doug Williams. All rights reserved.
//

import UIKit

extension UIImage {
    
    public class func toImage(view: UIView) -> UIImage {
        UIGraphicsBeginImageContext(view.frame.size);
        //new iOS 7 method to snapshot!!
        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let screenshot: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext ()
        return screenshot
    }

    public class func crop(image: UIImage, rect: CGRect) -> UIImage {
        let imageRef:CGImageRef = CGImageCreateWithImageInRect(image.CGImage, rect)!
        let cropped:UIImage = UIImage(CGImage:imageRef)
        return cropped
    }
    
    public class func c29_imageFromUrl(url: String, callback: (image: UIImage?)->()) {
        if let u = NSURL(string: url) {
            let request = NSURLRequest(URL: u)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) {
                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                if let imageData = data as NSData? {
                    callback(image: UIImage(data: imageData))
                } else {
                    callback(image: nil)
                }
            }
            return
        }
        callback(image: nil)
    }
    
    public class func newSizeFromHeight(image: UIImage, newHeight: CGFloat) -> CGSize {
        let curWidth = image.size.width
        let curHeight = image.size.height
        let ratio = newHeight / curHeight
        let newWidth = curWidth * ratio
        let newSize = CGSizeMake(newWidth, newHeight)
        return newSize
    }
    
    public class func imageWithImage(image:UIImage, newSize:CGSize) -> UIImage {
        if newSize == image.size {
            return image
        }
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.mainScreen().scale)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage.imageWithRenderingMode(.AlwaysTemplate)
    }
    
    // this will capture a UIImage of the currently display view, of size view.size
    public class func screenshot(view: UIView, rect: CGRect? = nil) -> UIImage {
        let origBounds = view.bounds
        
        if rect != nil {
            view.bounds = rect!
        }
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0);
        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Restore our bounds
        view.bounds = origBounds
        return image
    }
    
    // add a blur overlay to an image
    public class func blur(image: UIImage, style: UIBlurEffectStyle, vibrancy: Bool = false, blurFrame: CGRect! = nil) -> UIImage {
        
        // place our image in a view
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0,y: 0), size: image.size))
        imageView.image = image
        
        // add a blur
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        // set it in the same frame as the imageView, or the specified frame if present
        var frame = imageView.frame
        if let blurFrame = blurFrame {
            frame = blurFrame
        }
        blurView.frame = frame
        
        // Make the Blur happen!
        imageView.addSubview(blurView)
        
        // optionally add vibrancy
        if vibrancy {
            let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = blurView.bounds
            imageView.addSubview(vibrancyEffectView)
        }

        // return it
        return UIImage.screenshot(imageView)
    }
    
    public func roundImage() -> UIImage {
        let newImage = self.copy() as! UIImage
        let cornerRadius = self.size.height/2
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1.0)
        let bounds = CGRect(origin: CGPointZero, size: self.size)
        UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).addClip()
        newImage.drawInRect(bounds)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }
    
    public class func c29_pixelWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // simulate a green pulsing light on an image vie
    public class func pulseImageView(imageView: UIImageView, `repeat`: Bool = true)
    {
        // set our rendering mode, if necessary
        if imageView.image?.renderingMode != UIImageRenderingMode.AlwaysTemplate {
            imageView.image = imageView.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
        
        UIView.animateWithDuration(0.4,
            delay: 1.2,
            options: [],
            animations: {
                imageView.tintColor = UIColor.copper_primaryVerdigris()
            }, completion: { finished in
                
                UIView.animateWithDuration(0.4,
                    delay: 0.1,
                    options: [],
                    animations: {
                        imageView.tintColor = UIColor.blackColor()
                    },
                    completion: { finished in
                        
                        if `repeat` == true {
                            UIImage.pulseImageView(imageView)
                        }
                
                    })
        })
    }
}