//
//  Copper+String
//  Copper
//
//  Created by Doug Williams on 1/19/15.
//  Copyright (c) 2015 Doug Williams. All rights reserved.
//

import UIKit

extension String {
    
    // From: http://www.raywenderlich.com/86205/nsregularexpression-swift-tutorial
    public func clean() -> String {
        let leadingAndTrailingWhitespacePattern = "(?:^\\s+)|(?:\\s+$)"
        
        do {
            let regex = try NSRegularExpression(pattern: leadingAndTrailingWhitespacePattern, options: .CaseInsensitive)
            let range = NSMakeRange(0, self.characters.count)
            let trimmedString = regex.stringByReplacingMatchesInString(self, options: .ReportProgress, range:range, withTemplate:"$1")
            
            return trimmedString
        } catch _ {
            return self
        }
    }
    
    public func contains(find: String) -> Bool {
        return self.rangeOfString(find) != nil
    }
    
    public var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
    
    public func localizedWithComment(comment: String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: comment)
    }
    
    public var urlEncoded: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
    
    public static func randomStringWithLength(len: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        for (var i=0; i < len; i += 1){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString as String
    }
    
    public var htmlToAttributedString: NSAttributedString {
        let attributedString = try! NSAttributedString(data: self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!,
            options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
            documentAttributes: nil)
        return attributedString
    }
    
    public var convertJSONStringToDictionary: [String:AnyObject]? {
        let data = self.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
            return json as? [String : AnyObject]
        } catch {
            C29Log(.Critical, "Warning: convertJSONStringToDictionary failed, returning nil")
            return nil
        }
    }
    
    // Substring helpers, credit: http://stackoverflow.com/a/24144365/4389523
    // "abcde"[0] === "a"
    // "abcde"[0...2] === "abc"
    // "abcde"[2..<4] === "cd"
    
    public subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    public subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    public subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }

}