//
//  Verification.swift
//  Copper
//
//  Created by Doug Williams on 5/29/14.
//  Copyright (c) 2014 Doug Williams. All rights reserved.
//

import Foundation

@objc public class C29VerificationCode: NSObject {
    
    @objc enum Key: Int {
        case Code = 1
        
        var value: String {
            switch self {
            case Code:
                return "code"
            }
        }
    }
    
    public var code: String
    
    init(code: String) {
        self.code = code
    }
    
    public class func fromDictionary(dataDict: NSDictionary) -> C29VerificationCode? {
        if let code = dataDict[Key.Code.value] as? String {
            return C29VerificationCode(code: code)
        }
        C29LogWithRemote(.Critical, error: C29VerificationError.InvalidFormat.nserror, infoDict: dataDict as! [String : AnyObject])
        return C29VerificationCode?()
    }
}

public class C29VerificationResult {
    
    enum Key: String {
        case UserId = "user_id"
        case Token = "token"
        case IsNewUser = "is_new_user"
        case DeviceId = "device_id"
    }
    
    public var userId: String
    public var token: String
    public var isNewUser: Bool
    public var deviceId: String

    init(userId: String, token: String, isNewUser: Bool, deviceId: String) {
        self.userId = userId
        self.token = token
        self.isNewUser = isNewUser
        self.deviceId = deviceId
    }
    
    public class func fromDictionary(dataDict: NSDictionary) -> C29VerificationResult? {
        if let userId = dataDict[Key.UserId.rawValue] as? String,
            let token = dataDict[Key.Token.rawValue] as? String,
            let deviceId = dataDict[Key.DeviceId.rawValue] as? String,
            let isNewUser = dataDict[Key.IsNewUser.rawValue] as? Bool {
                return C29VerificationResult(userId: userId, token: token, isNewUser: isNewUser, deviceId: deviceId)
        }
        C29LogWithRemote(.Critical, error: C29VerificationError.InvalidFormat.nserror, infoDict: dataDict as! [String : AnyObject])
        return C29VerificationResult?()
    }
}

enum C29VerificationError: Int {
    case InvalidFormat = 1

    var reason: String {
        switch self {
        case InvalidFormat:
            return "C29Verification.fromDictionary failed because some required data was omitted or in the wrong format"
        }
    }
    var nserror: NSError {
        return NSError(domain: self.domain, code: self.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: self.reason])
    }
    var domain: String {
        return "\(NSBundle.mainBundle().bundleIdentifier!).Verification"
    }
}