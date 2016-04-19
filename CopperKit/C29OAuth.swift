//
//  C29OAuth.swift
//  Copper
//
//  Created by Doug Williams on 10/1/14.
//  Copyright (c) 2014 Doug Williams. All rights reserved.
//

import Foundation

public class C29OAuth {
    
    public enum Key: String {
        case ApplicationId = "client_id" // we leave this as client_id per the oauth spec
        case UserId = "user_id"
        case RedirectUri = "redirect_uri"
        case Nonce = "nonce"
        case State = "state"
        case Scope = "scope"
        case ResponseMode = "response_mode"
        case ResponseType = "response_type"
    }
    
    class var ResponseModeInternal: String {
        return "internal"
    }
    
    let applicationId: String!
    let redirectUri: String!
    let nonce: String!
    let state: String!
    let scope: String!
    let responseType: String!
    
    init(applicationId: String, redirectUri: String, nonce: String, state: String, scope: String, responseType: String) {
        self.applicationId = applicationId
        self.redirectUri = redirectUri
        self.nonce = nonce
        self.state = state
        self.scope = scope
        self.responseType = responseType
    }
    
    public class func handleURL(url: NSURL, session: C29SessionDataSource, callback: ((success: Bool, error: NSError?)->())! = nil) {
        let (oauth, error) = fromOAuthDialogURL(url)
        if let oauth = oauth {
            oauth.handleOAuthDialogURL(session, callback: { (request, error) in
                if let request = request {
                    session.requestStack.push(request, display: true)
                    callback?(success: true, error: nil)
                } else {
                    C29Log(.Error, "There was an error opening the request (1) \(url)")
                    callback?(success: false, error: error)
                }
            })
        } else {
            C29Log(.Error, "There was an error opening the request (2) \(url)")
            callback?(success: false, error: error)
        }
    }
    
    public class func fromOAuthDialogURL(url: NSURL) -> (oauth: C29OAuth?, error: NSError?) {
        var error = Error?()
        if let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) {
            if let host = components.host where C29Utils.CopperURLs.contains(host) {
                if let applicationId = components.getQueryStringParameter(C29OAuth.Key.ApplicationId.rawValue),
                    let redirectUri = components.getQueryStringParameter(Key.RedirectUri.rawValue),
                    let nonce = components.getQueryStringParameter(Key.Nonce.rawValue),
                    let state = components.getQueryStringParameter(Key.State.rawValue),
                    let scope = components.getQueryStringParameter(Key.Scope.rawValue),
                    let responseType = components.getQueryStringParameter(Key.ResponseType.rawValue) {
                    
                    let oauth = C29OAuth(applicationId: applicationId, redirectUri: redirectUri, nonce: nonce, state: state, scope: scope, responseType: responseType)
                    return (oauth, nil)
                } else {
                    error = .Parameters
                }
            } else {
                error = .Host
            }
        } else {
            error = Error.Invalid
        }
        return (nil, error!.nserror)
    }

    // returns true if the URL is in the correct format
    // callback is there to provide a facility to react to the success/error with the API request
    public func handleOAuthDialogURL(session: C29SessionDataSource, callback: ((request: C29Request?, error: NSError?)->())) {
        // example: https://copper-api.withcopper.com/oauth/dialog
        // client_id=55EBC95508CAE8537FA54AAD9E6EC3BEF7771257
        // redirect_uri=http%3A%2F%2Fcopper-api-staging.herokuapp.com%2Ftest%2Foauth%2Fdialog&scope=name%2Cemail%2Cphone_number&state=f46e83a607254943924cf489c0be7d5c
        // nonce=8137a174da924e3fa917d0bd7501b2d8
        // display=popup
        // scope=openid%20profile
        // response_type=id_token%2Ctoken
        
//
// TODO this needs to be added to the V29SessionCoordinator or made available to this file
//        guard let userId = session.userId else {
//            callback(request: nil, error: Error.NilUserId.nserror)
//            return
//        }        
//        session.api.oauthAuthorize(userId, applicationId: applicationId, redirectUri: redirectUri, nonce: nonce, state: state, scope: scope, responseMode: C29OAuth.ResponseModeInternal, responseType: responseType, callback: { (request: AnyObject?, error: NSError?) -> () in
//            callback(request: request as? C29Request, error: error)
//        })
    }
}


extension C29OAuth {
    enum Error: Int {
        case Invalid = 0
        case Host = 1
        case Path = 2
        case Parameters = 3
        case NilUserId = 4
        
        var reason: String {
            switch self {
            case Invalid:
                return "Not a Copper OAuth URL"
            case Host:
                return "Not a valid OAuth URL - check your host"
            case Path:
                return "Not a valid OAuth URL - check your path"
            case Parameters:
                return "Missing or invalid parameters"
            case .NilUserId:
                return "C29SessionDataSource has a nil user, and nil userID"
            }
        }
        
        var nserror: NSError {
            return NSError(domain: self.domain, code: self.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: self.reason])
        }
        
        var domain: String {
            return "\(NSBundle.mainBundle().bundleIdentifier!).C29OAuth"
        }
    }
}