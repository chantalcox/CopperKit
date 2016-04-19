//
//  CopperAPI.swift
//  Copper
//
//  Doug Williams on 12/9/14.
//

import Foundation
import SystemConfiguration

public class CopperNetworkAPI: NSObject, C29API {
    
    public weak var delegate: CopperNetworkAPIDelegate?
    public weak var dataSource:CopperNetworkAPIDataSource?
    public var URL: String = "https://api.withcopper.com"

    var authToken:String? {
        get {
            return delegate?.authTokenForAPI(self)
        }
    }

    // Instance Variables
    var session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

    // Our workhorse method, though you shouldn't need to call this directly.
    public func makeHTTPRequest(method: C29APIMethod, callback: C29APICallback, url: NSURL, httpMethod: HTTPMethod, params: [String: AnyObject]! = nil, authentication: Bool = true, retries: Int = 1) {
        C29Log(.Debug, "CopperAPI >> HTTP \(httpMethod.rawValue) \(url)")
        
        guard Reachability.isConnectedToNetwork() else {
            dispatch_async(dispatch_get_main_queue()) {
                callback(nil, C29NetworkAPIError.Disconnected.nserror)
            }
            return ()
        }
        
        // Request setup
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod.rawValue
        
        // Handle authenticaiton requirements and reauth as necessary
        if authentication {
            // If we have our authToken, proceed
            if let token = self.authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                // If there are authentication retries left, then let's use them
            } else if retries > 0 {
                attemptLoginThenRetryHTTPRequest(method, callback: callback, url: url, httpMethod: httpMethod, params: params, authentication: authentication, retries: retries)
                return
                // No retries left and we're still unauthed
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    C29LogWithRemote(.Error, error: C29NetworkAPIError.Auth.nserror, infoDict: params)
                    callback(nil, C29NetworkAPIError.Auth.nserror)
                }
            }
        }

        // Add any parameters to the request body as necessary
        if params != nil {
            do {
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                let json = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
                request.HTTPBody = json
                if let json = NSString(data: json, encoding: NSUTF8StringEncoding) {
                    C29Log(.Debug, "CopperNetworkAPI request body '\(json)'")
                }
            } catch {
                let error = C29NetworkAPIError.JsonInvalid.nserror
                C29LogWithRemote(.Error, error: error, infoDict: params)
                dispatch_async(dispatch_get_main_queue()) {
                    callback(nil, error)
                }
            }
        }
        
        // Make the call!
        delegate?.beganRequestInNetworkAPI(self)
        let task = session.dataTaskWithRequest(request) { data, response, error in
            self.delegate?.endedRequestInNetworkAPI(self)
            // attempt to serialize the data from json which we expect
            var dataDict = NSDictionary?()
            if let data = data {
                do {
                    dataDict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? NSDictionary
                } catch {
                    // no op
                }
            }
            
            // handle our request on the main thread since it may affect UI downstream
            dispatch_async(dispatch_get_main_queue()) {
                // exit early with any network / system error
                guard error == nil else {
                    callback(nil, self.handleError((response as? NSHTTPURLResponse), dataDict: dataDict))
                    return ()
                }
            
                // otherwise attempt to parse our response
                if let httpResponse = response as? NSHTTPURLResponse {
                    let res = self.handleResponse(method, response: httpResponse, dataDict: dataDict)
                    if let error = res.error as NSError? {
                        // We want to automatically retry if retries are available... and we're not attempted a JWT refresh already :)
                        if error == C29NetworkAPIError.Auth.nserror && retries > 0 && method != .GET_JWT {
                            self.attemptLoginThenRetryHTTPRequest(method, callback: callback, url: url, httpMethod: httpMethod, params: params, authentication: authentication, retries: retries)
                            return
                        }
                    }
                    
                    callback(res.data, res.error)
                }
            }
        }
        task.resume()
    }
    
    private func attemptLoginThenRetryHTTPRequest(method: C29APIMethod, callback: C29APICallback, url: NSURL, httpMethod: HTTPMethod, params: [String: AnyObject]! = nil, authentication: Bool = true, retries: Int = 1) {
        C29Log(.Debug, "CopperAPI >> attemping C29User.login with \(retries) retries")
        let tries = retries - 1
        delegate!.networkAPI(self, attemptLoginWithCallback: { (success, error) -> () in
            if success {
                self.makeHTTPRequest(method, callback: callback, url: url, httpMethod: httpMethod, params: params, authentication: authentication, retries: tries)
            } else {
                C29Log(.Debug, "CopperAPI >> error retrieving authToken")
                dispatch_async(dispatch_get_main_queue()) {
                    callback(nil, error)
                }
            }
        })
    }

    public func handleResponse(method: C29APIMethod, response: NSHTTPURLResponse, dataDict: NSDictionary! = nil) -> (data: AnyObject?, error: NSError?) {
        // This method should be much more fleshed out in actual implementation classes
        var result:AnyObject?
        var error:NSError?
        switch(response.statusCode) {
        // Success handling
        case 200, 201:
            result = dataDict
        // An error was (likely) returned
        default:
            error = self.handleError(response, dataDict: dataDict)
        }
        return (data: result, error: error)
    }
    
    // Create and return an NSError message that is expected and meaningful to the caller
    public func handleError(response: NSHTTPURLResponse! = nil, dataDict: NSDictionary! = nil) -> NSError {
        let errorMsg: String = (dataDict?["message"] as? String) ?? "Our computers are having troubles talking to one another. Please try again soon." // our
        // TODO capture the {code: internal_code} sub-json
        let code = response?.statusCode ?? -29 // -29 is unknown
        return NSError(domain: C29NetworkAPIError.HTTPStatusCode.domain, code: code, userInfo:["message": errorMsg])
    }

}

public class Reachability {
    
    // credit: http://stackoverflow.com/questions/25623272/how-to-use-scnetworkreachability-in-swift/25623647#25623647
    public class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.Reachable)
        let needsConnection = flags.contains(.ConnectionRequired)
        return (isReachable && !needsConnection)
    }
    
}


public enum C29NetworkAPIError: Int {
    case Disconnected = 0
    case Auth = 1
    case JsonInvalid = 3
    case CopperAPIDown = 4
    case HTTPStatusCode = 5
    
    // Dialog errors
    case DialogCodeExpired = 22
    case DialogCodeLocked = 23
    case DialogCodeInvalid = 24
    
    var reason: String {
        switch self {
        case Disconnected:
            return "Your device appears to be disconnected from the Internet."
        case Auth:
            return "You are no longer authenticated with Copper. For security, we need you to be authenticated before we can complete this request. You may need to restart the app to fix this error."
        //case UserConflict:
        //    return "This user id was previously registered."
        case JsonInvalid:
            return "We were unable to process that request."
        case CopperAPIDown:
            return "Copper is down"
        case HTTPStatusCode:
            return "Unexpected HTTP Status code"
        case DialogCodeExpired:
            return "That code is expired. Try again."
        case DialogCodeLocked:
            return "That code is locked. Try again."
        case DialogCodeInvalid:
            return "Wrong code."
        }
    }
    var description: String {
        switch self {
        case .CopperAPIDown:
            return "Check @withcopper for our status. Otherwise, please try again soon."
        default:
            return self.reason
        }
    }
    public var nserror: NSError {
        return NSError(domain: self.domain, code: self.rawValue, userInfo: ["message": self.reason, NSLocalizedFailureReasonErrorKey: self.reason])
    }
    var domain: String {
        return "\(NSBundle.mainBundle().bundleIdentifier!).CopperNetworkAPI"
    }
}